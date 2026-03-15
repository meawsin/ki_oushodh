// lib/services/llm_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../domain/models/scan_result.dart';

class LLMService {
  Map<String, String>? _brandIndex;
  Map<String, String>? _medicineDb;

  Future<ScanResult> identifyMedicine({
    required String rawOcrText,
    required String language,
  }) async {
    if (rawOcrText.trim().length < 3) {
      throw LLMServiceException.forLanguage(
        en: 'Not enough text found. Please hold the camera steadier and closer.',
        bn: 'যথেষ্ট লেখা পাওয়া যায়নি। ক্যামেরা আরও কাছে ও স্থির রাখুন।',
        language: language,
      );
    }

    await _ensureLoaded();

    final candidates = _extractCandidates(rawOcrText);
    debugPrint('=== OCR CANDIDATES ===\n${candidates.join(", ")}\n===');

    final localResult = _lookupLocal(candidates, language);
    if (localResult != null) {
      debugPrint('=== LOCAL DB HIT: ${localResult.medicineName} ===');
      return localResult;
    }

    debugPrint('=== LOCAL DB MISS — trying Wikipedia ===');
    try {
      for (final candidate in candidates) {
        final wikiResult = await _lookupWikipedia(candidate, language);
        if (wikiResult != null) return wikiResult;
      }
    } on SocketException {
      throw LLMServiceException.forLanguage(
        en: 'No internet connection. Please connect and try again.',
        bn: 'ইন্টারনেট সংযোগ নেই। সংযোগ দিয়ে আবার চেষ্টা করুন।',
        language: language,
      );
    } on TimeoutException {
      throw LLMServiceException.forLanguage(
        en: 'Connection timed out. Please try again.',
        bn: 'সংযোগে সমস্যা হয়েছে। আবার চেষ্টা করুন।',
        language: language,
      );
    }

    throw LLMServiceException.forLanguage(
      en: 'Medicine not recognized. Try scanning the name area more clearly.',
      bn: 'ওষুধটি চেনা যায়নি। ওষুধের নামের অংশটি স্পষ্টভাবে স্ক্যান করুন।',
      language: language,
    );
  }

  Future<void> _ensureLoaded() async {
    if (_brandIndex != null) return;
    try {
      final indexStr = await rootBundle.loadString('assets/data/brand_index.json');
      final dbStr = await rootBundle.loadString('assets/data/medicine_db.json');
      _brandIndex = Map<String, String>.from(jsonDecode(indexStr));
      _medicineDb = Map<String, String>.from(jsonDecode(dbStr));
      debugPrint('=== DB LOADED: ${_brandIndex!.length} brands, ${_medicineDb!.length} generics ===');
    } catch (e) {
      debugPrint('=== DB LOAD ERROR ===\n$e\n===');
      _brandIndex = {};
      _medicineDb = {};
    }
  }

  List<String> _extractCandidates(String rawText) {
    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    final noiseWords = {
      'usp', 'bp', 'ip', 'mg', 'ml', 'gm', 'mcg', 'iu', 'mfg', 'lic',
      'no', 'double', 'strength', 'gel', 'dried', 'hydroxide', 'and',
      'the', 'for', 'tablet', 'tablets', 'capsule', 'capsules', 'syrup',
      'injection', 'square', 'pls', 'plas', 'ltd', 'limited', 'lab',
      'laboratories', 'pharma', 'pharmaceuticals', 'plus', 'forte',
    };

    final candidates = <String>[];

    // Pass 1: full line exact match (multi-word brands like "Entacyd Plus")
    for (final line in lines) {
      if (_brandIndex!.containsKey(line.toLowerCase().trim())) {
        candidates.insert(0, line.trim());
      }
    }

    // Pass 2: word-level exact match
    for (final line in lines) {
      final words = line.split(RegExp(r'[\s,./\\()\[\]]+'));
      for (final word in words) {
        final clean = word.replaceAll(RegExp(r"""['""`*!]+"""), '').trim();
        if (clean.length < 3) continue;
        if (noiseWords.contains(clean.toLowerCase())) continue;
        if (RegExp(r'^\d+$').hasMatch(clean)) continue;
        if (!RegExp(r'^[a-zA-Z]').hasMatch(clean)) continue;
        if (_brandIndex!.containsKey(clean.toLowerCase()) && !candidates.contains(clean)) {
          candidates.add(clean);
        }
      }
    }

    // Pass 3: fuzzy — last resort
    for (final line in lines) {
      final first = line.split(RegExp(r'[\s,.]')).first
          .replaceAll(RegExp(r"""['""`*!]+"""), '').trim();
      if (first.length >= 3 &&
          !noiseWords.contains(first.toLowerCase()) &&
          RegExp(r'^[a-zA-Z]').hasMatch(first) &&
          !candidates.contains(first)) {
        candidates.add(first);
      }
    }

    return candidates.take(5).toList();
  }

