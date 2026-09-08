// lib/domain/models/scan_result.dart

class ScanResult {
  final String medicineName;
  final String brandName;
  final String genericName;
  final String? genericNameBn;
  final String? category;
  final String summary;          // In the selected language
  final String summaryEn;        // Always English — TTS fallback for Bangla
  final String? precaution;       // In the selected language
  final String? precautionEn;     // Precaution in English
  final String language;

  const ScanResult({
    required this.medicineName,
    required this.brandName,
    required this.genericName,
    this.genericNameBn,
    this.category,
    required this.summary,
    required this.summaryEn,
    this.precaution,
    this.precautionEn,
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
      final precPart = (precaution != null && precaution!.trim().isNotEmpty)
          ? ' সতর্কতা: $precaution'
          : '';
      return '$medicineName। এটি $gen। $catPart$summary$precPart';
    }
    final catPart = (category != null && category!.trim().isNotEmpty)
        ? ', used for $category'
        : '';
    final precPart = (precaution != null && precaution!.trim().isNotEmpty)
        ? ' Precaution: $precaution'
        : '';
    return '$medicineName. This medicine contains $genericName$catPart. $summary$precPart';
  }

  /// English spoken text — used as TTS fallback when Bangla voice unavailable
  String get spokenTextEn {
    final catPart = (category != null && category!.trim().isNotEmpty)
        ? ', used for $category'
        : '';
    final precPart = (precautionEn != null && precautionEn!.trim().isNotEmpty)
        ? ' Precaution: $precautionEn'
        : (precaution != null && language == 'en' ? ' Precaution: $precaution' : '');
    return '$medicineName. This medicine contains $genericName$catPart. $summaryEn$precPart';
  }
}