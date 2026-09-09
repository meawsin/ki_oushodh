import 'package:flutter_test/flutter_test.dart';
import 'package:ki_oushodh/services/llm_service.dart';
import 'package:ki_oushodh/services/ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ocrService = OCRService();
  final llmService = LLMService();

  group('Blister Pack Scenarios', () {
    test('Glued dosages without whitespace (Napa500, Sergel20, Maxpro20, Pantonix20, Ciprocin500)', () async {
      final tests = {
        'Napa500': 'napa',
        'Sergel20': 'sergel',
        'Maxpro20': 'maxpro',
        'Pantonix20': 'pantonix',
        'Ciprocin500': 'ciprocin',
      };

      for (final entry in tests.entries) {
        final res = await llmService.identifyMedicine(rawOcrText: entry.key, language: 'bn');
        expect(res.medicineName.toLowerCase(), contains(entry.value),
            reason: 'Should identify ${entry.key} as ${entry.value}');
      }
    });

    test('Hyphenated and plus notation on blister packaging (Seclo-20, Monas-10, Ace+ 500)', () async {
      final resSeclo = await llmService.identifyMedicine(rawOcrText: 'Seclo-20', language: 'bn');
      expect(resSeclo.medicineName.toLowerCase(), contains('seclo'));

      final resMonas = await llmService.identifyMedicine(rawOcrText: 'Monas-10', language: 'bn');
      expect(resMonas.medicineName.toLowerCase(), contains('monas'));

      final resAce = await llmService.identifyMedicine(rawOcrText: 'Ace+ 500', language: 'bn');
      expect(resAce.medicineName.toLowerCase(), contains('ace'));
    });

    test('Common OCR letter substitutions on shiny foil (0meprazole, Sec1o, Serge1, Paracetamo1)', () async {
      final resOme = await llmService.identifyMedicine(rawOcrText: '0meprazole 20mg', language: 'bn');
      expect(resOme.genericName.toLowerCase(), contains('omeprazole'));

      final resSec = await llmService.identifyMedicine(rawOcrText: 'Sec1o 20', language: 'bn');
      expect(resSec.medicineName.toLowerCase(), contains('seclo'));

      final resSer = await llmService.identifyMedicine(rawOcrText: 'Serge1 20', language: 'bn');
      expect(resSer.medicineName.toLowerCase(), contains('sergel'));

      final resPara = await llmService.identifyMedicine(rawOcrText: 'Paracetamo1 500mg', language: 'bn');
      expect(resPara.genericName.toLowerCase(), contains('paracetamol'));
    });

    test('Registered trademarks and spaced uppercase blister text (Napa® 500, S E C L O 20)', () async {
      final resTm = await llmService.identifyMedicine(rawOcrText: 'Napa® 500', language: 'bn');
      expect(resTm.medicineName.toLowerCase(), contains('napa'));

      final resSpaced = await llmService.identifyMedicine(rawOcrText: 'S E C L O 20', language: 'bn');
      expect(resSpaced.medicineName.toLowerCase(), contains('seclo'));
    });

    test('validateAsMedicine on real cut blister texts', () {
      final samples = [
        'SECLO 20\nOMEPRAZOLE',
        'Napa 500',
        'ACE PLUS',
        'MONAS 10',
        'SERGEL 20',
        'MAXPRO 20',
        'Ciprocin 500',
      ];
      for (final s in samples) {
        final err = ocrService.validateAsMedicine(s, 'bn');
        expect(err, isNull, reason: 'Cut blister packet "$s" should pass validation');
      }
    });

    test('Non-medicine text is rejected by validation', () {
      const nonMedicine = 'The quick brown fox jumps over the lazy dog\nChapter 3 Page 42';
      final err = ocrService.validateAsMedicine(nonMedicine, 'bn');
      expect(err, isNotNull);
    });
  });
}
