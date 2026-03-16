// lib/services/tts_service.dart
//
// Bangla TTS strategy:
//   - If device has Bangla TTS → speak in Bangla (bn-BD)
//   - If not → speak the English summary instead of reading Bangla Unicode
//     as gibberish. The LLMService already stores both in ScanResult.
//
// This is the correct behaviour for low-end Bangladeshi devices that ship
// without Google TTS Bengali voice pack.

import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _tts = FlutterTts();
  bool _isBanglaAvailable = false;
  bool _isInitialized = false;

  bool get isBanglaAvailable => _isBanglaAvailable;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isBanglaAvailable = await _checkBanglaAvailability();

    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
    _isInitialized = true;
  }

  /// Speaks [text] in [language].
  ///
  /// If language is 'bn' but Bangla TTS is unavailable, falls back to
  /// speaking [englishFallback] in English instead of garbling Unicode.
  Future<void> speak(
    String text, {
    required String language,
    String? englishFallback,
  }) async {
    if (!_isInitialized) await initialize();
    await stop();

    if (language == 'bn' && _isBanglaAvailable) {
      await _tts.setLanguage('bn-BD');
      await _tts.speak(text);
    } else if (language == 'bn' && !_isBanglaAvailable) {
      // Use English fallback if provided, otherwise skip TTS
      // (better silence than garbled Unicode)
      if (englishFallback != null && englishFallback.isNotEmpty) {
        await _tts.setLanguage('en-US');
        await _tts.speak(englishFallback);
      }
    } else {
      await _tts.setLanguage('en-US');
      await _tts.speak(text);
    }
  }

  Future<void> stop() async => await _tts.stop();
  Future<void> dispose() async => await stop();

  Future<bool> _checkBanglaAvailability() async {
    try {
      final dynamic langs = await _tts.getLanguages;
      if (langs is List) {
        for (final lang in langs) {
          final l = lang.toString().toLowerCase();
          if (l.startsWith('bn') ||
              l.contains('bengali') ||
              l.contains('bangla')) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}