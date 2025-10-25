class AnalysisResult {
  final String objectName;
  final double confidence;

  AnalysisResult({
    required this.objectName,
    required this.confidence,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      objectName: json['object_name'] ?? 'Không xác định',
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'object_name': objectName,
      'confidence': confidence,
    };
  }
}
