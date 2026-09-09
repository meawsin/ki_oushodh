// lib/services/ocr_service.dart

import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  // ---------------------------------------------------------------------------
  // Pharmaceutical signals — words that appear on medicine packaging.
  // If NONE of these appear in the OCR text, it's almost certainly not medicine.
  // Kept intentionally broad to avoid false negatives on partial scans.
  // ---------------------------------------------------------------------------
  static const _medicineSignals = {
    // Dosage units
    'mg', 'mcg', 'ml', 'iu', 'usp', 'bp', 'ip', 'gm',
    // Packaging words
    'tablet', 'tablets', 'tab', 'capsule', 'capsules', 'cap',
    'syrup', 'injection', 'cream', 'ointment', 'drops', 'strip',
    'blister', 'sachet', 'gel', 'inhaler', 'suspension',
    // Regulatory / pharma words
    'mfg', 'manufacturing', 'batch', 'exp', 'expiry', 'manufactured',
    'pharma', 'pharmaceuticals', 'laboratories', 'lab', 'ltd',
    'license', 'lic', 'reg', 'registration',
    // Common generic drug words
    'hydroxide', 'hydrochloride', 'sulfate', 'acetate', 'sodium',
    'potassium', 'oxide', 'acid', 'citrate', 'gluconate',
    // Common top generics
    'paracetamol', 'omeprazole', 'esomeprazole', 'pantoprazole',
    'cefixime', 'azithromycin', 'montelukast', 'ciprofloxacin',
    'amoxicillin', 'metformin', 'losartan', 'amlodipine', 'atorvastatin',
    'ibuprofen', 'naproxen', 'cetirizine', 'fexofenadine', 'antacid',
    // Common Bangladeshi pharma brands & companies
    'square', 'acme', 'beximco', 'incepta', 'eskayef', 'opsonin',
    'renata', 'aristopharma', 'healthcare', 'strength', 'dose',
    'double', 'forte', 'plus', 'extra', 'popular', 'skf', 'radiant',
    'napa', 'seclo', 'sergel', 'ace', 'monas', 'maxpro', 'pantonix',
  };

  static const _pharmaSuffixes = {
    'cillin', 'prazole', 'statin', 'sartan', 'floxacin', 'mycin',
    'tidine', 'dipine', 'lukast', 'fenac', 'profen', 'olol', 'pril', 'artan',
  };

  static final _dosageNumberPattern = RegExp(
    r'\b(0\.5|1|2|2\.5|4|5|10|15|20|25|30|40|50|75|100|120|125|150|180|200|250|300|400|500|600|650|750|800|1000)\b',
  );

  // Minimum number of medicine signals required to pass validation
  static const _minSignals = 1;

  Future<String> extractText(String imagePath) async {
    final imageFile = File(imagePath);
    final inputImage = InputImage.fromFile(imageFile);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText result = await recognizer.processImage(inputImage);

      final rawText = result.blocks
          .map((block) => block.text.trim())
          .where((text) => text.isNotEmpty)
          .join('\n');

      return rawText;
    } on Exception catch (e) {
      throw OCRServiceException('Text recognition failed: ${e.toString()}');
    } finally {
      await recognizer.close();
      try {
        if (await imageFile.exists()) await imageFile.delete();
      } catch (_) {}
    }
  }

  /// Validates that the extracted text looks like medicine packaging.
  /// Returns null if valid, or a user-facing error message if not.
  String? validateAsMedicine(String rawText, String language) {
    if (rawText.trim().isEmpty) {
      return language == 'bn'
          ? 'কোনো লেখা পাওয়া যায়নি। ওষুধের স্ট্রিপে আরও কাছে ধরুন।'
          : 'No text found. Hold the camera closer to the medicine strip.';
    }

    final textLower = rawText.toLowerCase();
    final words = textLower
        .split(RegExp(r'[\s\n,./\\()\[\]:;]+'))
        .where((w) => w.isNotEmpty)
        .toSet();

    // Count how many medicine signals appear in the text
    int signalCount = 0;
    for (final signal in _medicineSignals) {
      if (words.contains(signal)) {
        signalCount++;
        break;
      }
    }

    // Check pharma suffixes on words (e.g. "omeprazole" ends with "prazole")
    if (signalCount == 0) {
      for (final word in words) {
        if (word.length >= 6) {
          for (final suffix in _pharmaSuffixes) {
            if (word.endsWith(suffix)) {
              signalCount++;
              break;
            }
          }
          if (signalCount > 0) break;
        }
      }
    }

    // Dosage strength numbers on cut blister strips (e.g. "500", "20", "10")
    if (signalCount == 0 && _dosageNumberPattern.hasMatch(textLower)) {
      signalCount++;
    }

    if (signalCount < _minSignals) {

      return language == 'bn'
          ? 'এটি ওষুধের প্যাকেট মনে হচ্ছে না। শুধুমাত্র ওষুধের স্ট্রিপ বা প্যাকেট স্ক্যান করুন।'
          : 'This doesn\'t look like medicine packaging. Please scan a medicine strip or box only.';
    }

    return null; // Valid
  }
}

class OCRServiceException implements Exception {
  final String message;
  const OCRServiceException(this.message);

  @override
  String toString() => 'OCRServiceException: $message';
}