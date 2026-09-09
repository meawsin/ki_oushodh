// ignore_for_file: deprecated_member_use
// lib/features/scanner/scanner_viewmodel.dart
//
// Key fixes vs original:
//   - ScanStateProcessing carries a step enum (capturing / reading / identifying)
//     so the UI can show meaningful progress stages instead of "Checking..."
//   - TTS prompt on init reads naturally — no robotic phrasing
//   - Error messages localized consistently
//   - Camera/TTS init now sequential (TTS first — faster perceived startup)

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/scan_result.dart';
import '../../main.dart';
import '../../services/camera_service.dart';
import '../../services/llm_service.dart';
import '../../services/ocr_service.dart';
import '../../services/tts_service.dart';

// ---------------------------------------------------------------------------
// Language
// ---------------------------------------------------------------------------
final languageProvider =
    NotifierProvider<LanguageNotifier, String>(LanguageNotifier.new);

class LanguageNotifier extends Notifier<String> {
  static const _key = 'selected_language';
  static const _defaultLanguage = 'bn';

  @override
  String build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getString(_key) ?? _defaultLanguage;
  }

  Future<void> setLanguage(String lang) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, lang);
    state = lang;
  }

  void toggle() => setLanguage(state == 'bn' ? 'en' : 'bn');
}

// ---------------------------------------------------------------------------
// Scan State — processing now carries a step so UI can show progress stages
// ---------------------------------------------------------------------------
sealed class ScanState { const ScanState(); }

class ScanStateInitializing extends ScanState { const ScanStateInitializing(); }
class ScanStateReady       extends ScanState { const ScanStateReady(); }

enum ProcessingStep { capturing, reading, identifying }

class ScanStateProcessing extends ScanState {
  final ProcessingStep step;
  final String statusMessage;
  const ScanStateProcessing(this.step, this.statusMessage);
}

class ScanStateResult extends ScanState {
  final ScanResult result;
  const ScanStateResult(this.result);
}

class ScanStateNoTextFound extends ScanState { const ScanStateNoTextFound(); }

class ScanStateError extends ScanState {
  final String message;
  const ScanStateError(this.message);
}

// ---------------------------------------------------------------------------
// Service providers
// ---------------------------------------------------------------------------
final cameraServiceProvider = Provider.autoDispose<CameraService>((ref) {
  final service = CameraService();
  ref.onDispose(() => service.dispose());
  return service;
});

final ocrServiceProvider  = Provider<OCRService>((ref) => OCRService());
final llmServiceProvider  = Provider<LLMService>((ref) => LLMService());

