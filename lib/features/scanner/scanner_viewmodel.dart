// lib/features/scanner/scanner_viewmodel.dart
//
// Key fixes vs original:
//   - ScanStateProcessing carries a step enum (capturing / reading / identifying)
//     so the UI can show meaningful progress stages instead of "Checking..."
//   - TTS prompt on init reads naturally — no robotic phrasing
//   - Error messages localized consistently
//   - Camera/TTS init now sequential (TTS first — faster perceived startup)

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
    state = ScanStateProcessing(
      ProcessingStep.capturing,
      language == 'bn' ? 'ছবি তোলা হচ্ছে...' : 'Capturing...',
    );

    try {
      final imagePath = await _camera.captureFrame();

      // Step 2: OCR
      state = ScanStateProcessing(
        ProcessingStep.reading,
        language == 'bn' ? 'লেখা পড়া হচ্ছে...' : 'Reading text...',
      );

      final rawText = await _ocr.extractText(imagePath);

      final validationError = _ocr.validateAsMedicine(rawText, language);
      if (validationError != null) {
        state = ScanStateError(validationError);
        await _tts.speak(
          validationError,
          language: language,
          englishFallback:
              'This does not look like medicine packaging. Please scan a medicine strip only.',
        );
        return;
      }

      // Step 3: Identify
      state = ScanStateProcessing(
        ProcessingStep.identifying,
        language == 'bn' ? 'ওষুধ খোঁজা হচ্ছে...' : 'Identifying medicine...',
      );

      final result = await _llm.identifyMedicine(
        rawOcrText: rawText,
        language: language,
      );

      state = ScanStateResult(result);
      await _tts.speak(
        result.spokenText,
        language: language,
        englishFallback: result.spokenTextEn,
      );

    } on CameraServiceException catch (e) {
      state = ScanStateError(e.message);
      await _tts.speak(e.message, language: language, englishFallback: e.message);
    } on OCRServiceException catch (e) {
      state = ScanStateError(e.message);
      await _tts.speak(e.message, language: language, englishFallback: e.message);
    } on LLMServiceException catch (e) {
      state = ScanStateError(e.message);
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
      await _tts.speak(
        msg,
        language: language,
        englishFallback: 'Something went wrong. Please try again.',
      );
    }
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