  ScanResult? _lookupLocal(List<String> candidates, String language) {
    for (final candidate in candidates) {
      final key = candidate.toLowerCase().trim();

      // Exact brand match
      String? genericName = _brandIndex![key];

      // Fuzzy match if exact fails
      if (genericName == null) {
        for (final brand in _brandIndex!.keys) {
          if (brand.contains(key) || key.contains(brand)) {
            genericName = _brandIndex![brand];
            break;
          }
        }
      }

      if (genericName == null) continue;

      final rawSummary = _medicineDb![genericName.toLowerCase()] ?? '';
      final summary = _simplify(rawSummary, genericName, language);

      // Display brand name cleanly — capitalize first letter
      final displayBrand = candidate[0].toUpperCase() + candidate.substring(1);

      return ScanResult(
        medicineName: displayBrand,
        brandName: displayBrand,
        genericName: genericName,
        summary: summary,
        language: language,
      );
    }
    return null;
  }

  /// Converts clinical database text into plain accessible language.
  ///
  /// Database summaries sound like: "Paracetamol is indicated for fever,
  /// common cold and influenza, headache..."
  ///
  /// We want: "This medicine is used for fever, headache, and pain relief."
  String _simplify(String raw, String genericName, String language) {
    if (raw.isEmpty) {
      return language == 'bn'
          ? '$genericName গ্রুপের একটি ওষুধ।'
          : 'This medicine contains $genericName.';
    }

    // Strip clinical preamble patterns
    String cleaned = raw
        .replaceAll(RegExp(r'^[^:]+is indicated (for|in)[:\s]*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^[^:]+is used (for|in)[:\s]*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^[^:]+indicated[:\s]*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^\s*[-•]\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Take only up to first 120 characters to keep it brief for TTS
    if (cleaned.length > 120) {
      final cut = cleaned.substring(0, 120);
      final lastSpace = cut.lastIndexOf(' ');
      cleaned = '${cut.substring(0, lastSpace)}...';
    }

    if (language == 'bn') {
      return 'এই ওষুধটি $cleaned এর জন্য ব্যবহার করা হয়।';
    } else {
      // Ensure it starts naturally
      if (!cleaned.toLowerCase().startsWith('this')) {
        return 'This medicine is used for $cleaned';
      }
      return cleaned;
    }
  }

  Future<ScanResult?> _lookupWikipedia(String candidate, String language) async {
    final encoded = Uri.encodeComponent(candidate);
    final url = 'https://en.wikipedia.org/api/rest_v1/page/summary/$encoded';

    final response = await http
        .get(Uri.parse(url), headers: {'User-Agent': 'KiOushodh/1.0'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final description = (json['description'] as String? ?? '').toLowerCase();
      final extract = json['extract'] as String? ?? '';
      final title = json['title'] as String? ?? candidate;

      final medKeywords = ['drug','medication','medicine','antibiotic','analgesic','treatment','tablet','capsule'];
      if (!medKeywords.any((kw) => description.contains(kw) || extract.toLowerCase().contains(kw))) {
        return null;
      }

      final summary = _firstSentence(extract);
      return ScanResult(
        medicineName: title,
        brandName: candidate,
        genericName: title,
        summary: summary,
        language: language,
      );
    }
    return null;
  }

  String _firstSentence(String text) {
    final match = RegExp(r'([^.!?]+[.!?])').firstMatch(text);
    final s = match?.group(1)?.trim() ?? text;
    return s.length > 180 ? '${s.substring(0, 177)}...' : s;
  }
}

class LLMServiceException implements Exception {
  final String message;
  const LLMServiceException._raw(this.message);

  factory LLMServiceException.forLanguage({
    required String en,
    required String bn,
    required String language,
  }) => LLMServiceException._raw(language == 'bn' ? bn : en);

  @override
  String toString() => 'LLMServiceException: $message';
}