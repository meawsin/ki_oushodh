// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:ki_oushodh/services/llm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final llmService = LLMService();

  test('1. Verify MaxOmega recognition and Bengali text', () async {
    final samples = [
      'MaxOmega\nOmega-3 Acid Ethyl Esters 1000 mg\nRenata',
      'Max Omega\nOmega-3 Acid Ethyl Esters 1000 mg\nRenata',
      'Max Omega 1000\nRenata',
      'MAXOMEGA\nSalmon Fish Oil\nRenata Limited',
      'Max Omega\nEPA DHA Folic Acid',
      'Omega-3 Acid Ethyl Esters 1000 mg\nRenata',
      'Salmon Fish Oil 1000 mg\nRenata',
    ];

    for (final s in samples) {
      final res = await llmService.identifyMedicine(rawOcrText: s, language: 'bn');
      print('=== MaxOmega Test: ${s.replaceAll("\n", " | ")} ===');
      print('MedicineName: ${res.medicineName}');
      print('GenericName: ${res.genericName}');
      print('Category: ${res.category}');
      print('Summary: ${res.summary}');
      print('SpokenText: ${res.spokenText}\n');

      expect(res.genericName.toLowerCase().contains('omega-3') || res.genericName.toLowerCase().contains('salmon'), isTrue);
      // Ensure no Folic Acid or Ethyl Alcohol false match
      expect(res.genericName.toLowerCase().contains('folic'), isFalse);
      expect(res.genericName.toLowerCase().contains('alcohol'), isFalse);
      // Ensure no raw English sentence in Bengali summary
      expect(res.summary.contains('adjunct'), isFalse);
      expect(res.summary.contains('triglyceride (TG)'), isFalse);
    }
  });

  test('2. Verify Napa Extend recognition and Bengali text', () async {
    final samples = [
      'Napa Extend\nParacetamol 665mg\nBeximco',
      'NAPA EXTEND\nParacetamol BP 665 mg',
      'Napa\nExtend\nParacetamol 665mg',
      'Paracetamol 665mg\nNapa\nExtend',
      'Paracetamol BP 665 mg\nNapa Extend\nBeximco',
      'Napa 665 mg\nBeximco',
    ];

    for (final s in samples) {
      final res = await llmService.identifyMedicine(rawOcrText: s, language: 'bn');
      print('=== Napa Extend Test: ${s.replaceAll("\n", " | ")} ===');
      print('MedicineName: ${res.medicineName}');
      print('GenericName: ${res.genericName}');
      print('Category: ${res.category}');
      print('Summary: ${res.summary}');
      print('SpokenText: ${res.spokenText}\n');

      expect(res.medicineName, equals('Napa Extend'));
      expect(res.genericName.toLowerCase(), contains('paracetamol'));
      expect(res.spokenText.contains('নাপা এক্সটেন্ড'), isTrue);
      // Low-literacy check: should not have complex 4000mg / 8x500mg jargon
      expect(res.spokenText.contains('৪০০০ মিলিগ্রাম'), isFalse);
    }
  });

  test('3. Verify Entacyd Plus recognition and Bengali text', () async {
    final samples = [
      'Entacyd Plus\nAntacid\nSquare',
      'Entacyd\nPlus\nChewable Tablet\nSquare',
      'Entacyd Plus\nDried Aluminium Hydroxide Gel USP 400 mg\nMagnesium Hydroxide USP 400 mg\nSimethicone USP 30 mg',
      'Dried Aluminium Hydroxide Gel 400 mg\nMagnesium Hydroxide 400 mg\nSimethicone 30 mg\nEntacyd Plus',
      'Dried Aluminium Hydroxide Gel\nMagnesium Hydroxide\nSimethicone 30 mg\nSquare',
      'Simethicone\nSquare',
    ];

    for (final s in samples) {
      final res = await llmService.identifyMedicine(rawOcrText: s, language: 'bn');
      print('=== Entacyd Plus Test: ${s.replaceAll("\n", " | ")} ===');
      print('MedicineName: ${res.medicineName}');
      print('GenericName: ${res.genericName}');
      print('Category: ${res.category}');
      print('Summary: ${res.summary}');
      print('SpokenText: ${res.spokenText}\n');

      // Ensure no raw English sentence in Bengali summary
      expect(res.summary.contains('Flatulence, abdominal distention'), isFalse);
      // Ensure category is antacid/gas, NOT generic essential medicine
      expect(res.category, isNot(equals('প্রয়োজনীয় ওষুধ')));
    }
  });
}
