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

    final localResult = _lookupLocal(candidates, language, rawOcrText: rawOcrText);
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
    // 0. Pre-process raw OCR text for blister packaging realities:
    // a. Strip trademark and noise symbols (®, ™, ©, •, etc.)
    String preprocessed = rawText
        .replaceAll(RegExp(r'[®™©•★*]'), ' ')
        .replaceAll(RegExp(r'[\u00AE\u2122\u00A9]'), ' ');

    // b. Collapse single spaced uppercase letters (e.g. "S E C L O" -> "SECLO", "N A P A" -> "NAPA")
    preprocessed = preprocessed.replaceAllMapped(
      RegExp(r'\b([A-Za-z])\s+([A-Za-z])\s+([A-Za-z])(?:\s+([A-Za-z]))?(?:\s+([A-Za-z]))?\b'),
      (m) => '${m[1]}${m[2]}${m[3]}${m[4] ?? ""}${m[5] ?? ""}',
    );

    // c. Expand plus symbols into " Plus " (e.g. "Ace+" -> "Ace Plus")
    preprocessed = preprocessed.replaceAll('+', ' Plus ');

    // d. Replace leading OCR digit errors before letters (foil glare errors, e.g. "0meprazole" -> "Omeprazole", "5eclo" -> "Seclo")
    preprocessed = preprocessed.replaceAllMapped(
      RegExp(r'\b0([a-zA-Z]{3,})\b'),
      (m) => 'O${m[1]}',
    );
    preprocessed = preprocessed.replaceAllMapped(
      RegExp(r'\b5([a-zA-Z]{3,})\b'),
      (m) => 'S${m[1]}',
    );
    preprocessed = preprocessed.replaceAllMapped(
      RegExp(r'\b1([a-zA-Z]{4,})\b'),
      (m) => 'I${m[1]}',
    );

    // e. Replace OCR character substitutions inside/at the end of words (e.g. "Sec1o" -> "Seclo", "Serge1" -> "Sergel", "Secl0" -> "Seclo")
    preprocessed = preprocessed.replaceAllMapped(
      RegExp(r'([a-zA-Z])1([a-zA-Z])'),
      (m) => '${m[1]}l${m[2]}',
    );
    preprocessed = preprocessed.replaceAllMapped(
      RegExp(r'\b([a-zA-Z]{3,})1\b'),
      (m) => '${m[1]}l',
    );
    preprocessed = preprocessed.replaceAllMapped(
      RegExp(r'([a-zA-Z])0([a-zA-Z])'),
      (m) => '${m[1]}o${m[2]}',
    );
    preprocessed = preprocessed.replaceAllMapped(
      RegExp(r'\b([a-zA-Z]{3,})0\b'),
      (m) => '${m[1]}o',
    );

    // f. Separate glued letter-to-digit boundaries for strengths (e.g. "Napa500" -> "Napa 500", "Seclo20" -> "Seclo 20")
    preprocessed = preprocessed.replaceAllMapped(
      RegExp(r'([a-zA-Z]+)(\d+)'),
      (m) => '${m[1]} ${m[2]}',
    );

    // g. Separate glued digit-to-letter boundaries for dosage units (e.g. "500mg" -> "500 mg", "20tab" -> "20 tab")
    preprocessed = preprocessed.replaceAllMapped(
      RegExp(r'(\d+)\s*(mg|ml|gm|g|mcg|iu|%|tab|cap|tablet|capsule)\b', caseSensitive: false),
      (m) => '${m[1]} ${m[2]}',
    );

    // h. Separate hyphens between letters and numbers (e.g. "Seclo-20" -> "Seclo 20", "Monas-10" -> "Monas 10")
    preprocessed = preprocessed.replaceAllMapped(
      RegExp(r'([a-zA-Z]+)\-(\d+)'),
      (m) => '${m[1]} ${m[2]}',
    );

    final lines = preprocessed.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    final dosagePattern = RegExp(
      r'\b\d+(\.\d+)?\s*(mg|ml|gm|g|mcg|iu|%|v/v|w/v|w/w)\b',
      caseSensitive: false,
    );
    final standaloneNumberPattern = RegExp(r'\b\d+\b');

    final noiseWords = {
      'usp', 'bp', 'ip', 'mg', 'ml', 'gm', 'g', 'mcg', 'iu', 'mfg', 'lic',
      'no', 'batch', 'exp', 'date', 'mrp', 'tk', 'bdt', 'double', 'strength',
      'gel', 'dried', 'hydroxide', 'and', 'the', 'for', 'with',
      'tablet', 'tablets', 'capsule', 'capsules', 'syrup', 'suspension',
      'injection', 'square', 'pls', 'plas', 'ltd', 'limited', 'lab',
      'laboratories', 'pharma', 'pharmaceuticals', 'healthcare', 'beximco',
      'incepta', 'renata', 'aristopharma', 'acme', 'popular', 'skf', 'sk+f',
      'radiant', 'ibn', 'sina', 'orion', 'ziska', 'beacon', 'delta', 'silva',
      'tab', 'cap', 'syr', 'inj', 'oral', 'drop', 'drops', 'ointment', 'cream',
      'chewable', 'solution', 'elixir', 'emulsion', 'lotion', 'effervescent',
      'pediatric', 'adult', 'daily', 'release', 'delayed', 'extended',
      'acid', 'ethyl', 'esters', 'ester', 'salmon', 'fish', 'oil', 'fatty',
      'plus', 'extra', 'forte', 'ds', 'max', 'xr', 'sr', 'cr', 'mr',
    };

    final candidates = <String>[];
    final wordsByLine = <List<String>>[];

    for (final line in lines) {
      // Clean line by removing dosages and numbers
      final cleanedLine = line
          .replaceAll(dosagePattern, ' ')
          .replaceAll(standaloneNumberPattern, ' ')
          .replaceAll(RegExp(r"""['"`*!|#@$%^&=;:"<>~?/\\]+"""), ' ')
          .trim();

      final words = cleanedLine
          .split(RegExp(r'[\s,]+'))
          .map((w) => w.replaceAll(RegExp(r'^[\-_]+|[\-_]+$'), '').trim())
          .where((w) => w.length >= 2 && RegExp(r'^[a-zA-Z]').hasMatch(w))
          .toList();

      if (words.isNotEmpty) {
        wordsByLine.add(words);
      }
    }

    // 1. Multi-word phrases directly matching brand index (e.g. "Napa Extra", "Ace Plus", "Max Omega")
    for (final words in wordsByLine) {
      for (int i = 0; i < words.length; i++) {
        // 2-word phrase
        if (i + 1 < words.length) {
          final phrase2 = '${words[i]} ${words[i + 1]}';
          final lower2 = phrase2.toLowerCase();
          final noSpace2 = phrase2.replaceAll(RegExp(r'[\s\-_]+'), '').toLowerCase();
          if (_brandIndex != null && (_brandIndex!.containsKey(lower2) || _brandIndex!.containsKey(noSpace2))) {
            if (!candidates.contains(phrase2)) candidates.add(phrase2);
          }
        }
        // 3-word phrase
        if (i + 2 < words.length) {
          final phrase3 = '${words[i]} ${words[i + 1]} ${words[i + 2]}';
          final lower3 = phrase3.toLowerCase();
          final noSpace3 = phrase3.replaceAll(RegExp(r'[\s\-_]+'), '').toLowerCase();
          if (_brandIndex != null && (_brandIndex!.containsKey(lower3) || _brandIndex!.containsKey(noSpace3))) {
            if (!candidates.contains(phrase3)) candidates.add(phrase3);
          }
        }
      }
    }

    // 1b. Multi-word phrases across consecutive lines (e.g. Line 1 "Napa", Line 2 "Extend")
    for (int l = 0; l < wordsByLine.length - 1; l++) {
      if (wordsByLine[l].isNotEmpty && wordsByLine[l + 1].isNotEmpty) {
        final crossPhrase = '${wordsByLine[l].last} ${wordsByLine[l + 1].first}';
        final crossLower = crossPhrase.toLowerCase();
        final crossNoSpace = crossPhrase.replaceAll(RegExp(r'[\s\-_]+'), '').toLowerCase();
        if (_brandIndex != null && (_brandIndex!.containsKey(crossLower) || _brandIndex!.containsKey(crossNoSpace))) {
          if (!candidates.contains(crossPhrase)) candidates.add(crossPhrase);
        }
      }
    }

    // 2. Exact single-word matches in brand index (prioritize brands over generics)
    for (final words in wordsByLine) {
      for (final word in words) {
        final lower = word.toLowerCase();
        if (noiseWords.contains(lower)) continue;
        if (_brandIndex != null && _brandIndex!.containsKey(lower)) {
          if (!candidates.contains(word)) candidates.add(word);
        }
      }
    }

    // 2b. Exact single-word matches in medicine db (generics)
    for (final words in wordsByLine) {
      for (final word in words) {
        final lower = word.toLowerCase();
        if (noiseWords.contains(lower)) continue;
        if (_medicineDb != null && _medicineDb!.containsKey(lower)) {
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
    // Also cross-line 2-word phrases for fuzzy / tier lookup
    for (int l = 0; l < wordsByLine.length - 1; l++) {
      if (wordsByLine[l].isNotEmpty && wordsByLine[l + 1].isNotEmpty) {
        final crossPhrase = '${wordsByLine[l].last} ${wordsByLine[l + 1].first}';
        if (!candidates.contains(crossPhrase)) candidates.add(crossPhrase);
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

    return candidates.take(15).toList();
  }
  ScanResult? _lookupLocal(List<String> candidates, String language, {String rawOcrText = ''}) {
    if (_brandIndex == null || _medicineDb == null) return null;

    // Tier 1: Exact or space-normalized match in brand index
    for (final candidate in candidates) {
      final key = candidate.toLowerCase().trim();
      final noSpaceKey = key.replaceAll(RegExp(r'[\s\-_]+'), '');
      final generic = _brandIndex![key] ?? _brandIndex![noSpaceKey];
      if (generic != null) {
        return _buildResult(
          brandName: candidate,
          genericName: generic,
          language: language,
          rawOcrText: rawOcrText,
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
          rawOcrText: rawOcrText,
        );
      }
      // Check prefix or bracketed generic names (e.g. "Azithromycin" -> "Azithromycin Dihydrate", "Omega-3" -> "Omega-3 Acid Ethyl Esters [Salmon Fish Oil]")
      if (key.length >= 5) {
        for (final genKey in _medicineDb!.keys) {
          if (genKey.startsWith('$key ') ||
              genKey == key ||
              genKey.contains('[$key]') ||
              (key.contains('salmon') && genKey.contains('salmon fish oil')) ||
              (key.contains('omega') && genKey.contains('omega-3'))) {
            return _buildResult(
              brandName: _toTitleCase(candidate),
              genericName: _toTitleCase(genKey),
              language: language,
              rawOcrText: rawOcrText,
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
            rawOcrText: rawOcrText,
          );
        }
      }

      for (final genKey in _medicineDb!.keys) {
        if (_normalize(genKey) == candNorm) {
          return _buildResult(
            brandName: _toTitleCase(candidate),
            genericName: _toTitleCase(genKey),
            language: language,
            rawOcrText: rawOcrText,
          );
        }
      }
    }

    // Tier 4: Multi-word boundary / prefix match
    const blockedSuffixes = {
      'acid', 'plus', 'extra', 'forte', 'ds', 'xr', 'sr', 'cr', 'd', 'dx',
      'max', 'gold', 'silver', 'drop', 'drops', 'oil', 'gel', 'cream',
      'suspension', 'tablet', 'capsule', 'syrup', 'esters', 'ester', 'fatty',
      'ethyl', 'salmon', 'sodium', 'potassium', 'chloride', 'hydrate',
    };

    for (final candidate in candidates) {
      final key = candidate.toLowerCase().trim();
      if (key.length < 4) continue;

      String? bestBrand;
      String? bestGeneric;
      int minLenDiff = 999;

      for (final entry in _brandIndex!.entries) {
        final brand = entry.key;
        final bool canMatchSuffix = !blockedSuffixes.contains(key);
        final bool isMatch = brand.startsWith('$key ') || (canMatchSuffix && brand.endsWith(' $key'));
        if (isMatch) {
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
          rawOcrText: rawOcrText,
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

      // 5a. Check brand index
      for (final entry in _brandIndex!.entries) {
        final brand = entry.key;
        if ((brand.length - key.length).abs() > maxAllowedDist) continue;

        // First character heuristic: allow similar substitutions
        final firstMatch = brand[0] == key[0] ||
            (brand[0] == 's' && key[0] == '5') ||
            (brand[0] == 'o' && key[0] == '0') ||
            (brand[0] == 'i' && (key[0] == 'l' || key[0] == '1')) ||
            (brand[0] == 'l' && (key[0] == 'i' || key[0] == '1')) ||
            (brand[0] == 'b' && key[0] == '8');
        if (!firstMatch) continue;

        final dist = _levenshtein(key, brand);
        if (dist <= maxAllowedDist && dist < lowestDistance) {
          lowestDistance = dist;
          bestFuzzyBrand = brand;
          bestFuzzyGeneric = entry.value;
        }
      }

      // 5b. Check generic database (covers blister strips showing only generic with foil typos)
      for (final genKey in _medicineDb!.keys) {
        final firstWord = genKey.split(' ').first;
        if ((firstWord.length - key.length).abs() > maxAllowedDist) continue;

        final firstMatch = firstWord[0] == key[0] ||
            (firstWord[0] == 's' && key[0] == '5') ||
            (firstWord[0] == 'o' && key[0] == '0') ||
            (firstWord[0] == 'i' && (key[0] == 'l' || key[0] == '1')) ||
            (firstWord[0] == 'l' && (key[0] == 'i' || key[0] == '1')) ||
            (firstWord[0] == 'b' && key[0] == '8');
        if (!firstMatch) continue;

        final dist = _levenshtein(key, firstWord);
        if (dist <= maxAllowedDist && dist < lowestDistance) {
          lowestDistance = dist;
          bestFuzzyBrand = _toTitleCase(genKey);
          bestFuzzyGeneric = _toTitleCase(genKey);
        }
      }
    }

    if (bestFuzzyBrand != null && bestFuzzyGeneric != null) {
      return _buildResult(
        brandName: bestFuzzyBrand,
        genericName: bestFuzzyGeneric,
        language: language,
        rawOcrText: rawOcrText,
      );
    }

    return null;
  }

  ScanResult _buildResult({
    required String brandName,
    required String genericName,
    required String language,
    String rawOcrText = '',
  }) {
    String resolvedBrand = _toTitleCase(brandName);
    String resolvedGeneric = genericName;
    final ocrLower = rawOcrText.toLowerCase();

    // 1. Antacid combination & Entacyd Plus detection:
    final hasAntacidTerms = ocrLower.contains('antacid') ||
        ocrLower.contains('aluminium') ||
        ocrLower.contains('magnesium') ||
        ocrLower.contains('entacyd');
    final hasSimethicone = ocrLower.contains('simethicone') ||
        genericName.toLowerCase().contains('simethicone');

    if (hasAntacidTerms && hasSimethicone) {
      resolvedGeneric = 'Aluminium Hydroxide + Magnesium Hydroxide + Simethicone';
      if (ocrLower.contains('entacyd') || resolvedBrand.toLowerCase().contains('entacyd')) {
        resolvedBrand = 'Entacyd Plus';
      } else if (resolvedBrand.toLowerCase() == 'simethicone') {
        resolvedBrand = 'Antacid Plus';
      }
    }

    // 2. Napa Extend / Ace Extend dosage-aware detection:
    if (resolvedBrand.toLowerCase() == 'napa' && (ocrLower.contains('665') || ocrLower.contains('extend'))) {
      resolvedBrand = 'Napa Extend';
    } else if (resolvedBrand.toLowerCase() == 'ace' && (ocrLower.contains('665') || ocrLower.contains('extend'))) {
      resolvedBrand = 'Ace Extend';
    }

    // 3. MaxOmega title case normalization:
    if (resolvedBrand.toLowerCase() == 'max omega' || resolvedBrand.toLowerCase() == 'maxomega') {
      resolvedBrand = 'MaxOmega';
    }

    final genericBn = BnTranslations.getGenericNameBn(resolvedGeneric);
    final category = BnTranslations.getCategory(resolvedGeneric, language: language);

    final rawDesc = _medicineDb?[resolvedGeneric.toLowerCase()] ?? '';

    final summaryBn = BnTranslations.translateSummary(rawDesc, resolvedGeneric);
    final summaryEn = BnTranslations.getEnglishSummary(rawDesc, resolvedGeneric);

    final summary = language == 'bn' ? summaryBn : summaryEn;
    final precaution = BnTranslations.getPrecaution(resolvedGeneric, language: language);
    final precautionEn = BnTranslations.getPrecaution(resolvedGeneric, language: 'en');

    return ScanResult(
      medicineName: resolvedBrand,
      brandName: resolvedBrand,
      genericName: resolvedGeneric,
      genericNameBn: genericBn,
      category: category,
      summary: summary,
      summaryEn: summaryEn,
      language: language,
      precaution: precaution,
      precautionEn: precautionEn,
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
      final precaution = BnTranslations.getPrecaution(title, language: language);
      final precautionEn = BnTranslations.getPrecaution(title, language: 'en');

      return ScanResult(
        medicineName: title,
        brandName: candidate,
        genericName: title,
        genericNameBn: genericBn,
        category: category,
        summary: language == 'bn' ? summaryBn : summaryEn,
        summaryEn: summaryEn,
        language: language,
        precaution: precaution,
        precautionEn: precautionEn,
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
