/// Model representing the result of an OCR scan.
class ScanResult {
  ScanResult({
    required this.rawText,
    required this.keywords,
    required this.topicScores,
    DateTime? scannedAt,
  }) : scannedAt = scannedAt ?? DateTime.now();

  /// The full text extracted by OCR.
  final String rawText;

  /// Academic keywords detected in the text.
  final List<String> keywords;

  /// Topic → confidence score mapping (e.g., "Machine Learning" → 0.85).
  final Map<String, double> topicScores;

  /// When the scan was performed.
  final DateTime scannedAt;

  /// Whether the scan produced any useful text.
  bool get hasText => rawText.trim().isNotEmpty;

  /// Whether any keywords were detected.
  bool get hasKeywords => keywords.isNotEmpty;
}
