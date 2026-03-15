// lib/services/ocr_service.dart

import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// ---------------------------------------------------------------------------
// OCRService
//
// Responsibilities:
//   - Run on-device ML Kit text recognition on a captured image file
//   - Clean up the temp image file immediately after processing
//   - Return a cleaned raw text string for the LLM service
//
// Low-end device decisions:
//   - Script.latin only — the Latin model is ~1MB vs ~3MB for multi-script.
//     Medicine drug names on Bangladeshi blister packs are always Latin-script
//     (e.g., "Napa 500mg", "Amlodipine") even if surrounding text is Bengali.
//     Bengali script on packaging goes to Gemini as context anyway.
//   - TextRecognizer is created fresh per scan and closed immediately after.
//     Do NOT keep it as a class-level singleton — it holds a native resource
//     that will leak on low-RAM devices if the screen is disposed mid-scan.
//   - The temp file is deleted after processing — critical for low-storage devices.
// ---------------------------------------------------------------------------
class OCRService {
  /// Extracts raw text from the image at [imagePath].
  ///
  /// Cleans up the temp file regardless of success or failure.
  /// Returns an empty string if no text is detected (not an error).
  /// Throws [OCRServiceException] on a hard failure (corrupt image, etc).
  Future<String> extractText(String imagePath) async {
    final imageFile = File(imagePath);
    final inputImage = InputImage.fromFile(imageFile);

    // Create recognizer locally — closed in finally block
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText result = await recognizer.processImage(inputImage);

      // Combine all recognized blocks into a single string.
      // We preserve newlines between blocks — this helps Gemini distinguish
      // between the drug name line and the dosage/manufacturer lines.
      final rawText = result.blocks
          .map((block) => block.text.trim())
          .where((text) => text.isNotEmpty)
          .join('\n');

      return rawText;
    } on Exception catch (e) {
      throw OCRServiceException('Text recognition failed: ${e.toString()}');
    } finally {
      // Always close the recognizer to free the native ML Kit resource
      await recognizer.close();

      // Always delete the temp capture file — do not accumulate on device storage
      try {
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      } catch (_) {
        // Non-fatal — OS will clean up temp files eventually
        // Don't rethrow and mask the real result/error
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Typed exception
// ---------------------------------------------------------------------------
class OCRServiceException implements Exception {
  final String message;
  const OCRServiceException(this.message);

  @override
  String toString() => 'OCRServiceException: $message';
}