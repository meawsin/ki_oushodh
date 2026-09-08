// lib/domain/models/scan_result.dart

class ScanResult {
  final String medicineName;
  final String brandName;
  final String genericName;
  final String? genericNameBn;
  final String? category;
  final String summary;          // In the selected language
  final String summaryEn;        // Always English — TTS fallback for Bangla
  final String language;

  const ScanResult({
    required this.medicineName,
    required this.brandName,
    required this.genericName,
    this.genericNameBn,
    this.category,
    required this.summary,
    required this.summaryEn,
    required this.language,
  });

  /// Spoken text in selected language — natural and informative for listeners
  String get spokenText {
    if (language == 'bn') {
      final gen = (genericNameBn != null && genericNameBn!.isNotEmpty)
          ? '$genericNameBn গ্রুপের ওষুধ'
          : genericName;
      final catPart = (category != null && category!.trim().isNotEmpty)
          ? '$category। '
          : '';
      return '$medicineName। এটি $gen। $catPart$summary';
    }
    final catPart = (category != null && category!.trim().isNotEmpty)
        ? ', used for $category'
        : '';
    return '$medicineName. This medicine contains $genericName$catPart. $summary';
  }

  /// English spoken text — used as TTS fallback when Bangla voice unavailable
  String get spokenTextEn {
    final catPart = (category != null && category!.trim().isNotEmpty)
        ? ', used for $category'
        : '';
    return '$medicineName. This medicine contains $genericName$catPart. $summaryEn';
  }
}