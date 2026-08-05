import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../core/constants/asset_paths.dart';
import 'classification_result.dart';

/// Runs on-device inference with the bundled MobileNetV2 TFLite model.
///
/// Preprocessing must match `train_mobilenetv2.py` exactly: the model was
/// trained with Keras' `mobilenet_v2.preprocess_input`, which scales pixels
/// to the range [-1, 1] via `x / 127.5 - 1.0` (not the more common /255).
class ClassifierService {
  ClassifierService._();

  static final ClassifierService instance = ClassifierService._();

  static const int _inputSize = 224;

  Interpreter? _interpreter;
  List<String>? _labels;

  Future<void> _ensureLoaded() async {
    if (_interpreter != null && _labels != null) return;

    _interpreter = await Interpreter.fromAsset(AssetPaths.model);

    final raw = await rootBundle.loadString(AssetPaths.labels);
    _labels = parseLabels(raw);

    final inputShape = _interpreter!.getInputTensor(0).shape;
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final hasExpectedInput =
        inputShape.length == 4 &&
        inputShape[0] == 1 &&
        inputShape[1] == _inputSize &&
        inputShape[2] == _inputSize &&
        inputShape[3] == 3;
    final hasExpectedOutput =
        outputShape.isNotEmpty && outputShape.last == _labels!.length;

    if (!hasExpectedInput || !hasExpectedOutput) {
      dispose();
      throw StateError(
        'Model and labels are incompatible: input=$inputShape, '
        'output=$outputShape, labels=${_labels?.length ?? 0}',
      );
    }
  }

  static List<String> parseLabels(String raw) => raw
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);

  Future<ClassificationResult> classify(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Cannot decode image: $imagePath');
    }

    await _ensureLoaded();

    // Camera photos carry their rotation as EXIF metadata rather than in the
    // pixel data itself. decodeImage() ignores that tag, so without baking
    // it in, portrait photos are fed to the model sideways/upside-down.
    final oriented = img.bakeOrientation(decoded);

    final resized = img.copyResize(
      oriented,
      width: _inputSize,
      height: _inputSize,
    );

    final input = [_imageToInputPlane(resized)];
    final labels = _labels!;
    final output = [List<double>.filled(labels.length, 0.0)];

    _interpreter!.run(input, output);

    final scores = output[0];
    var bestIndex = 0;
    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > scores[bestIndex]) bestIndex = i;
    }

    return ClassificationResult(
      label: labels[bestIndex],
      confidence: scores[bestIndex],
      allScores: {for (var i = 0; i < labels.length; i++) labels[i]: scores[i]},
    );
  }

  List<List<List<double>>> _imageToInputPlane(img.Image image) {
    return List.generate(
      image.height,
      (y) => List.generate(image.width, (x) {
        final pixel = image.getPixel(x, y);
        return [
          pixel.r / 127.5 - 1.0,
          pixel.g / 127.5 - 1.0,
          pixel.b / 127.5 - 1.0,
        ];
      }),
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
  }
}
