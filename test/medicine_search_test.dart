import 'package:flutter_test/flutter_test.dart';
import 'package:ki_oushodh/core/constants/bn_translations.dart';
import 'package:ki_oushodh/domain/models/scan_result.dart';

void main() {
  group('BnTranslations Profile Tests', () {
    test('Paracetamol transliteration, category, and translations', () {
      final bnName = BnTranslations.getGenericNameBn('Paracetamol');
      expect(bnName, equals('প্যারাসিটামল'));

      final catBn = BnTranslations.getCategory('Paracetamol', language: 'bn');
      expect(catBn, contains('ব্যথানাশক'));

      final catEn = BnTranslations.getCategory('Paracetamol', language: 'en');
      expect(catEn, contains('Pain Relief & Fever'));

      final summaryBn = BnTranslations.translateSummary('', 'Paracetamol');
      expect(summaryBn, contains('জ্বর'));
      expect(summaryBn, contains('ব্যথা'));

      final summaryEn = BnTranslations.getEnglishSummary('', 'Paracetamol');
      expect(summaryEn, contains('fever'));
    });

    test('Omeprazole and Esomeprazole profiles', () {
      final omeprazoleBn = BnTranslations.getGenericNameBn('Omeprazole');
      expect(omeprazoleBn, equals('ওমিপ্রাজল'));

      final esomeprazoleBn = BnTranslations.getGenericNameBn('Esomeprazole');
      expect(esomeprazoleBn, equals('ইসোমিপ্রাজল'));

      final catBn = BnTranslations.getCategory('Omeprazole', language: 'bn');
      expect(catBn, contains('গ্যাস্ট্রিক'));
    });

    test('Antibiotics category detection for un-profiled medicines', () {
      final cat = BnTranslations.getCategory('Cefuroxime Axetil', language: 'bn');
      expect(cat, equals('অ্যান্টিবায়োটিক'));

      final catEn = BnTranslations.getCategory('Cefuroxime Axetil', language: 'en');
      expect(catEn, contains('Antibiotic'));
    });

    test('isCorruptedText correctly flags mojibake strings and clears clean strings', () {
      expect(BnTranslations.isCorruptedText('This is a clean English sentence.'), isFalse);
      expect(BnTranslations.isCorruptedText('প্যারাসিটামল একটি ওষুধ'), isFalse);
      expect(BnTranslations.isCorruptedText('Malformed \uFFFD text'), isTrue);
      expect(BnTranslations.isCorruptedText('Null \u0000 byte'), isTrue);
    });

    test('Clinical precautions and safety warnings for key drug classes', () {
      // Paracetamol maximum daily dose safety limit
      final paraPrecautionBn = BnTranslations.getPrecaution('Paracetamol', language: 'bn');
      expect(paraPrecautionBn, isNotNull);
      expect(paraPrecautionBn, contains('৪০০০ মিলিগ্রাম'));

      final paraPrecautionEn = BnTranslations.getPrecaution('Paracetamol', language: 'en');
      expect(paraPrecautionEn, isNotNull);
      expect(paraPrecautionEn, contains('4,000 mg'));

      // NSAID empty stomach warning
      final ibuPrecautionBn = BnTranslations.getPrecaution('Ibuprofen', language: 'bn');
      expect(ibuPrecautionBn, isNotNull);
      expect(ibuPrecautionBn, contains('ভরা পেটে'));

      // Antibiotic compliance warning
      final aziPrecautionBn = BnTranslations.getPrecaution('Azithromycin', language: 'bn');
      expect(aziPrecautionBn, isNotNull);
      expect(aziPrecautionBn, contains('কোর্স'));

      // Antibiotic fallback heuristic for unprofiled antibiotic
      final cefPrecautionBn = BnTranslations.getPrecaution('Cefixime Trihydrate', language: 'bn');
      expect(cefPrecautionBn, isNotNull);
      expect(cefPrecautionBn, contains('সম্পূর্ণ কোর্স'));

      final cefPrecautionEn = BnTranslations.getPrecaution('Cefixime Trihydrate', language: 'en');
      expect(cefPrecautionEn, isNotNull);
      expect(cefPrecautionEn, contains('full course'));
    });
  });

  group('ScanResult Speech & Text Tests', () {
    test('Bangla spokenText is natural, respectful, and includes precaution warnings', () {
      const result = ScanResult(
        medicineName: 'Napa',
        brandName: 'Napa',
        genericName: 'Paracetamol',
        genericNameBn: 'প্যারাসিটামল',
        category: 'ব্যথানাশক ও জ্বর নিবারক (Pain & Fever)',
        summary: 'প্যারাসিটামল জ্বর, মাথাব্যথা ও সাধারণ শারীরিক ব্যথা উপশমে ব্যবহৃত হয়।',
        summaryEn: 'Paracetamol is used to relieve mild to moderate pain and reduce fever.',
        language: 'bn',
        precaution: '২৪ ঘণ্টায় ৪,০০০ মিলিগ্রামের বেশি গ্রহণ করবেন না। অতিরিক্ত মাত্রায় লিভারের ক্ষতি হতে পারে।',
      );

      final spoken = result.spokenText;
      expect(spoken, startsWith('নাপা। এটি প্যারাসিটামল — '));
      expect(spoken, contains('ব্যথানাশক ও জ্বর নিবারক'));
      expect(spoken, contains('জ্বর, মাথাব্যথা'));
      expect(spoken, contains('২৪ ঘণ্টায় ৪,০০০ মিলিগ্রামের বেশি'));
    });

    test('English spokenText is clear, natural, and includes precaution warnings', () {
      const result = ScanResult(
        medicineName: 'Seclo',
        brandName: 'Seclo',
        genericName: 'Omeprazole',
        genericNameBn: 'ওমিপ্রাজল',
        category: 'Gastric & Acidity',
        summary: 'Omeprazole reduces stomach acid and treats gastric ulcers.',
        summaryEn: 'Omeprazole reduces stomach acid and treats gastric ulcers.',
        language: 'en',
        precaution: 'Best taken 30-60 minutes before meals, preferably in the morning.',
        precautionEn: 'Best taken 30-60 minutes before meals, preferably in the morning.',
      );

      final spoken = result.spokenText;
      expect(spoken, startsWith('Seclo. This medicine contains Omeprazole, used for Gastric & Acidity.'));
      expect(spoken, contains('stomach acid'));
      expect(spoken, contains('Precaution: Best taken 30-60 minutes before meals'));
    });
  });
}