final ttsServiceProvider = Provider<TTSService>((ref) {
  final service = TTSService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ---------------------------------------------------------------------------
// ScannerViewModel
// ---------------------------------------------------------------------------
final scannerViewModelProvider =
    NotifierProvider.autoDispose<ScannerViewModel, ScanState>(
  ScannerViewModel.new,
);

class ScannerViewModel extends AutoDisposeNotifier<ScanState> {
  late final CameraService _camera;
  late final OCRService _ocr;
  late final LLMService _llm;
  late final TTSService _tts;

  @override
  ScanState build() {
    _camera = ref.read(cameraServiceProvider);
    _ocr    = ref.read(ocrServiceProvider);
    _llm    = ref.read(llmServiceProvider);
    _tts    = ref.read(ttsServiceProvider);
    _initializeServices();
    return const ScanStateInitializing();
  }

  Future<void> onCaptureTapped() async {
    if (state is! ScanStateReady) return;

    final language = ref.read(languageProvider);

    // Step 1: Capture
    final capturingMsg = language == 'bn' ? 'ছবি তোলা হচ্ছে...' : 'Capturing...';
    state = ScanStateProcessing(ProcessingStep.capturing, capturingMsg);
    SemanticsService.announce(capturingMsg, TextDirection.ltr);

    try {
      final imagePath = await _camera.captureFrame();

      // Step 2: OCR
      final readingMsg = language == 'bn' ? 'লেখা পড়া হচ্ছে...' : 'Reading text...';
      state = ScanStateProcessing(ProcessingStep.reading, readingMsg);
      SemanticsService.announce(readingMsg, TextDirection.ltr);

      final rawText = await _ocr.extractText(imagePath);

      // Guard: empty text check
      if (rawText.trim().isEmpty) {
        final emptyMsg = language == 'bn'
            ? 'কোনো লেখা পাওয়া যায়নি। ওষুধের স্ট্রিপে আরও কাছে ধরুন।'
            : 'No text found. Hold the camera closer to the medicine strip.';
        state = ScanStateError(emptyMsg);
        SemanticsService.announce(emptyMsg, TextDirection.ltr);
        await _tts.speak(emptyMsg, language: language, englishFallback: emptyMsg);
        return;
      }

      // Step 3: Identify
      final identifyingMsg = language == 'bn' ? 'ওষুধ খোঁজা হচ্ছে...' : 'Identifying medicine...';
      state = ScanStateProcessing(ProcessingStep.identifying, identifyingMsg);
      SemanticsService.announce(identifyingMsg, TextDirection.ltr);

      ScanResult result;
      try {
        result = await _llm.identifyMedicine(
          rawOcrText: rawText,
          language: language,
        );
      } on LLMServiceException {
        // If not matched in database, check whether packaging has any pharma signals
        final validationError = _ocr.validateAsMedicine(rawText, language);
        if (validationError != null) {
          state = ScanStateError(validationError);
          SemanticsService.announce(validationError, TextDirection.ltr);
          await _tts.speak(
            validationError,
            language: language,
            englishFallback:
                'This does not look like medicine packaging. Please scan a medicine strip only.',
          );
          return;
        }
        rethrow;
      }

      state = ScanStateResult(result);
      final identifiedMsg = language == 'bn'
          ? '${result.medicineName} চিহ্নিত হয়েছে'
          : 'Identified ${result.medicineName}';
      SemanticsService.announce(identifiedMsg, TextDirection.ltr);

      await _tts.speak(
        result.spokenText,
        language: language,
        englishFallback: result.spokenTextEn,
      );

    } on CameraServiceException catch (e) {
      state = ScanStateError(e.message);
      SemanticsService.announce(e.message, TextDirection.ltr);
      await _tts.speak(e.message, language: language, englishFallback: e.message);
    } on OCRServiceException catch (e) {
      state = ScanStateError(e.message);
      SemanticsService.announce(e.message, TextDirection.ltr);
      await _tts.speak(e.message, language: language, englishFallback: e.message);
    } on LLMServiceException catch (e) {
      state = ScanStateError(e.message);
      SemanticsService.announce(e.message, TextDirection.ltr);
      await _tts.speak(
        e.message,
        language: language,
        englishFallback: 'Could not identify the medicine. Please try again.',
      );
    } catch (_) {
      final msg = language == 'bn'
          ? 'একটি সমস্যা হয়েছে। আবার চেষ্টা করুন।'
          : 'Something went wrong. Please try again.';
      state = ScanStateError(msg);
      SemanticsService.announce(msg, TextDirection.ltr);
      await _tts.speak(
        msg,
        language: language,
        englishFallback: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<bool> toggleTorch() async {
    final isTorch = await _camera.toggleTorch();
    final lang = ref.read(languageProvider);
    final msg = isTorch
        ? (lang == 'bn' ? 'ফ্ল্যাশলাইট চালু হয়েছে' : 'Flashlight on')
        : (lang == 'bn' ? 'ফ্ল্যাশলাইট বন্ধ হয়েছে' : 'Flashlight off');
    SemanticsService.announce(msg, TextDirection.ltr);
    return isTorch;
  }

  Future<void> setFocusPoint(Offset normalizedPoint) async {
    await _camera.setFocusPoint(normalizedPoint);
    final lang = ref.read(languageProvider);
    SemanticsService.announce(
      lang == 'bn' ? 'ক্যামেরা ফোকাস করা হয়েছে' : 'Camera focused',
      TextDirection.ltr,
    );
  }

  Future<void> reset() async {
    await _tts.stop();
    state = const ScanStateReady();
  }

  Future<void> onAppPaused() async {
    await _tts.stop();
    await _camera.pause();
  }

  Future<void> onAppResumed() => _camera.resume();

  Future<void> _initializeServices() async {
    try {
      // TTS first — faster on most devices, so welcome prompt plays sooner
      await _tts.initialize();
      await _camera.initialize();

      final language = ref.read(languageProvider);
      // Natural welcome — not robotic instruction
      final welcomeMsg = language == 'bn'
          ? 'ওষুধের স্ট্রিপটি ধরুন এবং স্ক্যান করুন।'
          : 'Point the camera at a medicine strip and tap Scan.';

      state = const ScanStateReady();
      await _tts.speak(
        welcomeMsg,
        language: language,
        englishFallback: 'Point the camera at a medicine strip and tap Scan.',
      );
    } on CameraServiceException catch (e) {
      state = ScanStateError(e.message);
    }
  }
}
