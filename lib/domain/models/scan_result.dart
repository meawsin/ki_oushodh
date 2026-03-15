// lib/domain/models/scan_result.dart

class ScanResult {
  final String medicineName;   // Display name shown on screen
  final String brandName;      // Just the brand (for history)
  final String genericName;    // Just the generic (for history)
  final String summary;        // Plain-language explanation
  final String language;       // 'en' or 'bn'

  const ScanResult({
    required this.medicineName,
    required this.brandName,
    required this.genericName,
    required this.summary,
    required this.language,
  });

  /// Spoken text — name first, then summary
  String get spokenText => '$medicineName. $summary';
}