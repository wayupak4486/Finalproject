import '../../../../services/ml/classification_result.dart';

class ScanResultArgs {
  const ScanResultArgs({required this.imagePath, required this.result});

  final String imagePath;
  final ClassificationResult result;
}
