import 'dart:io'; // ใช้จัดการอ่านไฟล์รูปภาพจากพื้นที่เก็บข้อมูลมือถือ

import 'package:flutter/services.dart' show rootBundle; // ใช้โหลดไฟล์จากโฟลเดอร์ assets (เช่น labels.txt)
import 'package:image/image.dart' as img; // แพ็กเกจจัดการรูปภาพ (ย่อขนาด, แปลงพิกเซล) เราตั้งชื่อเล่นให้มันว่า 'img'
import 'package:tflite_flutter/tflite_flutter.dart'; // ตัวเครื่องยนต์ TensorFlow Lite

import '../../core/constants/asset_paths.dart'; // พิกัดที่เก็บไฟล์โมเดล
import 'classification_result.dart'; // กล่องข้อมูล (Model) ที่เราจะแพ็คผลลัพธ์ส่งกลับไป

/// รันการทำนายผลแบบออฟไลน์ในมือถือ ด้วยโมเดล MobileNetV2
/// การแปลงข้อมูล (Preprocessing) ต้องเหมือนตอนเทรนใน Python เป๊ะๆ:
/// สูตรคือ (พิกเซล / 127.5) - 1.0 เพื่อปรับสเกลให้อยู่ในช่วง [-1, 1]
class ClassifierService {
  // 💡 ล็อก Constructor ไว้ไม่ให้ใครสร้างคลาสนี้เพิ่ม
  ClassifierService._();

  // 💡 Singleton: ท่อเชื่อม AI ประจำแอป มีท่อเดียวใช้ร่วมกันทั้งแอป
  static final ClassifierService instance = ClassifierService._();

  // ขนาดรูปภาพที่ AI ต้องการคือ กว้าง 224 ยาว 224 พิกเซล
  static const int _inputSize = 224;

  Interpreter? _interpreter; // ตัวสมองกล AI
  List<String>? _labels; // รายชื่อชนิดขยะ

  // ===========================================================================
  // 1. ฟังก์ชันโหลดสมองกล (ทำงานแค่ครั้งแรกครั้งเดียว)
  // ===========================================================================
  Future<void> _ensureLoaded() async {
    // ถ้าเคยโหลด AI และ Labels มาเก็บใน RAM แล้ว ให้หยุดทำฟังก์ชันนี้เลย ประหยัดเวลา
    if (_interpreter != null && _labels != null) return;

    // โหลดไฟล์ .tflite มาแปลงเป็นเครื่องยนต์ Interpreter
    _interpreter = await Interpreter.fromAsset(AssetPaths.model);

    // โหลดไฟล์ตัวหนังสือ labels.txt แล้วโยนเข้าฟังก์ชัน parseLabels เพื่อหั่นเป็น List
    final raw = await rootBundle.loadString(AssetPaths.labels);
    _labels = parseLabels(raw);

    // 💡 การตรวจสอบความปลอดภัย (Tensor Shape Validation)
    // เช็คว่าโมเดลที่ใส่เข้ามา มีช่องรับข้อมูล (Input) และช่องคายข้อมูล (Output) ตรงกับที่เราเขียนโค้ดไหม
    final inputShape = _interpreter!.getInputTensor(0).shape; // โครงสร้างช่องรับ (มักจะเป็น [1, 224, 224, 3])
    final outputShape = _interpreter!.getOutputTensor(0).shape; // โครงสร้างช่องคาย (มักจะเป็น [1, จำนวนชนิดขยะ])

    // เช็คว่าช่องรับข้อมูลมี 4 มิติ และสัดส่วนเป็น 1 รูป, 224 กว้าง, 224 ยาว, 3 สี(RGB) ใช่หรือไม่?
    final hasExpectedInput =
        inputShape.length == 4 &&
        inputShape[0] == 1 &&
        inputShape[1] == _inputSize &&
        inputShape[2] == _inputSize &&
        inputShape[3] == 3;
    
    // เช็คว่าช่องคายข้อมูลมีขนาดเท่ากับจำนวนรายชื่อขยะในไฟล์ txt ไหม?
    final hasExpectedOutput =
        outputShape.isNotEmpty && outputShape.last == _labels!.length;

    // ถ้าไฟล์โมเดลกับแอปมีโครงสร้างไม่ตรงกัน ให้ทำลายทิ้งแล้วเด้ง Error (Fail-fast)
    if (!hasExpectedInput || !hasExpectedOutput) {
      dispose();
      throw StateError(
        'Model and labels are incompatible: input=$inputShape, '
        'output=$outputShape, labels=${_labels?.length ?? 0}',
      );
    }
  }

  // หั่นข้อความจากไฟล์ txt ที่คั่นด้วยการขึ้นบรรทัดใหม่ (\n) ให้กลายเป็น List รายชื่อขยะ
  static List<String> parseLabels(String raw) => raw
      .split('\n') // หั่นด้วยการขึ้นบรรทัดใหม่
      .map((line) => line.trim()) // ตัดช่องว่างหัวท้ายทิ้ง
      .where((line) => line.isNotEmpty) // เอาเฉพาะบรรทัดที่มีตัวหนังสือ (กรองบรรทัดว่างทิ้ง)
      .toList(growable: false); // ล็อก List ให้เพิ่มขนาดไม่ได้ (ประหยัด RAM)

