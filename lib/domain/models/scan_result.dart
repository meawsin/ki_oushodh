// lib/domain/models/scan_result.dart

import '../../core/constants/bn_translations.dart';

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

  /// Spoken text in selected language — gentle, clear, and tailored for low-literacy users
  String get spokenText {
    if (language == 'bn') {
      final brandBn = BnTranslations.getBrandNameBn(medicineName);
      final genBn = (genericNameBn != null && genericNameBn!.isNotEmpty)
          ? genericNameBn!
          : '';

      // 1. Medicine Name & Category
      final String idSentence;
      final bool isSameOrRedundant = genBn.isEmpty ||
          brandBn.contains(genBn) ||
          genBn.contains(brandBn) ||
          (brandBn.contains('এন্টাসিড') && genBn.contains('অ্যান্টাসিড')) ||
          (brandBn.contains('ওমেগা') && genBn.contains('ওমেগা'));

      if (!isSameOrRedundant) {
        idSentence = '$brandBn। এটি $genBn — ${category ?? 'প্রয়োজনীয় ওষুধ'}।';
      } else {
        idSentence = '$brandBn। এটি ${category ?? 'প্রয়োজনীয় ওষুধ'}।';
      }

      // 2. Action / Summary
      final String actionSentence = summary.isNotEmpty ? ' $summary' : '';

      // 3. Essential precaution
      final String precSentence;
      if (precaution != null && precaution!.trim().isNotEmpty) {
        String cleanPrec = precaution!.replaceAll(RegExp(r'^সতর্কতা[:\s]*'), '').trim();
        // Remove clinical milligram dosage from spoken output for low-literacy clarity
        cleanPrec = cleanPrec.replaceAll(RegExp(r'৪[০,]*\s*মিলিগ্রাম বা\s*'), '');
        precSentence = ' $cleanPrec';
      } else {
        precSentence = '';
      }

      return '$idSentence$actionSentence$precSentence';
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