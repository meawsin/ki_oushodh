// lib/services/llm_service.dart
//
// Medicine identification using:
//   1. Local asset database — 13,929 Bangladeshi brand names (instant, offline)
//   2. Wikipedia REST API fallback — for anything not in local DB
//
// No API key. No LLM. No network required for most Bangladeshi medicines.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../domain/models/scan_result.dart';

class LLMService {
  // Loaded once at first use, kept in memory
  Map<String, String>? _brandIndex;     // brand_lower → generic_name
  Map<String, String>? _medicineDb;     // generic_lower → summary_en

  // --------------------------------------------------------------------------
  // Public API — same interface as before, ViewModel unchanged
  // --------------------------------------------------------------------------
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

    // Step 1: Extract the most likely brand/generic name from OCR text
    final extracted = _extractCandidates(rawOcrText);
    debugPrint('=== OCR CANDIDATES ===\n${extracted.join(", ")}\n===');

    // Step 2: Match against local BD database (13,929 brands)
    final localResult = _lookupLocal(extracted, language);
    if (localResult != null) {
      debugPrint('=== LOCAL DB HIT: ${localResult.medicineName} ===');
      return localResult;
    }

    // Step 3: Wikipedia fallback for unrecognized medicines
    debugPrint('=== LOCAL DB MISS — trying Wikipedia ===');
    try {
      for (final candidate in extracted) {
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

  // --------------------------------------------------------------------------
  // Load JSON assets from Flutter asset bundle (runs once)
  // --------------------------------------------------------------------------
  Future<void> _ensureLoaded() async {
    if (_brandIndex != null) return;

    try {
      final indexStr =
          await rootBundle.loadString('assets/data/brand_index.json');
      final dbStr =
          await rootBundle.loadString('assets/data/medicine_db.json');

      _brandIndex = Map<String, String>.from(jsonDecode(indexStr));
      _medicineDb = Map<String, String>.from(jsonDecode(dbStr));

      debugPrint(
          '=== DB LOADED: ${_brandIndex!.length} brands, ${_medicineDb!.length} generics ===');
    } catch (e) {
      debugPrint('=== DB LOAD ERROR ===\n$e\n===');
      _brandIndex = {};
      _medicineDb = {};
    }
  }

  // --------------------------------------------------------------------------
  // Extract candidate medicine names from noisy OCR text
  //
  // Returns a ranked list — most likely first.
  // Prioritizes words that appear in the DB over heuristics.
  // --------------------------------------------------------------------------
  List<String> _extractCandidates(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final noiseWords = {
      'usp', 'bp', 'ip', 'mg', 'ml', 'gm', 'mcg', 'iu', 'mfg', 'lic',
      'no', 'double', 'strength', 'gel', 'dried', 'hydroxide', 'and',
      'the', 'for', 'tablet', 'tablets', 'capsule', 'capsules', 'syrup',
      'injection', 'square', 'pls', 'plas', 'ltd', 'limited', 'lab',
      'laboratories', 'pharma', 'pharmaceuticals', 'plus', 'forte',
    };

    final candidates = <String>[];

    // Pass 1: Check full line against DB (catches multi-word brand names)
    for (final line in lines) {
      final lineLower = line.toLowerCase().trim();
      if (_brandIndex!.containsKey(lineLower)) {
        candidates.insert(0, line.trim()); // Highest priority
      }
    }

    // Pass 2: Check individual words/tokens
    for (final line in lines) {
      final words = line.split(RegExp(r'[\s,./\\()\[\]]+'));
      for (final word in words) {
        final clean = word.replaceAll(RegExp(r"""['""`*!]+"""), '').trim();
        if (clean.length < 3) continue;
        if (noiseWords.contains(clean.toLowerCase())) continue;
        if (RegExp(r'^\d+$').hasMatch(clean)) continue;
        if (!RegExp(r'^[a-zA-Z]').hasMatch(clean)) continue;

        final wordLower = clean.toLowerCase();
        if (_brandIndex!.containsKey(wordLower)) {
          if (!candidates.contains(clean)) candidates.add(clean);
        }
      }
    }

    // Pass 3: Add remaining non-noise words as last-resort candidates
    for (final line in lines) {
      final firstWord = line.split(RegExp(r'[\s,.]')).first
          .replaceAll(RegExp(r"""['""`*!]+"""), '').trim();
      if (firstWord.length >= 3 &&
          !noiseWords.contains(firstWord.toLowerCase()) &&
          RegExp(r'^[a-zA-Z]').hasMatch(firstWord) &&
          !candidates.contains(firstWord)) {
        candidates.add(firstWord);
      }
    }

    return candidates.take(5).toList(); // Max 5 candidates to try
  }

  // --------------------------------------------------------------------------
  // Local database lookup
  // --------------------------------------------------------------------------
  ScanResult? _lookupLocal(List<String> candidates, String language) {
    for (final candidate in candidates) {
      final key = candidate.toLowerCase();

      // Exact brand match
      final genericName = _brandIndex![key];
      if (genericName != null) {
        final summary = _medicineDb![genericName.toLowerCase()];
        if (summary != null && summary.isNotEmpty) {
          return ScanResult(
            medicineName: '${_getDisplayBrand(candidate)} ($genericName)',
            summary: summary,
            language: language,
          );
        }
        // Brand found but no summary — still return with generic name
        return ScanResult(
          medicineName: '${_getDisplayBrand(candidate)} ($genericName)',
          summary: language == 'bn'
              ? '$genericName গ্রুপের একটি ওষুধ।'
              : 'A medicine containing $genericName.',
          language: language,
        );
      }

      // Fuzzy: check if candidate is contained in any brand name
      // (handles OCR cutting off last chars e.g. "Entacy" → "Entacyd")
      for (final brand in _brandIndex!.keys) {
        if (brand.contains(key) || key.contains(brand)) {
          final gName = _brandIndex![brand]!;
          final summary = _medicineDb![gName.toLowerCase()];
          if (summary != null) {
            return ScanResult(
              medicineName: '${_getDisplayBrand(brand)} ($gName)',
              summary: summary,
              language: language,
            );
          }
        }
      }
    }
    return null;
  }

  String _getDisplayBrand(String raw) {
    // Restore proper casing for display — capitalize first letter
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1);
  }

  // --------------------------------------------------------------------------
  // Wikipedia REST API fallback
  // --------------------------------------------------------------------------
  Future<ScanResult?> _lookupWikipedia(
      String candidate, String language) async {
    final encoded = Uri.encodeComponent(candidate);
    final url =
        'https://en.wikipedia.org/api/rest_v1/page/summary/$encoded';

    final response = await http
        .get(Uri.parse(url), headers: {'User-Agent': 'KiOushodh/1.0'})
        .timeout(const Duration(seconds: 10));

    debugPrint('=== WIKIPEDIA [$candidate]: ${response.statusCode} ===');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final description = json['description'] as String? ?? '';
      final extract = json['extract'] as String? ?? '';
      final title = json['title'] as String? ?? candidate;

      // Only accept results that are medicine-related
      final medicinekeywords = [
        'drug', 'medication', 'medicine', 'pharmaceutical', 'antibiotic',
        'analgesic', 'treatment', 'therapy', 'clinical', 'dose',
        'tablet', 'capsule', 'injection', 'generic',
      ];
      final combined = (description + extract).toLowerCase();
      final isMedical =
          medicinekeywords.any((kw) => combined.contains(kw));

      if (isMedical && extract.isNotEmpty) {
        final summary = _firstSentence(extract);
        return ScanResult(
          medicineName: title,
          summary: summary,
          language: language,
        );
      }
    }
    return null;
  }

  String _firstSentence(String text) {
    final match = RegExp(r'([^.!?]+[.!?])').firstMatch(text);
    final sentence = match?.group(1)?.trim() ?? text;
    return sentence.length > 200 ? '${sentence.substring(0, 197)}...' : sentence;
  }
}

// --------------------------------------------------------------------------
class LLMServiceException implements Exception {
  final String message;
  const LLMServiceException._raw(this.message);

  factory LLMServiceException.forLanguage({
    required String en,
    required String bn,
    required String language,
  }) =>
      LLMServiceException._raw(language == 'bn' ? bn : en);

  @override
  String toString() => 'LLMServiceException: $message';
}