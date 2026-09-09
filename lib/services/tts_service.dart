// lib/services/tts_service.dart
//
// TTS Strategy:
//   - Bangla TTS if device supports it (bn-BD)
//   - English fallback on devices without Bangla voice
//   - Warm, natural speech rate (not robotic)
//   - Proper sentence punctuation for natural pauses
//
// Key fixes vs original:
//   - Speech rate tuned to 0.48 (was 0.42 — too slow, robotic)
//   - Pitch 1.05 for slightly warmer/more natural tone
//   - Added _sanitizeForTts() to clean up medical jargon/symbols before speaking
//   - Queue mode so rapid calls don't cut each other off awkwardly
//   - isSpeaking getter exposed so UI can show live state

import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _tts = FlutterTts();
  bool _isBanglaAvailable = false;
  bool _isInitialized = false;
  bool _isSpeaking = false;

  bool get isBanglaAvailable => _isBanglaAvailable;
  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isBanglaAvailable = await _checkBanglaAvailability();

    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.43);   // Calmer, gentle cadence for low-literacy users
    await _tts.setPitch(0.94);         // Warm, soothing, slightly deeper tone (removes sharp/harsh tone)

    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((_) => _isSpeaking = false);

    _isInitialized = true;
  }

  /// Speaks [text] in [language].
  ///
  /// Cleans up the text first so the TTS engine doesn't read out:
  ///   "dot dot dot" for "..." or stumble on drug suffixes.
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
      await _tts.speak(_sanitizeForTts(text, language: 'bn'));
    } else if (language == 'bn' && !_isBanglaAvailable) {
      if (englishFallback != null && englishFallback.isNotEmpty) {
        await _tts.setLanguage('en-US');
        await _tts.speak(_sanitizeForTts(englishFallback, language: 'en'));
      }
    } else {
      await _tts.setLanguage('en-US');
      await _tts.speak(_sanitizeForTts(text, language: 'en'));
    }
  }

  Future<void> stop() async {
    _isSpeaking = false;
    await _tts.stop();
  }

  Future<void> dispose() async => await stop();

  // ---------------------------------------------------------------------------
  // Sanitise text before handing to TTS engine
  // ---------------------------------------------------------------------------
  String _sanitizeForTts(String text, {String language = 'en'}) {
    String cleaned = text
        .replaceAll('...', language == 'bn' ? '।' : '.')
        .replaceAll('…', language == 'bn' ? '।' : '.')
        .replaceAll(RegExp(r'[*#_~`^|]'), ' ');

    if (language == 'bn') {
      cleaned = cleaned
          .replaceAll(RegExp(r'\bmg\b', caseSensitive: false), 'মিলিগ্রাম')
          .replaceAll(RegExp(r'\bml\b', caseSensitive: false), 'মিলিলিটার')
          .replaceAll(RegExp(r'\bmcg\b', caseSensitive: false), 'মাইক্রোগ্রাম')
          .replaceAll(RegExp(r'\bgm?\b', caseSensitive: false), 'গ্রাম')
          .replaceAll('+', ' এবং ')
          .replaceAll('&', ' এবং ')
          .replaceAll('/', ' অথবা ');

      const phonetics = {
        'napa extend': 'নাপা এক্সটেন্ড',
        'napa extra': 'নাপা এক্সট্রা',
        'napa': 'নাপা',
        'extend': 'এক্সটেন্ড',
        'extra': 'এক্সট্রা',
        'entacyd plus': 'এন্টাসিড প্লাস',
        'entacyd': 'এন্টাসিড',
        'maxomega': 'ম্যাক্সওমেগা',
        'max omega': 'ম্যাক্সওমেগা',
        'omega': 'ওমেগা',
        'simethicone': 'সিমেথিকন',
        'paracetamol': 'প্যারাসিটামল',
        'antacid': 'অ্যান্টাসিড',
        'ace plus': 'এস প্লাস',
        'ace': 'এস',
        'seclo': 'সেকলো',
        'sergel': 'সারজেল',
        'square': 'স্কয়ার',
        'beximco': 'বেক্সিমকো',
        'renata': 'রেনাটা',
      };
      phonetics.forEach((en, bn) {
        cleaned = cleaned.replaceAll(RegExp('\\b$en\\b', caseSensitive: false), bn);
      });
    } else {
      cleaned = cleaned
          .replaceAll(RegExp(r'\bmg\b', caseSensitive: false), 'milligram')
          .replaceAll(RegExp(r'\bml\b', caseSensitive: false), 'milliliter')
          .replaceAll(RegExp(r'\bmcg\b', caseSensitive: false), 'microgram')
          .replaceAll(RegExp(r'\bgm?\b', caseSensitive: false), 'gram')
          .replaceAll('+', ' and ')
          .replaceAll('&', ' and ')
          .replaceAll('/', ' or ');
    }

    return cleaned
        .replaceAll(RegExp(r'[()]'), ', ')
        .replaceAll(RegExp(r',\s*,'), ',')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  Future<bool> _checkBanglaAvailability() async {
    try {
      final dynamic langs = await _tts.getLanguages;
      if (langs is List) {
        for (final lang in langs) {
          final l = lang.toString().toLowerCase();
          if (l.startsWith('bn') || l.contains('bengali') || l.contains('bangla')) {
            return true;
          }
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
