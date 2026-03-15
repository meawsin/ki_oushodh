// lib/features/scanner/scanner_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/scan_result.dart';
import '../../main.dart';
import '../../services/camera_service.dart';
import '../../services/llm_service.dart';
import '../../services/ocr_service.dart';
import '../../services/tts_service.dart';

// ---------------------------------------------------------------------------
// Language State Provider
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
// Scan State
// ---------------------------------------------------------------------------
sealed class ScanState { const ScanState(); }

class ScanStateInitializing extends ScanState { const ScanStateInitializing(); }

class ScanStateReady extends ScanState { const ScanStateReady(); }

class ScanStateProcessing extends ScanState {
  final String statusMessage;
  const ScanStateProcessing(this.statusMessage);
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
// Service Providers
// ---------------------------------------------------------------------------
final cameraServiceProvider = Provider.autoDispose<CameraService>((ref) {
  final service = CameraService();
  ref.onDispose(() => service.dispose());
  return service;
});

final ocrServiceProvider = Provider<OCRService>((ref) => OCRService());
final llmServiceProvider = Provider<LLMService>((ref) => LLMService());

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
    _ocr = ref.read(ocrServiceProvider);
    _llm = ref.read(llmServiceProvider);
    _tts = ref.read(ttsServiceProvider);
    _initializeServices();
    return const ScanStateInitializing();
  }

  Future<void> onCaptureTapped() async {
    if (state is! ScanStateReady) return;

    final language = ref.read(languageProvider);
    final checkingMsg = language == 'bn' ? 'দেখা হচ্ছে...' : 'Checking...';

    state = ScanStateProcessing(checkingMsg);
    await _tts.speak(checkingMsg, language: language);

    try {
      final imagePath = await _camera.captureFrame();
      final rawText = await _ocr.extractText(imagePath);

      // ADD THIS TEMPORARILY:
      debugPrint('=== OCR RAW TEXT ===\n$rawText\n=== END OCR ===');

      if (rawText.trim().isEmpty) {
        final msg = language == 'bn'
            ? 'কোনো লেখা পাওয়া যায়নি। ক্যামেরা ওষুধের কাছে ধরুন।'
            : 'No text found. Please hold the camera closer to the medicine.';
        state = const ScanStateNoTextFound();
        await _tts.speak(msg, language: language);
        return;
      }

      final result = await _llm.identifyMedicine(
        rawOcrText: rawText,
        language: language,
      );

      state = ScanStateResult(result);
      await _tts.speak(result.spokenText, language: language);

    } on CameraServiceException catch (e) {
      state = ScanStateError(e.message);
      await _tts.speak(e.message, language: language);
    } on OCRServiceException catch (e) {
      state = ScanStateError(e.message);
      await _tts.speak(e.message, language: language);
    } on LLMServiceException catch (e) {
      state = ScanStateError(e.message);
      await _tts.speak(e.message, language: language);
    } catch (_) {
      final msg = language == 'bn'
          ? 'একটি সমস্যা হয়েছে। আবার চেষ্টা করুন।'
          : 'Something went wrong. Please try again.';
      state = ScanStateError(msg);
      await _tts.speak(msg, language: language);
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
      await Future.wait([_tts.initialize(), _camera.initialize()]);

      final language = ref.read(languageProvider);
      final promptMsg = language == 'bn'
          ? 'ওষুধের দিকে ক্যামেরা ধরুন এবং স্ক্রিনে ট্যাপ করুন।'
          : 'Please point the camera at the medicine and tap the screen.';

      state = const ScanStateReady();
      await _tts.speak(promptMsg, language: language);

    } on CameraServiceException catch (e) {
      state = ScanStateError(e.message);
    }
  }
}