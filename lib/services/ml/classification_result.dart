class ClassificationResult {
  const ClassificationResult({
    required this.label,
    required this.confidence,
    required this.allScores,
  });

  final String label;
  final double confidence;
  final Map<String, double> allScores;
}
