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

    final dosagePattern = RegExp(
      r'\b\d+(\.\d+)?\s*(mg|ml|gm|g|mcg|iu|%|v/v|w/v|w/w)\b',
      caseSensitive: false,
    );
    final standaloneNumberPattern = RegExp(r'\b\d+\b');

    final noiseWords = {
      'usp', 'bp', 'ip', 'mg', 'ml', 'gm', 'mcg', 'iu', 'mfg', 'lic',
      'no', 'batch', 'exp', 'date', 'mrp', 'tk', 'bdt', 'double', 'strength',
      'gel', 'dried', 'hydroxide', 'and', 'the', 'for', 'with',
      'tablet', 'tablets', 'capsule', 'capsules', 'syrup', 'suspension',
      'injection', 'square', 'pls', 'plas', 'ltd', 'limited', 'lab',
      'laboratories', 'pharma', 'pharmaceuticals', 'healthcare', 'beximco',
      'incepta', 'renata', 'aristopharma', 'acme', 'popular', 'skf', 'sk+f',
      'radiant', 'ibn', 'sina', 'orion', 'ziska', 'beacon', 'delta', 'silva',
      'tab', 'cap', 'syr', 'inj', 'oral', 'drop', 'drops', 'ointment', 'cream',
    };

    final candidates = <String>[];
    final wordsByLine = <List<String>>[];

    for (final line in lines) {
      // Clean line by removing dosages and numbers
      final cleanedLine = line
          .replaceAll(dosagePattern, ' ')
          .replaceAll(standaloneNumberPattern, ' ')
          .replaceAll(RegExp(r"""['"`*!|#@$%^&+=;:"<>~?/\\]+"""), ' ')
          .trim();

      final words = cleanedLine
          .split(RegExp(r'[\s,]+'))
          .map((w) => w.trim())
          .where((w) => w.length >= 2 && RegExp(r'^[a-zA-Z]').hasMatch(w))
          .toList();

      if (words.isNotEmpty) {
        wordsByLine.add(words);
      }
    }

    // 1. Multi-word phrases directly matching brand index (e.g. "Napa Extra", "Ace Plus")
    for (final words in wordsByLine) {
      for (int i = 0; i < words.length; i++) {
        // 2-word phrase
        if (i + 1 < words.length) {
          final phrase2 = '${words[i]} ${words[i + 1]}';
          final lower2 = phrase2.toLowerCase();
          if (_brandIndex != null && _brandIndex!.containsKey(lower2)) {
            if (!candidates.contains(phrase2)) candidates.add(phrase2);
          }
        }
        // 3-word phrase
        if (i + 2 < words.length) {
          final phrase3 = '${words[i]} ${words[i + 1]} ${words[i + 2]}';
          final lower3 = phrase3.toLowerCase();
          if (_brandIndex != null && _brandIndex!.containsKey(lower3)) {
            if (!candidates.contains(phrase3)) candidates.add(phrase3);
          }
        }
      }
    }

    // 2. Exact single-word matches in brand index or medicine db
    for (final words in wordsByLine) {
      for (final word in words) {
        final lower = word.toLowerCase();
        if (noiseWords.contains(lower)) continue;
        if ((_brandIndex != null && _brandIndex!.containsKey(lower)) ||
            (_medicineDb != null && _medicineDb!.containsKey(lower))) {
          if (!candidates.contains(word)) candidates.add(word);
        }
      }
    }

    // 3. Multi-word phrases not yet matched (for fuzzy / tier lookup)
    for (final words in wordsByLine) {
      for (int i = 0; i < words.length; i++) {
        if (i + 1 < words.length) {
          final phrase2 = '${words[i]} ${words[i + 1]}';
          if (!candidates.contains(phrase2)) candidates.add(phrase2);
        }
      }
    }

    // 4. Remaining clean words
    for (final words in wordsByLine) {
      for (final word in words) {
        final lower = word.toLowerCase();
        if (noiseWords.contains(lower)) continue;
        if (word.length >= 3 && !candidates.contains(word)) {
          candidates.add(word);
        }
      }
    }

    // Fallback: if candidates is empty, use non-empty lines
    if (candidates.isEmpty) {
      for (final line in lines) {
        final firstWord = line.split(RegExp(r'\s+')).first;
        if (firstWord.length >= 3 && RegExp(r'^[a-zA-Z]').hasMatch(firstWord)) {
          candidates.add(firstWord);
        }
      }
    }

    return candidates.take(8).toList();
  }

  ScanResult? _lookupLocal(List<String> candidates, String language) {
    if (_brandIndex == null || _medicineDb == null) return null;

    // Tier 1: Exact match in brand index
    for (final candidate in candidates) {
      final key = candidate.toLowerCase().trim();
      final generic = _brandIndex![key];
      if (generic != null) {
        return _buildResult(
          brandName: candidate,
          genericName: generic,
          language: language,
        );
      }
    }

    // Tier 2: Exact or prefix match in medicine DB (candidate IS generic name)
    for (final candidate in candidates) {
      final key = candidate.toLowerCase().trim();
      if (_medicineDb!.containsKey(key)) {
        return _buildResult(
          brandName: _toTitleCase(key),
          genericName: _toTitleCase(key),
          language: language,
        );
      }
      // Check prefix for generic names (e.g. "Azithromycin" -> "Azithromycin Dihydrate")
      if (key.length >= 5) {
        for (final genKey in _medicineDb!.keys) {
          if (genKey.startsWith('$key ') || genKey == key) {
            return _buildResult(
              brandName: _toTitleCase(candidate),
              genericName: _toTitleCase(genKey),
              language: language,
            );
          }
        }
      }
    }

    // Tier 3: Hyphen/Whitespace normalized match (e.g. "a cold" vs "a-cold", "e cap" vs "e-cap")
    for (final candidate in candidates) {
      final candNorm = _normalize(candidate);
      if (candNorm.length < 3) continue;

      for (final entry in _brandIndex!.entries) {
        if (_normalize(entry.key) == candNorm) {
          return _buildResult(
            brandName: entry.key,
            genericName: entry.value,
            language: language,
          );
        }
      }

      for (final genKey in _medicineDb!.keys) {
        if (_normalize(genKey) == candNorm) {
          return _buildResult(
            brandName: _toTitleCase(candidate),
            genericName: _toTitleCase(genKey),
            language: language,
          );
        }
      }
    }

    // Tier 4: Multi-word boundary / prefix match
    for (final candidate in candidates) {
      final key = candidate.toLowerCase().trim();
      if (key.length < 4) continue;

      String? bestBrand;
      String? bestGeneric;
      int minLenDiff = 999;

      for (final entry in _brandIndex!.entries) {
        final brand = entry.key;
        if (brand.startsWith('$key ') || brand.endsWith(' $key')) {
          final diff = (brand.length - key.length).abs();
          if (diff < minLenDiff) {
            minLenDiff = diff;
            bestBrand = brand;
            bestGeneric = entry.value;
          }
        }
      }

      if (bestBrand != null && minLenDiff <= 8) {
        return _buildResult(
          brandName: bestBrand,
          genericName: bestGeneric!,
          language: language,
        );
      }
    }

    // Tier 5: Levenshtein distance fuzzy matching for OCR typos
    // (e.g. "SecIo" -> "seclo", "SergeI" -> "sergel", "ParacetamoI" -> "paracetamol")
    String? bestFuzzyBrand;
    String? bestFuzzyGeneric;
    int lowestDistance = 999;

    for (final candidate in candidates) {
      final key = candidate.toLowerCase().trim();
      if (key.length < 4) continue;

      final maxAllowedDist = key.length <= 6 ? 1 : 2;

      for (final entry in _brandIndex!.entries) {
        final brand = entry.key;
        if ((brand.length - key.length).abs() > maxAllowedDist) continue;

        // First character heuristic: allow similar substitutions
        final firstMatch = brand[0] == key[0] ||
            (brand[0] == 's' && key[0] == '5') ||
            (brand[0] == 'o' && key[0] == '0') ||
            (brand[0] == 'i' && key[0] == 'l');
        if (!firstMatch) continue;

        final dist = _levenshtein(key, brand);
        if (dist <= maxAllowedDist && dist < lowestDistance) {
          lowestDistance = dist;
          bestFuzzyBrand = brand;
          bestFuzzyGeneric = entry.value;
        }
      }
    }

    if (bestFuzzyBrand != null && bestFuzzyGeneric != null) {
      return _buildResult(
        brandName: bestFuzzyBrand,
        genericName: bestFuzzyGeneric,
        language: language,
      );
    }

    return null;
  }

  ScanResult _buildResult({
    required String brandName,
    required String genericName,
    required String language,
  }) {
    final genericBn = BnTranslations.getGenericNameBn(genericName);
    final category = BnTranslations.getCategory(genericName, language: language);

    final rawDesc = _medicineDb?[genericName.toLowerCase()] ?? '';

    final summaryBn = BnTranslations.translateSummary(rawDesc, genericName);
    final summaryEn = BnTranslations.getEnglishSummary(rawDesc, genericName);

    final summary = language == 'bn' ? summaryBn : summaryEn;
    final displayBrand = _toTitleCase(brandName);

    return ScanResult(
      medicineName: displayBrand,
      brandName: displayBrand,
      genericName: genericName,
      genericNameBn: genericBn,
      category: category,
      summary: summary,
      summaryEn: summaryEn,
      language: language,
    );
  }

  Future<ScanResult?> _lookupWikipedia(String candidate, String language) async {
    final encoded = Uri.encodeComponent(candidate);
    final url = 'https://en.wikipedia.org/api/rest_v1/page/summary/$encoded';

    final response = await http
        .get(Uri.parse(url), headers: {
          'User-Agent': 'KiOushodh/1.0 (https://github.com/meawsin/ki_oushodh; accessible.medicine.identifier@gmail.com)',
        })
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final description = (json['description'] as String? ?? '').toLowerCase();
      final extract = json['extract'] as String? ?? '';
      final title = json['title'] as String? ?? candidate;

      final medKeywords = [
        'drug', 'medication', 'medicine', 'antibiotic',
        'analgesic', 'treatment', 'tablet', 'capsule', 'pharmaceutical'
      ];
      if (!medKeywords.any((kw) =>
          description.contains(kw) || extract.toLowerCase().contains(kw))) {
        return null;
      }

      final summaryEn = _firstTwoSentences(extract);
      final summaryBn = BnTranslations.translateSummary(summaryEn, title);
      final genericBn = BnTranslations.getGenericNameBn(title);
      final category = BnTranslations.getCategory(title, language: language);

      return ScanResult(
        medicineName: title,
        brandName: candidate,
        genericName: title,
        genericNameBn: genericBn,
        category: category,
        summary: language == 'bn' ? summaryBn : summaryEn,
        summaryEn: summaryEn,
        language: language,
      );
    }
    return null;
  }

  String _firstTwoSentences(String text) {
    final matches = RegExp(r'([^.!?]+[.!?])').allMatches(text).take(2).toList();
    if (matches.isEmpty) return text.length > 280 ? '${text.substring(0, 277)}...' : text;
    final combined = matches.map((m) => m.group(1)?.trim() ?? '').join(' ');
    return combined.length > 280 ? '${combined.substring(0, 277)}...' : combined;
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[\s\-_\.]+'), '');

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        final cost = (s.codeUnitAt(i) == t.codeUnitAt(j)) ? 0 : 1;
        final a = v1[j] + 1;
        final b = v0[j + 1] + 1;
        final c = v0[j] + cost;
        v1[j + 1] = (a < b) ? (a < c ? a : c) : (b < c ? b : c);
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
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
