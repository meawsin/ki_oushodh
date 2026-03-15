// lib/domain/models/scan_result.dart

class ScanResult {
  final String medicineName;
  final String brandName;
  final String genericName;
  final String summary;          // In the selected language
  final String summaryEn;        // Always English — TTS fallback for Bangla
  final String language;

  const ScanResult({
    required this.medicineName,
    required this.brandName,
    required this.genericName,
    required this.summary,
    required this.summaryEn,
    required this.language,
  });

  /// Spoken text in selected language
  String get spokenText => '$medicineName. $summary';

  /// English spoken text — used as TTS fallback when Bangla voice unavailable
  String get spokenTextEn => '$medicineName. $summaryEn';
}