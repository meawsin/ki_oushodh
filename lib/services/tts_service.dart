// lib/services/tts_service.dart

import 'package:flutter_tts/flutter_tts.dart';

// ---------------------------------------------------------------------------
// TTSService
//
// Wraps flutter_tts with:
//   - Language switching (Bangla bn-BD / English en-US)
//   - Graceful fallback to English if Bangla TTS not installed on device
//   - Instant interrupt: calling speak() while playing stops current audio
//   - Accessibility-tuned speech rate (slightly slower than default)
//
// Low-end device note:
//   - flutter_tts uses the OS TTS engine — zero extra APK size
//   - Most Bangladeshi budget phones ship Google TTS (supports bn-BD)
//   - We detect bn-BD availability at init and store the result
// ---------------------------------------------------------------------------
class TTSService {
  final FlutterTts _tts = FlutterTts();
  bool _isBanglaAvailable = false;
  bool _isInitialized = false;

  /// Must be called once before using speak().
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Check if the device TTS engine supports Bangla
    _isBanglaAvailable = await _checkBanglaAvailability();

    await _tts.setVolume(1.0);

    // Slightly slower than default — better for elderly users (PRD §2)
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);

    // Stop TTS when app is paused (e.g., incoming call)
    _tts.setStartHandler(() {});
    _tts.setCompletionHandler(() {});
    _tts.setErrorHandler((_) {});

    _isInitialized = true;
  }

  /// Speaks [text] in the appropriate language.
  ///
  /// If already speaking, STOPS the current audio immediately before
  /// starting the new text (PRD §6 Interruptibility requirement).
  Future<void> speak(String text, {required String language}) async {
    if (!_isInitialized) await initialize();

    // Interrupt any ongoing speech immediately
    await stop();

    // Select language — fall back to English if Bangla not available
    final useLanguage = (language == 'bn' && _isBanglaAvailable)
        ? 'bn-BD'
        : 'en-US';

    await _tts.setLanguage(useLanguage);
    await _tts.speak(text);
  }

  /// Stops any ongoing TTS playback immediately.
  Future<void> stop() async {
    await _tts.stop();
  }

  /// Whether the device supports Bangla TTS.
  /// Exposed so the UI can warn the user if needed.
  bool get isBanglaAvailable => _isBanglaAvailable;

  /// Releases TTS engine resources.
  Future<void> dispose() async {
    await stop();
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<bool> _checkBanglaAvailability() async {
    try {
      final dynamic languages = await _tts.getLanguages;
      if (languages is List) {
        return languages.any((lang) =>
            lang.toString().toLowerCase().contains('bn') ||
            lang.toString().toLowerCase().contains('bengali') ||
            lang.toString().toLowerCase().contains('bangla'));
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}