  // ===========================================================================
  // 2. ฟังก์ชันพระเอก: รับรูปภาพ -> แปลงรูป -> ส่งให้ AI -> ตอบผลลัพธ์
  // ===========================================================================
  Future<ClassificationResult> classify(String imagePath) async {
    // อ่านไฟล์รูปจากมือถือออกมาเป็นก้อนข้อมูลไบต์ (Bytes)
    final bytes = await File(imagePath).readAsBytes();
    
    // ถอดรหัสไบต์ให้กลายเป็นออบเจกต์ Image ที่แก้ไขได้
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Cannot decode image: $imagePath'); // ถ้าถอดรหัสไม่ได้ให้พังไปเลย
    }

    // เรียกให้มั่นใจว่าโหลดโมเดล AI เสร็จแล้วชัวร์ๆ
    await _ensureLoaded();

    // 💡 [จุดสำคัญ] แก้ไขปัญหา EXIF Orientation
    // ภาพจากมือถือมักจะกลับหัวหรือตะแคงข้างซ่อนอยู่ใน Metadata โค้ดบรรทัดนี้จะอบ (Bake)
    // การหมุนรูปเข้าไปในพิกเซลจริงๆ เพื่อให้ AI เห็นรูปตั้งตรงเป๊ะๆ
    final oriented = img.bakeOrientation(decoded);

    // ย่อขนาดรูปภาพให้เหลือ 224 x 224 พิกเซล
    final resized = img.copyResize(
      oriented,
      width: _inputSize,
      height: _inputSize,
    );

    // แปลงรูป 224x224 ให้กลายเป็นอาร์เรย์คณิตศาสตร์ 3 มิติ
    final input = [_imageToInputPlane(resized)];
    final labels = _labels!;
    
    // สร้างอาร์เรย์ว่างๆ มารอรับผลลัพธ์คะแนน (เต็มไปด้วยเลข 0.0)
    final output = [List<double>.filled(labels.length, 0.0)];

    // 🧠 สั่งให้ AI คำนวณ! (ข้อมูลจาก input จะถูกคำนวณและพ่นคะแนนไปทับที่ output)
    _interpreter!.run(input, output);

    // แกะเอาอาร์เรย์คะแนนออกมา
    final scores = output[0];
    var bestIndex = 0; // ตัวแปรจำตำแหน่งขยะที่ได้คะแนนสูงสุด เริ่มต้นที่ 0
    
    // วนลูปหาว่าตำแหน่งไหน (Index) ได้คะแนนสูงสุด
    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > scores[bestIndex]) bestIndex = i;
    }

    // แพ็คผลลัพธ์ใส่กล่อง ClassificationResult แล้วโยนกลับไปให้หน้าจอ
    return ClassificationResult(
      label: labels[bestIndex], // ชื่อขยะที่คะแนนสูงสุด
      confidence: scores[bestIndex], // คะแนนความมั่นใจที่สูงสุด
      // สร้าง Map เก็บรายชื่อขยะคู่กับคะแนนทุกตัวแนบไปด้วย
      allScores: {for (var i = 0; i < labels.length; i++) labels[i]: scores[i]},
    );
  }

  // ===========================================================================
  // 3. ฟังก์ชันแปลงพิกเซลสีให้เป็นตัวเลขที่ AI เข้าใจ (Image Normalization)
  // ===========================================================================
  List<List<List<double>>> _imageToInputPlane(img.Image image) {
    // วนลูปสร้างอาร์เรย์ 3 มิติ (กว้าง x ยาว x สี RGB)
    return List.generate(
      image.height, // วนลูปแนวตั้ง (แกน Y)
      (y) => List.generate(image.width, (x) { // วนลูปแนวนอน (แกน X)
        // ดึงค่าสี (สีแดง, สีเขียว, สีน้ำเงิน) ของ 1 จุดพิกเซลออกมา
        final pixel = image.getPixel(x, y);
        // 💡 [จุดสำคัญ] สูตร Normalize แบบ MobileNetV2
        // สีปกติคือ 0-255 เอามาหาร 127.5 จะได้ 0.0 ถึง 2.0
        // แล้วเอาไปลบ 1.0 จะได้ช่วง -1.0 ถึง 1.0 ตามที่ AI ชอบ
        return [
          pixel.r / 127.5 - 1.0, // สีแดง
          pixel.g / 127.5 - 1.0, // สีเขียว
          pixel.b / 127.5 - 1.0, // สีน้ำเงิน
        ];
      }),
    );
  }

  // ===========================================================================
  // 4. ฟังก์ชันทำลายล้าง คืนหน่วยความจำ
  // ===========================================================================
  void dispose() {
    _interpreter?.close(); // ปิดเครื่องยนต์ AI คืน RAM ให้มือถือ
    _interpreter = null;
    _labels = null;
  }
}