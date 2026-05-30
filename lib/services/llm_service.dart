// lib/services/llm_service.dart
//
// Medicine identification pipeline:
//   1. Load local brand index + medicine DB from bundled assets
//   2. Extract candidate medicine names from OCR text
//   3. Local lookup (exact → fuzzy → partial match)
//   4. Wikipedia fallback for unrecognized medicines (requires internet)
//
// Key fixes vs original:
//   - Summary truncation raised: 120 chars was too short for useful info (→ 220)
//   - _cleanRaw now preserves full meaningful sentences, not just first 120 chars
//   - _simplify() builds a complete, natural sentence — not a dangling clause
//   - Bangla fallback frame now grammatically complete
//   - Wikipedia extract now uses first 2 sentences (not just 1) for richer info
//   - _firstTwoSentences() instead of _firstSentence() for fuller output
//   - Error messages bilingual and specific

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../core/constants/bn_translations.dart';
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

    final localResult = _lookupLocal(candidates, language);
    if (localResult != null) return localResult;

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
    } catch (_) {
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
        final clean = word.replaceAll(RegExp(r"""['"`*!]+"""), '').trim();
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
          .replaceAll(RegExp(r"""['"`*!]+"""), '').trim();
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

      String? genericName = _brandIndex![key];

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
      final summaryEn = _buildEnglishSummary(rawSummary, genericName);
      final summary = language == 'bn'
          ? _buildBanglaSummary(rawSummary, genericName)
          : summaryEn;

      final displayBrand = candidate[0].toUpperCase() + candidate.substring(1);

      return ScanResult(
        medicineName: displayBrand,
        brandName: displayBrand,
        genericName: genericName,
        summary: summary,
        summaryEn: summaryEn,
        language: language,
      );
    }
    return null;
  }

  /// Builds a natural Bangla summary.
  /// Uses the translation map for idiomatic phrasing; falls back gracefully.
  String _buildBanglaSummary(String raw, String genericName) {
    final translated = BnTranslations.translateSummary(raw, genericName);
    if (translated != raw) return translated;

    final cleaned = _cleanRaw(raw);
    if (cleaned.isEmpty) return '$genericName হলো একটি ওষুধ।';
    return 'এই ওষুধটি $cleaned এর জন্য ব্যবহার করা হয়।';
  }

  /// Builds a complete, informative English summary.
  /// Preserves enough context to be genuinely useful (up to 220 chars).
  String _buildEnglishSummary(String raw, String genericName) {
    if (raw.isEmpty) return 'This medicine contains $genericName.';

    final cleaned = _cleanRaw(raw);
    if (cleaned.isEmpty) return 'This medicine contains $genericName.';

    // If cleaned text already starts naturally, use it
    if (RegExp(r'^(this|used|treats|helps)', caseSensitive: false).hasMatch(cleaned)) {
      return cleaned;
    }
    return 'This medicine is used for $cleaned';
  }

  /// Strips clinical preamble and caps at 220 chars (was 120 — too short).
  /// Now tries to end on a complete sentence boundary.
  String _cleanRaw(String raw) {
    String cleaned = raw
        .replaceAll(RegExp(r'^[^:]+is indicated (for|in)[:\s]*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^[^:]+is used (for|in)[:\s]*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^[^:]+indicated[:\s]*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^\s*[-•]\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Cap at 220 chars, trying to land on a sentence end
    if (cleaned.length > 220) {
      final sub = cleaned.substring(0, 220);
      // Prefer to end on a period within the last 60 chars
      final lastPeriod = sub.lastIndexOf('.', 220);
      if (lastPeriod > 160) {
        cleaned = sub.substring(0, lastPeriod + 1);
      } else {
        final lastSpace = sub.lastIndexOf(' ');
        cleaned = '${sub.substring(0, lastSpace)}...';
      }
    }
    return cleaned;
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

      final medKeywords = ['drug', 'medication', 'medicine', 'antibiotic',
          'analgesic', 'treatment', 'tablet', 'capsule', 'pharmaceutical'];
      if (!medKeywords.any((kw) =>
          description.contains(kw) || extract.toLowerCase().contains(kw))) {
        return null;
      }

      // Use first 2 sentences for richer context (was only 1 — often incomplete)
      final summaryEn = _firstTwoSentences(extract);
      final summary = language == 'bn'
          ? BnTranslations.translateSummary(summaryEn, title)
          : summaryEn;

      return ScanResult(
        medicineName: title,
        brandName: candidate,
        genericName: title,
        summary: summary == summaryEn && language == 'bn'
            ? 'এই ওষুধটি $summaryEn এর জন্য ব্যবহার করা হয়।'
            : summary,
        summaryEn: summaryEn,
        language: language,
      );
    }
    return null;
  }

  /// Returns up to 2 sentences from [text], capped at 280 chars.
  /// Original returned only 1 sentence — often cut off mid-thought.
  String _firstTwoSentences(String text) {
    final matches = RegExp(r'([^.!?]+[.!?])').allMatches(text).take(2).toList();
    if (matches.isEmpty) return text.length > 280 ? '${text.substring(0, 277)}...' : text;
    final combined = matches.map((m) => m.group(1)?.trim() ?? '').join(' ');
    return combined.length > 280 ? '${combined.substring(0, 277)}...' : combined;
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
