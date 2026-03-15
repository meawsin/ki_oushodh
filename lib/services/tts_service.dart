// lib/services/tts_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _tts = FlutterTts();
  bool _isBanglaAvailable = false;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _isBanglaAvailable = await _checkBanglaAvailability();
    debugPrint('=== TTS: Bangla available: $_isBanglaAvailable ===');

    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.42); // Slightly slower for elderly users
    await _tts.setPitch(1.0);
    _isInitialized = true;
  }

  Future<void> speak(String text, {required String language}) async {
    if (!_isInitialized) await initialize();
    await stop();

    if (language == 'bn' && _isBanglaAvailable) {
      await _tts.setLanguage('bn-BD');
    } else if (language == 'bn' && !_isBanglaAvailable) {
      // Bangla not available — speak English translation note first
      await _tts.setLanguage('en-US');
      debugPrint('=== TTS: Bangla unavailable, using English ===');
    } else {
      await _tts.setLanguage('en-US');
    }

    await _tts.speak(text);
  }

  Future<void> stop() async => await _tts.stop();

  bool get isBanglaAvailable => _isBanglaAvailable;

  Future<void> dispose() async => await stop();

  Future<bool> _checkBanglaAvailability() async {
    try {
      final dynamic langs = await _tts.getLanguages;
      if (langs is List) {
        for (final lang in langs) {
          final l = lang.toString().toLowerCase();
          if (l.startsWith('bn') || l.contains('bengali') || l.contains('bangla')) {
            debugPrint('=== TTS: Found Bangla language: $lang ===');
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('=== TTS language check error: $e ===');
      return false;
    }
  }
}