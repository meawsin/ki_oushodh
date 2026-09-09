// lib/core/constants/bn_translations.dart
//
// Plain Bangla translations for common medicine indications.
// Used to produce natural-sounding Bangla summaries instead of
// wrapping English medical terms in a Bangla sentence frame.

class MedicineProfile {
  final String bnName;
  final String categoryBn;
  final String categoryEn;
  final String summaryBn;
  final String summaryEn;
  final String? precautionBn;
  final String? precautionEn;

  const MedicineProfile({
    required this.bnName,
    required this.categoryBn,
    required this.categoryEn,
    required this.summaryBn,
    required this.summaryEn,
    this.precautionBn,
    this.precautionEn,
  });
}

class BnTranslations {
  BnTranslations._();

  /// Returns Bengali transliteration for smooth TTS pronunciation
  static String? getGenericNameBn(String genericName) {
    final lower = genericName.toLowerCase().trim();
    if (_profiles.containsKey(lower)) return _profiles[lower]!.bnName;
    for (final entry in _profiles.entries) {
      if (lower.startsWith('${entry.key} ') || lower.endsWith(' ${entry.key}') || lower.contains(' ${entry.key} ')) {
        return entry.value.bnName;
      }
    }
    for (final entry in _profiles.entries) {
      if (lower.contains(entry.key)) return entry.value.bnName;
    }
    return null;
  }

  static const Map<String, String> _brandNameToBn = {
    'napa extend': 'নাপা এক্সটেন্ড',
    'napa extra': 'নাপা এক্সট্রা',
    'napa': 'নাপা',
    'ace plus': 'এস প্লাস',
    'ace extend': 'এস এক্সটেন্ড',
    'ace': 'এস',
    'entacyd plus': 'এন্টাসিড প্লাস',
    'entacyd': 'এন্টাসিড',
    'antacid plus': 'এন্টাসিড প্লাস',
    'antacid': 'এন্টাসিড',
    'maxomega': 'ম্যাক্সওমেগা',
    'max omega': 'ম্যাক্সওমেগা',
    'omega fatty': 'ওমেগা-৩',
    'omega acid': 'ওমেগা-৩',
    'salmon fish': 'স্যামন মাছের তেল',
    'seclo': 'সেকলো',
    'sergel': 'সারজেল',
    'losectil': 'লোসেকটিল',
    'pantobex': 'প্যান্টোবেক্স',
    'monas': 'মোনাস',
    'alatrol': 'অ্যালাট্রোল',
    'fenofex': 'ফেনোফেক্স',
    'fexo': 'ফেক্সো',
    'ebatin': 'এবাটিন',
    'bextram gold': 'বেকস্ট্রাম গোল্ড',
    'silver': 'সিলভার',
    'e-cap': 'ই-ক্যাপ',
    'e cap': 'ই-ক্যাপ',
    'renova': 'রেনোভা',
    'fast': 'ফাস্ট',
    'tory': 'টোরি',
    'flacol': 'ফ্ল্যাকল',
    'disopan': 'ডাইসোপ্যান',
    'simethicone': 'সিমেথিকন',
    'paracetamol': 'প্যারাসিটামল',
  };

  /// Returns friendly Bengali pronunciation of medicine brand names
  static String getBrandNameBn(String brandName) {
    final lower = brandName.toLowerCase().trim();
    if (_brandNameToBn.containsKey(lower)) return _brandNameToBn[lower]!;
    for (final entry in _brandNameToBn.entries) {
      if (lower == entry.key || lower.startsWith('${entry.key} ')) {
        return entry.value;
      }
    }
    return brandName;
  }

  /// Returns clean therapeutic category in selected language
  static String getCategory(String genericName, {required String language}) {
    final lower = genericName.toLowerCase().trim();
    if (_profiles.containsKey(lower)) {
      return language == 'bn' ? _profiles[lower]!.categoryBn : _profiles[lower]!.categoryEn;
    }
    for (final entry in _profiles.entries) {
      if (lower.startsWith('${entry.key} ') || lower.endsWith(' ${entry.key}') || lower.contains(' ${entry.key} ')) {
        return language == 'bn' ? entry.value.categoryBn : entry.value.categoryEn;
      }
    }
    for (final entry in _profiles.entries) {
      if (lower.contains(entry.key)) {
        return language == 'bn' ? entry.value.categoryBn : entry.value.categoryEn;
      }
    }
    if (lower.contains('cef') || lower.contains('cillin') || lower.contains('mycin') || lower.contains('floxacin')) {
      return language == 'bn' ? 'অ্যান্টিবায়োটিক' : 'Antibiotic';
    }
    if (lower.contains('aluminium') || lower.contains('magnesium') || lower.contains('antacid')) {
      return language == 'bn' ? 'অ্যান্টাসিড ও বুকজ্বালা' : 'Antacid & Heartburn';
    }
    if (lower.contains('prazole') || lower.contains('tidine')) {
      return language == 'bn' ? 'গ্যাস্ট্রিক ও অ্যাসিডিটি' : 'Gastric & Acidity';
    }
    if (lower.contains('simethicone')) {
      return language == 'bn' ? 'পেটের গ্যাস ও পেট ফাঁপা' : 'Gas & Bloating Relief';
    }
    if (lower.contains('omega') || lower.contains('salmon')) {
      return language == 'bn' ? 'হার্ট ও স্বাস্থ্য সাপ্লিমেন্ট' : 'Heart & Health Supplement';
    }
    if (lower.contains('sartan') || lower.contains('olol') || lower.contains('dipine') || lower.contains('statin')) {
      return language == 'bn' ? 'উচ্চ রক্তচাপ ও হৃদরোগ' : 'Heart & Blood Pressure';
    }
    if (lower.contains('gliptin') || lower.contains('formin') || lower.contains('gliflozin')) {
      return language == 'bn' ? 'ডায়াবেটিস নিয়ন্ত্রণ' : 'Diabetes Care';
    }
    if (lower.contains('vitamin') || lower.contains('calcium') || lower.contains('zinc') || lower.contains('iron')) {
      return language == 'bn' ? 'ভিটামিন ও পুষ্টি' : 'Vitamins & Supplements';
    }
    return language == 'bn' ? 'প্রয়োজনীয় ওষুধ' : 'Essential Medicine';
  }

  /// Returns safety precaution and dosage advice in selected language
  static String? getPrecaution(String genericName, {required String language}) {
    final lower = genericName.toLowerCase().trim();
    if (_profiles.containsKey(lower)) {
      final prec = language == 'bn' ? _profiles[lower]!.precautionBn : _profiles[lower]!.precautionEn;
      if (prec != null && prec.isNotEmpty) return prec;
    }
    for (final entry in _profiles.entries) {
      if (lower.startsWith('${entry.key} ') || lower.endsWith(' ${entry.key}') || lower.contains(' ${entry.key} ')) {
        final prec = language == 'bn' ? entry.value.precautionBn : entry.value.precautionEn;
        if (prec != null && prec.isNotEmpty) return prec;
      }
    }
    for (final entry in _profiles.entries) {
      if (lower.contains(entry.key)) {
        final prec = language == 'bn' ? entry.value.precautionBn : entry.value.precautionEn;
        if (prec != null && prec.isNotEmpty) return prec;
      }
    }
    // Class-wide heuristics for unprofiled medicines
    if (lower.contains('cef') || lower.contains('cillin') || lower.contains('mycin') || lower.contains('floxacin')) {
      return language == 'bn'
          ? 'চিকিৎসকের নির্দেশিত অ্যান্টিবায়োটিকের সম্পূর্ণ কোর্স শেষ করুন।'
          : 'Complete the full course of this antibiotic as directed.';
    }
    if (lower.contains('fenac') || lower.contains('profen') || lower.contains('coxib')) {
      return language == 'bn'
          ? 'পেটের সমস্যা এড়াতে অবশ্যই ভরা পেটে সেবন করুন।'
          : 'Always take with or after food to prevent stomach irritation.';
    }
    if (lower.contains('sartan') || lower.contains('olol') || lower.contains('dipine')) {
      return language == 'bn'
          ? 'নিয়মিত একই সময়ে সেবন করুন। চিকিৎসকের পরামর্শ ছাড়া হঠাৎ বন্ধ করবেন না।'
          : 'Take regularly at the same time daily. Do not discontinue abruptly.';
    }
    if (lower.contains('omega') || lower.contains('salmon')) {
      return language == 'bn'
          ? 'খাবারের সাথে বা ভরা পেটে সেবন করুন।'
          : 'Take with or immediately after meals.';
    }
    if (lower.contains('simethicone')) {
      return language == 'bn'
          ? 'খাবারের পরে বা চিকিৎসকের পরামর্শ মতো সেবন করুন।'
          : 'Take after meals or at bedtime as needed.';
    }
    if (lower.contains('aluminium') && lower.contains('magnesium')) {
      return language == 'bn'
          ? 'চিবিয়ে খাবেন এবং অন্যান্য ওষুধের অন্তত ২ ঘণ্টা আগে বা পরে খাবেন।'
          : 'Chew thoroughly. Take 2 hours apart from other medications.';
    }
    return null;
  }

  /// Translates a raw indication or generic medicine into plain Bangla.
  static String translateSummary(String englishSummary, String genericName) {
    final genericLower = genericName.toLowerCase().trim();

    // 1. Direct profile match
    if (_profiles.containsKey(genericLower)) {
      return _profiles[genericLower]!.summaryBn;
    }
    for (final entry in _profiles.entries) {
      if (genericLower.startsWith('${entry.key} ') || genericLower.endsWith(' ${entry.key}') || genericLower.contains(' ${entry.key} ')) {
        return entry.value.summaryBn;
      }
    }
    for (final entry in _profiles.entries) {
      if (genericLower.contains(entry.key)) {
        return entry.value.summaryBn;
      }
    }

    // 2. Indication keyword match
    final lower = englishSummary.toLowerCase();
    for (final entry in _indicationMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    // 3. Fallback: NEVER inject raw English text into Bengali!
    final catBn = getCategory(genericName, language: 'bn');
    return 'এই ওষুধটি $catBn এর চিকিৎসায় নির্দিষ্ট নিয়মে ব্যবহার করা হয়।';
  }

  /// Returns a clean, user-friendly English summary
  static String getEnglishSummary(String englishSummary, String genericName) {
    final genericLower = genericName.toLowerCase();

    // 1. Direct profile match
    for (final entry in _profiles.entries) {
      if (genericLower.contains(entry.key)) {
        return entry.value.summaryEn;
      }
    }

    // 2. Cleaned raw summary
    final cleaned = cleanRawSummary(englishSummary);
    if (cleaned.isNotEmpty && !isCorruptedText(cleaned)) {
      if (RegExp(r'^(this|used|treats|helps)', caseSensitive: false).hasMatch(cleaned)) {
        return cleaned;
      }
      return 'Used for $cleaned';
    }

    return 'This medicine is used under the guidance of a physician or healthcare provider.';
  }

  /// Checks if a string contains corrupted encoding/mojibake characters
  static bool isCorruptedText(String text) {
    if (text.contains('\uFFFD') || text.contains('\u0000')) return true;
    final nonAsciiCount = text.codeUnits.where((c) => c > 127 && c < 0x0980).length;
    return nonAsciiCount > 5 && text.contains('?');
  }

  /// Cleans clinical boilerplate from summaries
  static String cleanRawSummary(String raw) {
    if (isCorruptedText(raw)) return '';

    String cleaned = raw
        .replaceAll(RegExp(r'^[^:]+is indicated (for|in)[:\s]*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^[^:]+is used (for|in)[:\s]*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^[^:]+indicated[:\s]*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^\s*[-•]\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.length > 220) {
      final sub = cleaned.substring(0, 220);
      final lastPeriod = sub.lastIndexOf('.');
      if (lastPeriod > 140) {
        cleaned = sub.substring(0, lastPeriod + 1);
      } else {
        final lastSpace = sub.lastIndexOf(' ');
        cleaned = lastSpace > 0 ? '${sub.substring(0, lastSpace)}...' : '$sub...';
      }
    }
    return cleaned;
  }

  // ---------------------------------------------------------------------------
  // Indication keyword → Bangla plain-language explanation
  // Ordered from most specific to most general
  // ---------------------------------------------------------------------------
  static const Map<String, String> _indicationMap = {
    // Pain & fever
    'fever': 'এই ওষুধটি জ্বর, মাথাব্যথা এবং ব্যথা কমাতে ব্যবহার করা হয়।',
    'headache': 'এই ওষুধটি মাথাব্যথা, জ্বর এবং হালকা ব্যথা কমাতে ব্যবহার করা হয়।',
    'pain relief': 'এই ওষুধটি ব্যথা ও জ্বর কমাতে ব্যবহার করা হয়।',
    'analgesic': 'এই ওষুধটি ব্যথানাশক হিসেবে কাজ করে এবং জ্বর কমায়।',

    // Stomach & acidity
    'flatulence': 'এই ওষুধটি পেটের অতিরিক্ত গ্যাস ও পেট ফাঁপা কমাতে ব্যবহার করা হয়।',
    'antiflatulent': 'এই ওষুধটি পেটের গ্যাস ও পেট ফাঁপা দূর করতে সাহায্য করে।',
    'windy colic': 'এই ওষুধটি পেটের গ্যাস ও ফাঁপা দূর করতে সাহায্য করে।',
    'hyperacidity': 'এই ওষুধটি পেটের অ্যাসিডিটি, বুকজ্বালা এবং গ্যাস কমাতে ব্যবহার করা হয়।',
    'heartburn': 'এই ওষুধটি বুকজ্বালা ও পেটের অ্যাসিডিটি কমাতে ব্যবহার করা হয়।',
    'gastric': 'এই ওষুধটি পেটের গ্যাস, অ্যাসিডিটি এবং বদহজম কমাতে ব্যবহার করা হয়।',
    'peptic ulcer': 'এই ওষুধটি পেটের আলসার ও অ্যাসিডিটি চিকিৎসায় ব্যবহার করা হয়।',
    'acid reflux': 'এই ওষুধটি পেটের অ্যাসিড উপরে উঠে আসা এবং বুকজ্বালা কমাতে ব্যবহার করা হয়।',
    'indigestion': 'এই ওষুধটি বদহজম ও পেটের অস্বস্তি কমাতে ব্যবহার করা হয়।',
    'nausea': 'এই ওষুধটি বমি বমি ভাব ও বমি কমাতে ব্যবহার করা হয়।',
    'diarrhea': 'এই ওষুধটি ডায়রিয়া ও পেটের সংক্রমণ চিকিৎসায় ব্যবহার করা হয়।',
    'constipation': 'এই ওষুধটি কোষ্ঠকাঠিন্য দূর করতে ব্যবহার করা হয়।',

    // Infections & antibiotics
    'bacterial infection': 'এই ওষুধটি ব্যাকটেরিয়া সংক্রমণের বিরুদ্ধে কাজ করে।',
    'antibiotic': 'এই ওষুধটি একটি অ্যান্টিবায়োটিক যা বিভিন্ন সংক্রমণ চিকিৎসায় ব্যবহার করা হয়।',
    'infection': 'এই ওষুধটি সংক্রমণ চিকিৎসায় ব্যবহার করা হয়।',
    'urinary tract': 'এই ওষুধটি মূত্রনালীর সংক্রমণ চিকিৎসায় ব্যবহার করা হয়।',
    'respiratory': 'এই ওষুধটি শ্বাসযন্ত্রের সংক্রমণ ও কাশি চিকিৎসায় ব্যবহার করা হয়।',
    'pneumonia': 'এই ওষুধটি নিউমোনিয়া ও ফুসফুসের সংক্রমণ চিকিৎসায় ব্যবহার করা হয়।',

    // Blood pressure, heart & cholesterol
    'triglyceride': 'এই ওষুধটি রক্তের ক্ষতিকর চর্বি কমাতে এবং হার্ট সুস্থ রাখতে সাহায্য করে।',
    'omega': 'এই ওষুধটি স্বাস্থ্যকর ওমেগা-৩ পুষ্টি জোগায় এবং হৃদযন্ত্র ভালো রাখে।',
    'salmon': 'এই ওষুধটি স্বাস্থ্যকর ওমেগা-৩ পুষ্টি জোগায় এবং হৃদযন্ত্র ভালো রাখে।',
    'high blood pressure': 'এই ওষুধটি উচ্চ রক্তচাপ নিয়ন্ত্রণে ব্যবহার করা হয়।',
    'hypertension': 'এই ওষুধটি উচ্চ রক্তচাপ কমাতে ব্যবহার করা হয়।',
    'blood pressure': 'এই ওষুধটি রক্তচাপ নিয়ন্ত্রণে ব্যবহার করা হয়।',
    'heart failure': 'এই ওষুধটি হৃদযন্ত্রের সমস্যা ও উচ্চ রক্তচাপ চিকিৎসায় ব্যবহার করা হয়।',
    'angina': 'এই ওষুধটি বুকের ব্যথা ও হৃদরোগের চিকিৎসায় ব্যবহার করা হয়।',
    'cholesterol': 'এই ওষুধটি রক্তের কোলেস্টেরল কমাতে এবং হৃদরোগের ঝুঁকি কমাতে ব্যবহার করা হয়।',

    // Diabetes
    'diabetes': 'এই ওষুধটি ডায়াবেটিস নিয়ন্ত্রণে রক্তের শর্করা কমাতে ব্যবহার করা হয়।',
    'blood sugar': 'এই ওষুধটি রক্তের শর্করা নিয়ন্ত্রণে ব্যবহার করা হয়।',
    'insulin': 'এই ইনসুলিন ডায়াবেটিস রোগীদের রক্তের শর্করা নিয়ন্ত্রণ করতে ব্যবহার করা হয়।',

    // Allergy & breathing
    'allergy': 'এই ওষুধটি অ্যালার্জির উপসর্গ যেমন সর্দি, চুলকানি ও হাঁচি কমাতে ব্যবহার করা হয়।',
    'allergic': 'এই ওষুধটি অ্যালার্জির প্রতিক্রিয়া কমাতে ব্যবহার করা হয়।',
    'antihistamine': 'এই ওষুধটি অ্যালার্জির ওষুধ — সর্দি, হাঁচি এবং চোখের চুলকানি কমায়।',
    'asthma': 'এই ওষুধটি হাঁপানি ও শ্বাসকষ্ট কমাতে ব্যবহার করা হয়।',
    'bronchitis': 'এই ওষুধটি শ্বাসনালীর প্রদাহ ও কাশি কমাতে ব্যবহার করা হয়।',
    'cough': 'এই ওষুধটি কাশি ও সর্দি কমাতে ব্যবহার করা হয়।',

    // Vitamins & supplements
    'vitamin deficiency': 'এই ওষুধটি ভিটামিনের অভাব পূরণ করতে ব্যবহার করা হয়।',
    'vitamin': 'এই ওষুধটি শরীরে প্রয়োজনীয় ভিটামিনের অভাব পূরণ করে।',
    'calcium': 'এই ওষুধটি হাড় ও দাঁত মজবুত রাখতে ক্যালসিয়ামের অভাব পূরণ করে।',
    'iron deficiency': 'এই ওষুধটি রক্তশূন্যতা ও আয়রনের অভাব পূরণ করতে ব্যবহার করা হয়।',
    'anaemia': 'এই ওষুধটি রক্তশূন্যতা দূর করতে ব্যবহার করা হয়।',
    'anemia': 'এই ওষুধটি রক্তশূন্যতা দূর করতে ব্যবহার করা হয়।',

    // Skin & fungal
    'fungal': 'এই ওষুধটি ছত্রাকজনিত চর্মরোগ চিকিৎসায় ব্যবহার করা হয়।',
    'skin infection': 'এই ওষুধটি চামড়ার সংক্রমণ চিকিৎসায় ব্যবহার করা হয়।',
    'ringworm': 'এই ওষুধটি দাদ ও ছত্রাকের সংক্রমণ সারাতে ব্যবহার করা হয়।',

    // Sleep & anxiety
    'anxiety': 'এই ওষুধটি উদ্বেগ ও মানসিক চাপ কমাতে ব্যবহার করা হয়।',
    'insomnia': 'এই ওষুধটি ঘুমের সমস্যা দূর করতে ব্যবহার করা হয়।',
    'seizure': 'এই ওষুধটি খিঁচুনি ও মৃগীরোগ নিয়ন্ত্রণে ব্যবহার করা হয়।',

    // General
    'anti-inflammatory': 'এই ওষুধটি প্রদাহ ও ব্যথা কমাতে ব্যবহার করা হয়।',
    'inflammation': 'এই ওষুধটি শরীরের প্রদাহ ও ফোলাভাব কমাতে ব্যবহার করা হয়।',
    'arthritis': 'এই ওষুধটি গাঁটের ব্যথা ও আর্থ্রাইটিস চিকিৎসায় ব্যবহার করা হয়।',
    'muscle pain': 'এই ওষুধটি মাংসপেশির ব্যথা কমাতে ব্যবহার করা হয়।',
    'toothache': 'এই ওষুধটি দাঁতের ব্যথা ও জ্বর কমাতে ব্যবহার করা হয়।',
  };

  // ---------------------------------------------------------------------------
  // Top 70+ Generic Medicine Profiles in Bangladesh
  // ---------------------------------------------------------------------------
  static const Map<String, MedicineProfile> _profiles = {
    // --- Pain, Fever & Inflammation ---
    'paracetamol': MedicineProfile(
      bnName: 'প্যারাসিটামল',
      categoryBn: 'জ্বর ও ব্যথানাশক',
      categoryEn: 'Pain Relief & Fever',
      summaryBn: 'এই ওষুধটি জ্বর, মাথাব্যথা এবং সাধারণ শরীর ব্যথা কমাতে ব্যবহার করা হয়।',
      summaryEn: 'Used for fever, headache, body aches, and pain relief.',
      precautionBn: '২৪ ঘণ্টায় ৪০০০ মিলিগ্রাম বা ৮টির বেশি ট্যাবলেট খাবেন না। অতিরিক্ত সেবনে লিভারের ক্ষতি হতে পারে।',
      precautionEn: 'Do not exceed 4,000 mg (8 tablets) in 24 hours. Overdose damages the liver.',
    ),
    'ibuprofen': MedicineProfile(
      bnName: 'আইবুপ্রোফেন',
      categoryBn: 'ব্যথানাশক ও প্রদাহনাশক',
      categoryEn: 'Pain & Anti-inflammatory',
      summaryBn: 'এই ওষুধটি তীব্র ব্যথা, জ্বর এবং ফোলাভাব বা প্রদাহ কমাতে ব্যবহার করা হয়।',
      summaryEn: 'Used for pain, fever, and reducing swelling and inflammation.',
      precautionBn: 'পেটের আলসার এড়াতে অবশ্যই ভরা পেটে খাবেন। কিডনি বা হার্টের জটিলতা থাকলে চিকিৎসকের পরামর্শ নিন।',
      precautionEn: 'Always take with food to protect your stomach. Consult a doctor if you have kidney or heart issues.',
    ),
    'naproxen': MedicineProfile(
      bnName: 'ন্যাপ্রোক্সেন',
      categoryBn: 'বাতব্যথা ও ব্যথানাশক',
      categoryEn: 'Arthritis & Pain Relief',
      summaryBn: 'এই ওষুধটি বাতব্যথা, গাঁটের ব্যথা ও দীর্ঘস্থায়ী ব্যথা কমাতে ব্যবহার করা হয়।',
      summaryEn: 'Used for arthritis, joint inflammation, and chronic body pain.',
      precautionBn: 'অবশ্যই ভরা পেটে খাবেন। গ্যাস্ট্রিক সুরক্ষার জন্য সাধারণত গ্যাস্ট্রিকের ওষুধের সাথে নির্দেশিত হয়।',
      precautionEn: 'Take with or after meals. Often prescribed with an acid suppressor to prevent ulceration.',
    ),
    'diclofenac': MedicineProfile(
      bnName: 'ডাইক্লোফেনাক',
      categoryBn: 'তীব্র ব্যথানাশক',
      categoryEn: 'Severe Pain Relief',
      summaryBn: 'এই ওষুধটি তীব্র বাতব্যথা, হাড় ও মাংসপেশির ব্যথা কমাতে ব্যবহার করা হয়।',
      summaryEn: 'Used for severe joint pain, back pain, and musculoskeletal pain.',
      precautionBn: 'কখনোই খালি পেটে সেবন করবেন না। দীর্ঘমেয়াদে চিকিৎসকের প্রেসক্রিপশন ছাড়া খাবেন না।',
      precautionEn: 'Never take on an empty stomach. Avoid unmonitored long-term usage.',
    ),
    'aceclofenac': MedicineProfile(
      bnName: 'অ্যাসিফেনাক',
      categoryBn: 'বাতব্যথা ও ব্যথানাশক',
      categoryEn: 'Joint Pain & Arthritis',
      summaryBn: 'এই ওষুধটি বাতব্যথা, হাড়ের ক্ষয়জনিত ব্যথা ও প্রদাহ কমাতে ব্যবহার করা হয়।',
      summaryEn: 'Used for osteoarthritis, rheumatoid arthritis, and joint pain.',
      precautionBn: 'গ্যাস্ট্রিক আলসারের ঝুঁকি কমাতে অবশ্যই ভরা পেটে সেবন করবেন।',
      precautionEn: 'Always take after food to minimize gastrointestinal discomfort.',
    ),
    'ketorolac': MedicineProfile(
      bnName: 'কিটোরোলাক',
      categoryBn: 'তীব্র ব্যথানাশক',
      categoryEn: 'Acute Pain Relief',
      summaryBn: 'এই ওষুধটি অপারেশনের পরবর্তী তীব্র ব্যথা বা আঘাতের ব্যথা দ্রুত কমাতে ব্যবহার করা হয়।',
      summaryEn: 'Used for short-term relief of moderate to severe acute pain.',
      precautionBn: 'এটি সর্বোচ্চ ৫ দিনের বেশি ব্যবহার করা উচিত নয়। কিডনির ওপর প্রভাব ফেলতে পারে।',
      precautionEn: 'Do not use for more than 5 consecutive days due to risk of kidney toxicity and bleeding.',
    ),
    'etoricoxib': MedicineProfile(
      bnName: 'ইটোরিকক্সিব',
      categoryBn: 'তীব্র বাতব্যথা',
      categoryEn: 'Gout & Joint Pain',
      summaryBn: 'এই ওষুধটি গেঁটেবাত এবং অস্থিসন্ধির তীব্র ব্যথা ও ফোলা কমাতে ব্যবহার করা হয়।',
      summaryEn: 'Used for gout flare-ups, osteoarthritis, and acute joint pain.',
      precautionBn: 'উচ্চ রক্তচাপ থাকলে নিয়মিত রক্তচাপ পরীক্ষা করুন।',
      precautionEn: 'Monitor blood pressure regularly if you have hypertension.',
    ),
    'tramadol': MedicineProfile(
      bnName: 'ট্রামাডল',
      categoryBn: 'শক্তিশালী ব্যথানাশক',
      categoryEn: 'Moderate to Severe Pain',
      summaryBn: 'এই ওষুধটি মধ্যম থেকে তীব্র ব্যথা কমাতে নির্দেশিত।',
      summaryEn: 'Used for the treatment of moderate to severe acute pain.',
      precautionBn: 'ঘুম বা মাথা ঘোরার সমস্যা হতে পারে। চিকিৎসকের নির্দেশনা ছাড়া অতিরিক্ত সেবন করবেন না।',
      precautionEn: 'May cause drowsiness and dizziness. Use strictly as prescribed by a licensed physician.',
    ),

    // --- Gastric, Acidity & Ulcer ---
    'omeprazole': MedicineProfile(
      bnName: 'ওমিপ্রাজল',
      categoryBn: 'গ্যাস্ট্রিক ও অ্যাসিডিটি',
      categoryEn: 'Gastric & Acidity',
      summaryBn: 'এই ওষুধটি পেটের অতিরিক্ত অ্যাসিড কমিয়ে বুকজ্বালা, গ্যাস ও আলসার নিরাময় করে।',
      summaryEn: 'Reduces stomach acid to relieve heartburn, gas, and peptic ulcers.',
      precautionBn: 'খাবারের ৩০ মিনিট আগে খালি পেটে সেবন করা সবচেয়ে বেশি কার্যকর।',
      precautionEn: 'Take on an empty stomach at least 30 minutes before meals for maximum efficacy.',
    ),
    'esomeprazole': MedicineProfile(
      bnName: 'ইসোমিপ্রাজল',
      categoryBn: 'গ্যাস্ট্রিক ও বুকজ্বালা',
      categoryEn: 'Heartburn & Acid Reflux',
      summaryBn: 'এই ওষুধটি পেটের অতিরিক্ত অ্যাসিড কমায় এবং বুকজ্বালা ও গ্যাস্ট্রিক আলসার প্রতিরোধ করে।',
      summaryEn: 'Decreases stomach acid for relief from heartburn, GERD, and ulcers.',
      precautionBn: 'খাবারের ৩০ মিনিট আগে খালি পেটে সেবন করা সবচেয়ে বেশি কার্যকর।',
      precautionEn: 'Take on an empty stomach at least 30 minutes before breakfast or meals.',
    ),
    'pantoprazole': MedicineProfile(
      bnName: 'প্যান্টোপ্রাজল',
      categoryBn: 'গ্যাস্ট্রিক ও আলসার',
      categoryEn: 'Gastric & Acid Control',
      summaryBn: 'এই ওষুধটি পেটের অ্যাসিড উৎপাদন নিয়ন্ত্রণ করে গ্যাস্ট্রিক ও খাদ্যনালীর প্রদাহ কমায়।',
      summaryEn: 'Used for stomach ulcers, gastroesophageal reflux, and gastric hyperacidity.',
      precautionBn: 'খাবারের ৩০ মিনিট আগে খালি পেটে সেবন করুন। ট্যাবলেট চিবিয়ে খাবেন না।',
      precautionEn: 'Take 30 minutes before food. Swallow whole; do not chew or crush.',
    ),
    'rabeprazole': MedicineProfile(
      bnName: 'রাবিপ্রাজল',
      categoryBn: 'গ্যাস্ট্রিক ও অ্যাসিড নিয়ন্ত্রণ',
      categoryEn: 'Rapid Acid Relief',
      summaryBn: 'এই ওষুধটি পেটের গ্যাস, বুকজ্বালা এবং অ্যাসিড রিফ্লাক্স নিয়ন্ত্রণে দ্রুত কাজ করে।',
      summaryEn: 'Provides fast acid reduction for treating ulcers and acid indigestion.',
      precautionBn: 'খাবারের আগে খালি পেটে সেবন করুন।',
      precautionEn: 'Take on an empty stomach before a meal.',
    ),
    'dexlansoprazole': MedicineProfile(
      bnName: 'ডেক্সল্যান্সোপ্রাজল',
      categoryBn: 'দীর্ঘস্থায়ী অ্যাসিড নিয়ন্ত্রণ',
      categoryEn: '24-Hour Acid Control',
      summaryBn: 'এই ওষুধটি দীর্ঘক্ষণ পেটের অ্যাসিড কমিয়ে বুকজ্বালা ও খাদ্যনালীর ক্ষত সারাতে সাহায্য করে।',
      summaryEn: 'Provides dual-release 24-hour acid control for erosive heartburn and GERD.',
      precautionBn: 'খাবারের সাথে বা খাবার ছাড়া যেকোনো সময় নেওয়া যায়। চিবিয়ে খাবেন না।',
      precautionEn: 'Can be taken with or without food. Swallow capsule whole.',
    ),
    'famotidine': MedicineProfile(
      bnName: 'ফ্যামোটিডিন',
      categoryBn: 'অ্যাসিডিটি ও বুকজ্বালা',
      categoryEn: 'Heartburn & Indigestion',
      summaryBn: 'এই ওষুধটি পেটের অ্যাসিড কমিয়ে বদহজম ও বুকজ্বালা কমাতে ব্যবহার করা হয়।',
      summaryEn: 'Used to treat and prevent heartburn, sour stomach, and acid indigestion.',
      precautionBn: 'রাতে শোবার আগে বা লক্ষণ দেখা দিলে সেবন করুন।',
      precautionEn: 'Often taken at bedtime or 15–60 minutes before acid-triggering meals.',
    ),
    'ranitidine': MedicineProfile(
      bnName: 'র্যানিটিডিন',
      categoryBn: 'গ্যাস্ট্রিক ও আলসার',
      categoryEn: 'Gastric & Ulcer Relief',
      summaryBn: 'এই ওষুধটি পেটের অতিরিক্ত অ্যাসিড কমাতে ও আলসার নিরাময়ে ব্যবহার করা হয়।',
      summaryEn: 'Used for reducing stomach acid and promoting healing of peptic ulcers.',
      precautionBn: 'খাবারের আগে বা খাবারের সাথে সেবন করা যায়।',
      precautionEn: 'Can be taken with or without food.',
    ),
    'aluminium hydroxide': MedicineProfile(
      bnName: 'অ্যালুমিনিয়াম হাইড্রক্সাইড (অ্যান্টাসিড)',
      categoryBn: 'অ্যান্টাসিড ও বুকজ্বালা',
      categoryEn: 'Antacid & Gas Relief',
      summaryBn: 'এই অ্যান্টাসিড পেটের অ্যাসিড প্রশমিত করে দ্রুত বুকজ্বালা ও গ্যাস দূর করে।',
      summaryEn: 'Neutralizes excess stomach acid for fast relief of heartburn and indigestion.',
      precautionBn: 'অন্যান্য ওষুধ সেবনের অন্তত ২ ঘণ্টার ব্যবধান রাখুন যাতে শোষণে বাধা না ঘটে।',
      precautionEn: 'Take 2 hours apart from other oral medications to avoid reducing their absorption.',
    ),
    'magnesium hydroxide': MedicineProfile(
      bnName: 'ম্যাগনেসিয়াম হাইড্রক্সাইড',
      categoryBn: 'অ্যান্টাসিড ও কোষ্ঠকাঠিন্য',
      categoryEn: 'Antacid & Laxative',
      summaryBn: 'এই অ্যান্টাসিড পেটের অম্লতা কমায় এবং কোষ্ঠকাঠিন্য দূর করতে সাহায্য করে।',
      summaryEn: 'Relieves indigestion and sour stomach, and relieves occasional constipation.',
      precautionBn: 'প্রচুর পানি পান করুন। অতিরিক্ত মাত্রায় পাতলা পায়খানা হতে পারে।',
      precautionEn: 'Drink adequate fluids. May cause laxative effects in higher doses.',
    ),
    'sodium alginate': MedicineProfile(
      bnName: 'সোডিয়াম অ্যালজিনেট',
      categoryBn: 'রিফ্লাক্স ও বুকজ্বালা রোধক',
      categoryEn: 'Acid Reflux Barrier',
      summaryBn: 'এই ওষুধটি পেটের অ্যাসিড উপরে উঠে বুকজ্বালা করা প্রতিরোধে একটি সুরক্ষামূলক স্তর তৈরি করে।',
      summaryEn: 'Forms a protective barrier over stomach contents to prevent acid reflux.',
      precautionBn: 'খাবারের পর এবং শোবার আগে সেবন করা সবচেয়ে কার্যকর।',
      precautionEn: 'Most effective when taken after meals and at bedtime.',
    ),

    'aluminium hydroxide + magnesium hydroxide + simethicone': MedicineProfile(
      bnName: 'অ্যান্টাসিড প্লাস',
      categoryBn: 'গ্যাস্ট্রিক ও বুকজ্বালা',
      categoryEn: 'Antacid, Heartburn & Gas Relief',
      summaryBn: 'এই অ্যান্টাসিড বুকজ্বালা, গ্যাস্ট্রিক এবং পেটের অতিরিক্ত গ্যাস দ্রুত দূর করে।',
      summaryEn: 'Neutralizes excess stomach acid and relieves gas, bloating, and heartburn.',
      precautionBn: 'ট্যাবলেট চিবিয়ে খাবেন এবং অন্যান্য ওষুধের অন্তত ২ ঘণ্টা আগে বা পরে খাবেন।',
      precautionEn: 'Chew tablets thoroughly. Take 2 hours apart from other medications.',
    ),
    'simethicone': MedicineProfile(
      bnName: 'সিমেথিকন (গ্যাসের ওষুধ)',
      categoryBn: 'পেটের গ্যাস ও পেট ফাঁপা',
      categoryEn: 'Gas & Bloating Relief',
      summaryBn: 'এই ওষুধটি পেটের অতিরিক্ত গ্যাস, পেট ফাঁপা এবং অস্বস্তি দূর করতে সাহায্য করে।',
      summaryEn: 'Relieves uncomfortable gas, abdominal bloating, and pressure in the stomach.',
      precautionBn: 'খাবারের পরে বা চিকিৎসকের পরামর্শ মতো সেবন করুন।',
      precautionEn: 'Take after meals or at bedtime as needed.',
    ),

    // --- Antibiotics & Antibacterials ---
    'amoxicillin': MedicineProfile(
      bnName: 'অ্যামোক্সিসিলিন',
      categoryBn: 'অ্যান্টিবায়োটিক',
      categoryEn: 'Antibacterial Antibiotic',
      summaryBn: 'এই অ্যান্টিবায়োটিকটি কান, নাক, গলা, দাঁত ও ফুসফুসের ব্যাকটেরিয়া সংক্রমণে ব্যবহার করা হয়।',
      summaryEn: 'Broad-spectrum antibiotic used for throat, ear, chest, and dental infections.',
      precautionBn: 'পেনিসিলিনে অ্যালার্জি থাকলে চিকিৎসকের পরামর্শ নিন। পূর্ণ কোর্স শেষ করুন।',
      precautionEn: 'Do not take if allergic to penicillin. Complete the full prescribed course.',
    ),
    'azithromycin': MedicineProfile(
      bnName: 'অ্যাজিথ্রোমাইসিন',
      categoryBn: 'অ্যান্টিবায়োটিক',
      categoryEn: 'Macrolide Antibiotic',
      summaryBn: 'এই অ্যান্টিবায়োটিকটি কাশি, গলাব্যথা, নিউমোনিয়া ও শ্বাসযন্ত্রের ব্যাকটেরিয়া সংক্রমণে ব্যবহার করা হয়।',
      summaryEn: 'Antibiotic for respiratory infections, tonsillitis, bronchitis, and pneumonia.',
      precautionBn: 'খাবারের ১ ঘণ্টা আগে বা ২ ঘণ্টা পরে সেবন করুন। পুরো ৩ বা ৫ দিনের কোর্স সম্পন্ন করুন।',
      precautionEn: 'Take 1 hour before or 2 hours after meals. Complete the entire 3 or 5-day course.',
    ),
    'ciprofloxacin': MedicineProfile(
      bnName: 'সিপ্রোফ্লক্সাসিন',
      categoryBn: 'অ্যান্টিবায়োটিক',
      categoryEn: 'Broad-Spectrum Antibiotic',
      summaryBn: 'এই অ্যান্টিবায়োটিকটি মূত্রনালী, পেটের সংক্রমণ, টাইফয়েড ও ডায়রিয়ার চিকিৎসায় ব্যবহৃত হয়।',
      summaryEn: 'Fluoroquinolone antibiotic for urinary tract, typhoid, and gut infections.',
      precautionBn: 'প্রচুর পানি পান করুন। দুধ বা অ্যান্টাসিডের সাথে একই সময়ে খাবেন না (কমপক্ষে ২ ঘণ্টার ব্যবধান রাখুন)।',
      precautionEn: 'Drink plenty of water. Avoid taking simultaneously with dairy products or antacids.',
    ),
    'levofloxacin': MedicineProfile(
      bnName: 'লেভোফ্লক্সাসিন',
      categoryBn: 'অ্যান্টিবায়োটিক',
      categoryEn: 'Respiratory Antibiotic',
      summaryBn: 'এই অ্যান্টিবায়োটিকটি সাইনাস, ফুসফুসের সংক্রমণ ও মূত্রনালীর সংক্রমণে ব্যবহৃত হয়।',
      summaryEn: 'Used for respiratory tract infections, severe sinusitis, and urinary infections.',
    ),
    'cefixime': MedicineProfile(
      bnName: 'সেফিক্সিম',
      categoryBn: 'অ্যান্টিবায়োটিক',
      categoryEn: 'Cephalosporin Antibiotic',
      summaryBn: 'এই অ্যান্টিবায়োটিকটি টাইফয়েড জ্বর, কান ও গলার সংক্রমণ এবং মূত্রনালীর সংক্রমণে ব্যবহৃত হয়।',
      summaryEn: 'Used for typhoid fever, urinary tract infections, and ear/throat infections.',
    ),
    'cefuroxime': MedicineProfile(
      bnName: 'সেফুরোক্সিম',
      categoryBn: 'অ্যান্টিবায়োটিক',
      categoryEn: 'Cephalosporin Antibiotic',
      summaryBn: 'এই অ্যান্টিবায়োটিকটি ফুসফুস, গলা, সাইনাস ও ত্বকের ব্যাকটেরিয়া চিকিৎসায় ব্যবহৃত হয়।',
      summaryEn: 'Used for respiratory infections, sinus infections, and skin infections.',
    ),
    'ceftriaxone': MedicineProfile(
      bnName: 'সেফট্রিয়াক্সন',
      categoryBn: 'ইনজেকশন অ্যান্টিবায়োটিক',
      categoryEn: 'Injectable Antibiotic',
      summaryBn: 'এই ইনজেকশন অ্যান্টিবায়োটিকটি নিউমোনিয়া, টাইফয়েড ও রক্তের গুরুতর সংক্রমণ চিকিৎসায় ব্যবহার করা হয়।',
      summaryEn: 'Broad-spectrum injectable antibiotic for severe infections and typhoid.',
    ),
    'cephradine': MedicineProfile(
      bnName: 'সেফ্রাডিন',
      categoryBn: 'অ্যান্টিবায়োটিক',
      categoryEn: 'Antibiotic',
      summaryBn: 'এই অ্যান্টিবায়োটিকটি প্রস্রাবের ইনফেকশন, শ্বাসযন্ত্র ও ত্বকের ব্যাকটেরিয়াল সংক্রমণে ব্যবহৃত হয়।',
      summaryEn: 'Used for skin, urinary tract, and respiratory bacterial infections.',
    ),
    'flucloxacillin': MedicineProfile(
      bnName: 'ফ্লুক্লক্সাসিন',
      categoryBn: 'ত্বক ও ঘা-এর অ্যান্টিবায়োটিক',
      categoryEn: 'Skin & Wound Antibiotic',
      summaryBn: 'এই অ্যান্টিবায়োটিকটি ফোঁড়া, ত্বকের ঘা, ক্ষত এবং সেলুলাইটিস চিকিৎসায় ব্যবহৃত হয়।',
      summaryEn: 'Targeted antibiotic for skin infections, boils, wounds, and cellulitis.',
    ),
    'cloxacillin': MedicineProfile(
      bnName: 'ক্লক্সাসিলিন',
      categoryBn: 'ত্বক ও ঘা-এর অ্যান্টিবায়োটিক',
      categoryEn: 'Skin & Wound Antibiotic',
      summaryBn: 'এই অ্যান্টিবায়োটিকটি ত্বকের ফোঁড়া, ক্ষতের সংক্রমণ ও ব্যাকটেরিয়াজনিত প্রদাহ নিরাময়ে ব্যবহৃত হয়।',
      summaryEn: 'Antibiotic used for bacterial infections of the skin, boils, and wounds.',
    ),
    'metronidazole': MedicineProfile(
      bnName: 'মেট্রোনিডাজল',
      categoryBn: 'আমাশয় ও পেটের সংক্রমণ',
      categoryEn: 'Antiprotozoal & Gut Infection',
      summaryBn: 'এই ওষুধটি আমাশয়, পেটের পরজীবী সংক্রমণ এবং দাঁতের মাড়ির ইনফেকশনে ব্যবহার করা হয়।',
      summaryEn: 'Used for amoebiasis, giardiasis, dental infections, and gut parasites.',
    ),
    'doxycycline': MedicineProfile(
      bnName: 'ডক্সিসাইক্লিন',
      categoryBn: 'অ্যান্টিবায়োটিক',
      categoryEn: 'Tetracycline Antibiotic',
      summaryBn: 'এই অ্যান্টিবায়োটিকটি ব্রঙ্কাইটিস, মূত্রনালীর সংক্রমণ ও ত্বকের ব্রণ চিকিৎসায় ব্যবহার করা হয়।',
      summaryEn: 'Used for respiratory chest infections, acne, and bacterial infections.',
    ),

    // --- Allergy, Cold, Cough & Respiratory ---
    'cetirizine': MedicineProfile(
      bnName: 'সেটিরিজিন',
      categoryBn: 'অ্যালার্জি ও সর্দি',
      categoryEn: 'Antihistamine & Allergy',
      summaryBn: 'এই ওষুধটি অ্যালার্জিজনিত সর্দি, হাঁচি, নাক দিয়ে পানি পড়া এবং চুলকানি কমাতে ব্যবহার করা হয়।',
      summaryEn: 'Antihistamine that relieves sneezing, runny nose, itchy eyes, and hives.',
    ),
    'levocetirizine': MedicineProfile(
      bnName: 'লেভোসেটিরিজিন',
      categoryBn: 'অ্যালার্জি ও চুলকানি',
      categoryEn: 'Allergy & Itch Relief',
      summaryBn: 'এই ওষুধটি অ্যালার্জির কারণে চোখ-নাক চুলকানো, হাঁচি এবং ত্বকের ফুসকুড়ি দ্রুত কমায়।',
      summaryEn: 'Fast-acting antihistamine for seasonal allergic rhinitis and skin rashes.',
    ),
    'fexofenadine': MedicineProfile(
      bnName: 'ফেক্সোফেনাডিন',
      categoryBn: 'অ্যালার্জি ও সর্দি',
      categoryEn: 'Non-Drowsy Allergy Relief',
      summaryBn: 'এই ওষুধটি ঘুম না এনে অ্যালার্জিজনিত সর্দি, হাঁচি ও চুলকানি নিয়ন্ত্রণে রাখে।',
      summaryEn: 'Non-drowsy antihistamine for allergic rhinitis, sneezing, and skin itching.',
    ),
    'bilastine': MedicineProfile(
      bnName: 'বিলাস্টিন',
      categoryBn: 'অ্যালার্জি ও চুলকানি',
      categoryEn: 'Modern Allergy Relief',
      summaryBn: 'এই আধুনিক ওষুধটি তন্দ্রাচ্ছন্নতা তৈরি না করে অ্যালার্জিক সর্দি ও ত্বকের চুলকানি দূর করে।',
      summaryEn: 'Next-generation non-sedating antihistamine for allergic rhinitis and hives.',
    ),
    'rupatadine': MedicineProfile(
      bnName: 'রূপাটাডিন',
      categoryBn: 'অ্যালার্জি ও চুলকানি',
      categoryEn: 'Allergy & Urticaria',
      summaryBn: 'এই ওষুধটি দীর্ঘস্থায়ী চুলকানি ও অ্যালার্জিক সর্দি চিকিৎসায় কার্যকর।',
      summaryEn: 'Dual-action antihistamine for allergic rhinitis and chronic urticaria.',
    ),
    'loratadine': MedicineProfile(
      bnName: 'লোরাটাডিন',
      categoryBn: 'অ্যালার্জি ও হাঁচি',
      categoryEn: 'Allergy Relief',
      summaryBn: 'এই ওষুধটি সর্দি, হাঁচি ও চোখের চুলকানি কমাতে ব্যবহার করা হয়।',
      summaryEn: 'Antihistamine for relief of hay fever, sneezing, and skin itching.',
    ),
    'desloratadine': MedicineProfile(
      bnName: 'ডেসলোরাটাডিন',
      categoryBn: 'অ্যালার্জি নিয়ন্ত্রণ',
      categoryEn: 'Allergy Control',
      summaryBn: 'এই ওষুধটি সারা দিনের অ্যালার্জি উপসর্গ ও চুলকানি নিয়ন্ত্রণে সাহায্য করে।',
      summaryEn: 'Long-acting antihistamine for continuous relief of nasal allergic symptoms.',
    ),
    'montelukast': MedicineProfile(
      bnName: 'মন্টেলুকাস্ট',
      categoryBn: 'হাঁপানি ও অ্যালার্জি নিয়ন্ত্রণ',
      categoryEn: 'Asthma & Allergy Control',
      summaryBn: 'এই ওষুধটি শ্বাসনালীর ফোলাভাব কমিয়ে হাঁপানি, শ্বাসকষ্ট ও দীর্ঘস্থায়ী সর্দি প্রতিরোধ করে।',
      summaryEn: 'Prevents asthma attacks and relieves seasonal nasal allergies.',
    ),
    'salbutamol': MedicineProfile(
      bnName: 'সালবিউটামল',
      categoryBn: 'শ্বাসকষ্ট উপশমকারী',
      categoryEn: 'Bronchodilator (Asthma)',
      summaryBn: 'এই ব্রঙ্কোডাইলেটর শ্বাসনালী প্রসারিত করে দ্রুত শ্বাসকষ্ট ও হাঁপানির টান কমায়।',
      summaryEn: 'Fast-acting bronchodilator for rapid relief of asthma attacks and wheezing.',
    ),
    'levosalbutamol': MedicineProfile(
      bnName: 'লেভোস্যালবিউটামল',
      categoryBn: 'শ্বাসকষ্ট উপশমকারী',
      categoryEn: 'Asthma Bronchodilator',
      summaryBn: 'এই ওষুধটি অল্প কাঁপুনি সৃষ্টি করে হাঁপানির শ্বাসকষ্ট দূর করতে শ্বাসনালী উন্মুক্ত করে।',
      summaryEn: 'Bronchodilator that opens airways for asthma relief with fewer heart palpitations.',
    ),
    'doxophylline': MedicineProfile(
      bnName: 'ডক্সোফিলিন',
      categoryBn: 'হাঁপানি ও ব্রঙ্কাইটিস',
      categoryEn: 'COPD & Asthma Care',
      summaryBn: 'এই ওষুধটি ক্রনিক ব্রঙ্কাইটিস ও দীর্ঘমেয়াদী হাঁপানিতে শ্বাসপ্রশ্বাস সহজ করে।',
      summaryEn: 'Used to treat chronic obstructive pulmonary disease (COPD) and asthma.',
    ),
    'ambroxol': MedicineProfile(
      bnName: 'অ্যামব্রোক্সল',
      categoryBn: 'কফ পাতলাকারী',
      categoryEn: 'Mucolytic Cough Syrup',
      summaryBn: 'এই ওষুধটি বুকের জমাট বাঁধা ঘন কফ পাতলা করে কাশির সাথে বের করে দেয়।',
      summaryEn: 'Mucolytic agent that thins and loosens thick chest phlegm for easy cough-out.',
    ),
    'bromhexine': MedicineProfile(
      bnName: 'ব্রোমহেক্সিন',
      categoryBn: 'কফ পাতলাকারী',
      categoryEn: 'Mucus Relief',
      summaryBn: 'এই ওষুধটি কাশির সাথে ঘন কফ তরল করতে সাহায্য করে।',
      summaryEn: 'Assists in clearing thick mucus secretions in respiratory tract disorders.',
    ),
    'dextromethorphan': MedicineProfile(
      bnName: 'ডেক্সট্রোমেথরফান',
      categoryBn: 'শুষ্ক কাশির ওষুধ',
      categoryEn: 'Dry Cough Suppressant',
      summaryBn: 'এই ওষুধটি শুকনো খুকখুকে কাশি দমন করতে ব্যবহার করা হয়।',
      summaryEn: 'Cough suppressant used for temporary relief of dry, irritating cough.',
    ),

    // --- Cardiovascular & Blood Pressure ---
    'amlodipine': MedicineProfile(
      bnName: 'অ্যামলোডিপাইন',
      categoryBn: 'উচ্চ রক্তচাপ নিয়ন্ত্রণ',
      categoryEn: 'High Blood Pressure (BP)',
      summaryBn: 'এই ওষুধটি রক্তনালী শিথিল করে উচ্চ রক্তচাপ নিয়ন্ত্রণে রাখে এবং বুকের ব্যথা প্রতিরোধ করে।',
      summaryEn: 'Lowers high blood pressure and prevents heart-related chest pain (angina).',
    ),
    'losartan': MedicineProfile(
      bnName: 'লোসার্টান',
      categoryBn: 'রক্তচাপ ও কিডনি সুরক্ষা',
      categoryEn: 'Blood Pressure & Kidney',
      summaryBn: 'এই ওষুধটি উচ্চ রক্তচাপ কমায় এবং কিডনির সুরক্ষা প্রদান করে।',
      summaryEn: 'Lowers high blood pressure and helps protect kidneys in diabetic patients.',
    ),
    'telmisartan': MedicineProfile(
      bnName: 'টেলমিসার্টান',
      categoryBn: 'রক্তচাপ ও হৃদযন্ত্র সুরক্ষা',
      categoryEn: 'Blood Pressure & Heart',
      summaryBn: 'এই ওষুধটি উচ্চ রক্তচাপ কমায় এবং হার্ট অ্যাটাক ও স্ট্রোকের ঝুঁকি হ্রাস করে।',
      summaryEn: 'Long-acting antihypertensive that reduces cardiovascular and stroke risk.',
    ),
    'bisoprolol': MedicineProfile(
      bnName: 'বিসোপ্রোলল',
      categoryBn: 'হৃদস্পন্দন ও রক্তচাপ নিয়ন্ত্রণ',
      categoryEn: 'Beta-Blocker (Heart Rate)',
      summaryBn: 'এই বিটা-ব্লকার হৃদস্পন্দন ও উচ্চ রক্তচাপ নিয়ন্ত্রণ করে হার্ট ভালো রাখে।',
      summaryEn: 'Slows the heart rate and relaxes blood vessels to treat hypertension.',
    ),
    'atenolol': MedicineProfile(
      bnName: 'অ্যাটেনোলল',
      categoryBn: 'রক্তচাপ ও বুকের ব্যথা',
      categoryEn: 'Beta-Blocker for BP',
      summaryBn: 'এই ওষুধটি উচ্চ রক্তচাপ ও অনিয়মিত হৃদস্পন্দন নিয়ন্ত্রণে কাজ করে।',
      summaryEn: 'Used for managing hypertension and preventing angina chest pain.',
    ),
    'carvedilol': MedicineProfile(
      bnName: 'কার্ভেডিলল',
      categoryBn: 'হার্ট ফেইলিউর ও রক্তচাপ',
      categoryEn: 'Heart Failure & BP',
      summaryBn: 'এই ওষুধটি হৃদযন্ত্রের কার্যক্ষমতা বাড়াতে এবং রক্তচাপ কমাতে ব্যবহার করা হয়।',
      summaryEn: 'Improves heart pumping function and manages high blood pressure.',
    ),
    'atorvastatin': MedicineProfile(
      bnName: 'অ্যাটরভাস্ট্যাটিন',
      categoryBn: 'কোলেস্টেরল নিয়ন্ত্রণ',
      categoryEn: 'Cholesterol Lowering (Statin)',
      summaryBn: 'এই ওষুধটি রক্তের ক্ষতিকর কোলেস্টেরল কমিয়ে হৃদরোগ ও স্ট্রোকের ঝুঁকি কমায়।',
      summaryEn: 'Reduces bad cholesterol (LDL) and triglycerides, protecting against heart attacks.',
    ),
    'rosuvastatin': MedicineProfile(
      bnName: 'রোসুভাস্ট্যাটিন',
      categoryBn: 'কোলেস্টেরল নিয়ন্ত্রণ',
      categoryEn: 'Cholesterol & Lipid Control',
      summaryBn: 'এই শক্তিশালী ওষুধটি রক্তের চর্বি কমিয়ে ধমনী পরিষ্কার ও সুস্থ রাখতে সাহায্য করে।',
      summaryEn: 'Potent statin used to lower blood cholesterol levels and arterial plaque.',
    ),

    // --- Diabetes ---
    'metformin': MedicineProfile(
      bnName: 'মেটফরমিন',
      categoryBn: 'রক্তের শর্করা নিয়ন্ত্রণ',
      categoryEn: 'Diabetes Blood Sugar Control',
      summaryBn: 'এই ওষুধটি টাইপ ২ ডায়াবেটিসে রক্তের শর্করার মাত্রা নিয়ন্ত্রণে সহায়তা করে।',
      summaryEn: 'First-line medication for controlling blood sugar levels in type 2 diabetes.',
    ),
    'glimepiride': MedicineProfile(
      bnName: 'গ্লিমেপিরিড',
      categoryBn: 'ডায়াবেটিস নিয়ন্ত্রণ',
      categoryEn: 'Diabetes Glucose Control',
      summaryBn: 'এই ওষুধটি অগ্ন্যাশয় থেকে ইনসুলিন নিঃসরণ বাড়িয়ে রক্তের চিনি কমায়।',
      summaryEn: 'Stimulates insulin release from the pancreas to reduce blood glucose.',
    ),
    'gliclazide': MedicineProfile(
      bnName: 'গ্লিক্লাজাইড',
      categoryBn: 'ডায়াবেটিস নিয়ন্ত্রণ',
      categoryEn: 'Oral Diabetes Medicine',
      summaryBn: 'এই ওষুধটি টাইপ ২ ডায়াবেটিসে ইনসুলিন তৈরি বৃদ্ধি করে শর্করা স্বাভাবিক রাখে।',
      summaryEn: 'Helps manage blood glucose levels in patients with type 2 diabetes.',
    ),
    'linagliptin': MedicineProfile(
      bnName: 'লিনাগ্লিপটিন',
      categoryBn: 'ডায়াবেটিস ও কিডনিবান্ধব',
      categoryEn: 'Kidney-Safe Diabetes Care',
      summaryBn: 'এই ওষুধটি কিডনি রোগীদের জন্যও নিরাপদভাবে রক্তের সুগার নিয়ন্ত্রণে সহায়তা করে।',
      summaryEn: 'DPP-4 inhibitor for improving blood glucose, safe for kidneys.',
    ),
    'vildagliptin': MedicineProfile(
      bnName: 'ভিলডাগ্লিপটিন',
      categoryBn: 'ডায়াবেটিস নিয়ন্ত্রণ',
      categoryEn: 'Diabetes Sugar Management',
      summaryBn: 'এই ওষুধটি রক্তে শর্করার মাত্রা নিয়ন্ত্রণে ইনসুলিন উৎপাদন বাড়ায়।',
      summaryEn: 'Increases insulin secretion to effectively control blood glucose.',
    ),
    'empagliflozin': MedicineProfile(
      bnName: 'এম্পাগ্লিফ্লোজিন',
      categoryBn: 'ডায়াবেটিস ও হৃদযন্ত্র সুরক্ষা',
      categoryEn: 'Diabetes & Heart Protection',
      summaryBn: 'এই ওষুধটি প্রস্রাবের মাধ্যমে অতিরিক্ত চিনি বের করে দেয় এবং হৃদযন্ত্র সুরক্ষিত রাখে।',
      summaryEn: 'Eliminates excess glucose through urine and provides heart protection.',
    ),
    'dapagliflozin': MedicineProfile(
      bnName: 'ডাপাগ্লিফ্লোজিন',
      categoryBn: 'ডায়াবেটিস ও কিডনি সুরক্ষা',
      categoryEn: 'Diabetes & Kidney Health',
      summaryBn: 'এই ওষুধটি রক্তে চিনি কমায় এবং কিডনি ও হার্টের কার্যক্ষমতা বজায় রাখতে সাহায্য করে।',
      summaryEn: 'Lowers blood sugar while supporting kidney function and heart health.',
    ),

    // --- Nausea, Vomiting & Antispasmodics ---
    'domperidone': MedicineProfile(
      bnName: 'ডমপেরিডোন',
      categoryBn: 'বমি বমি ভাব ও বদহজম',
      categoryEn: 'Nausea & Indigestion',
      summaryBn: 'এই ওষুধটি বমি বমি ভাব, বমি এবং পেট ফাঁপা বা অস্বস্তি দূর করতে ব্যবহৃত হয়।',
      summaryEn: 'Relieves nausea, vomiting, fullness, and promotes healthy digestion.',
    ),
    'ondansetron': MedicineProfile(
      bnName: 'অনডানসেট্রন',
      categoryBn: 'বমি বন্ধকারী',
      categoryEn: 'Anti-Emetic (Stops Vomiting)',
      summaryBn: 'এই ওষুধটি তীব্র বমি ভাব ও বমি বন্ধ করতে দ্রুত কাজ করে।',
      summaryEn: 'Fast-acting medication that prevents and stops nausea and vomiting.',
    ),
    'tiemonium': MedicineProfile(
      bnName: 'টিমোনিয়াম',
      categoryBn: 'পেটের মোচড় ও খিঁচুনি ব্যথা',
      categoryEn: 'Abdominal Cramp Relief',
      summaryBn: 'এই ওষুধটি পেটের তীব্র মোচড়, খিঁচুনি ও পিরিয়ডের ব্যথা উপশম করে।',
      summaryEn: 'Antispasmodic for acute spasms of the intestine and menstrual cramps.',
    ),
    'hyoscine': MedicineProfile(
      bnName: 'হায়োসিন',
      categoryBn: 'পেট মোচড়ানো ব্যথা',
      categoryEn: 'Stomach Cramps & Spasms',
      summaryBn: 'এই ওষুধটি পেটের নাড়িভুঁড়ির পেশি শিথিল করে পেট মোচড়ানো ব্যথা দ্রুত কমায়।',
      summaryEn: 'Relieves gastrointestinal cramps, abdominal spasms, and bladder colic.',
    ),

    // --- Vitamins & Supplements ---
    'calcium': MedicineProfile(
      bnName: 'ক্যালসিয়াম',
      categoryBn: 'হাড় ও দাঁতের পুষ্টি',
      categoryEn: 'Bone & Teeth Strength',
      summaryBn: 'এই ক্যালসিয়াম হাড় ও দাঁতের গঠন মজবুত রাখতে এবং ক্ষয়রোধে ব্যবহৃত হয়।',
      summaryEn: 'Supplements essential calcium for bone density and osteoporosis prevention.',
    ),
    'vitamin d3': MedicineProfile(
      bnName: 'ভিটামিন ডি৩',
      categoryBn: 'হাড় ও রোগপ্রতিরোধ',
      categoryEn: 'Bone & Immune Health',
      summaryBn: 'এই ভিটামিন হাড়ের শক্তি বৃদ্ধি করে এবং শরীরের রোগপ্রতিরোধ ক্ষমতা উন্নত রাখে।',
      summaryEn: 'Supports calcium absorption, bone density, and healthy immune response.',
    ),
    'ferrous': MedicineProfile(
      bnName: 'আয়রন (লোহা)',
      categoryBn: 'রক্তস্বল্পতা দূরীকরণ',
      categoryEn: 'Iron Supplement (Anemia)',
      summaryBn: 'এই আয়রন শরীরে রক্ত তৈরি করে রক্তশূন্যতা ও শারীরিক দুর্বলতা দূর করতে ব্যবহৃত হয়।',
      summaryEn: 'Replenishes iron stores to treat and prevent iron deficiency anemia.',
    ),
    'folic acid': MedicineProfile(
      bnName: 'ফলিক অ্যাসিড',
      categoryBn: 'রক্তস্বল্পতা ও গর্ভকালীন পুষ্টি',
      categoryEn: 'Prenatal & Blood Health',
      summaryBn: 'এই ভিটামিন রক্তকণিকা গঠনে এবং গর্ভকালীন স্বাস্থ্য রক্ষায় অত্যন্ত জরুরি।',
      summaryEn: 'Essential B-vitamin for red blood cell production and healthy pregnancy.',
    ),
    'vitamin b complex': MedicineProfile(
      bnName: 'ভিটামিন বি কমপ্লেক্স',
      categoryBn: 'স্নায়ু ও শক্তিবর্ধক',
      categoryEn: 'Energy & Nerve Support',
      summaryBn: 'এই ভিটামিন স্নায়ুর শক্তি বাড়ায়, মুখের ঘা সারায় এবং শারীরিক দুর্বলতা দূর করে।',
      summaryEn: 'Supports nervous system function, mouth ulcer recovery, and vitality.',
    ),
    'vitamin c': MedicineProfile(
      bnName: 'ভিটামিন সি',
      categoryBn: 'রোগপ্রতিরোধ ও ত্বক',
      categoryEn: 'Immunity & Skin Health',
      summaryBn: 'এই অ্যান্টিঅক্সিডেন্ট ভিটামিন রোগপ্রতিরোধ ক্ষমতা বাড়ায় ও ক্ষত শুকাতে সাহায্য করে।',
      summaryEn: 'Antioxidant that boosts immunity, supports tissue healing, and collagen.',
    ),
    'vitamin e': MedicineProfile(
      bnName: 'ভিটামিন ই',
      categoryBn: 'অ্যান্টিঅক্সিডেন্ট ও ত্বক',
      categoryEn: 'Antioxidant & Skin Care',
      summaryBn: 'এই ভিটামিন কোষের সুরক্ষা দেয় এবং ত্বক ও চুলের স্বাস্থ্য ভালো রাখে।',
      summaryEn: 'Lipid antioxidant that protects cells and supports skin and heart health.',
    ),

    'omega-3 acid ethyl esters [salmon fish oil]': MedicineProfile(
      bnName: 'ওমেগা-৩ (মাছের তেল)',
      categoryBn: 'হার্ট ও স্বাস্থ্য সাপ্লিমেন্ট',
      categoryEn: 'Heart & Health Supplement',
      summaryBn: 'এই ওমেগা-৩ রক্তের ক্ষতিকর চর্বি কমাতে এবং হার্ট ও শরীর সুস্থ রাখতে সাহায্য করে।',
      summaryEn: 'Dietary supplement to reduce blood triglycerides and support heart and cellular health.',
      precautionBn: 'খাবারের সাথে বা ভরা পেটে সেবন করুন।',
      precautionEn: 'Take with or immediately after meals.',
    ),
    'omega-3 acid ethyl esters': MedicineProfile(
      bnName: 'ওমেগা-৩ ফ্যাটি অ্যাসিড',
      categoryBn: 'হার্ট ও স্বাস্থ্য সাপ্লিমেন্ট',
      categoryEn: 'Heart & Health Supplement',
      summaryBn: 'এই ওমেগা-৩ রক্তের ক্ষতিকর চর্বি কমাতে এবং হার্ট ও শরীর সুস্থ রাখতে সাহায্য করে।',
      summaryEn: 'Dietary supplement to reduce blood triglycerides and support heart and cellular health.',
      precautionBn: 'খাবারের সাথে বা ভরা পেটে সেবন করুন।',
      precautionEn: 'Take with or immediately after meals.',
    ),
    'salmon fish oil': MedicineProfile(
      bnName: 'স্যামন মাছের তেল (ওমেগা-৩)',
      categoryBn: 'পুষ্টি ও হার্ট সাপ্লিমেন্ট',
      categoryEn: 'Nutritional & Heart Supplement',
      summaryBn: 'এটি স্বাস্থ্যকর ওমেগা-৩ যা রক্তের চর্বি কমায় এবং হৃদযন্ত্র ভালো রাখে।',
      summaryEn: 'Natural source of omega-3 to support cardiovascular wellness and vitality.',
      precautionBn: 'খাবারের সাথে সেবন করুন।',
      precautionEn: 'Take with food.',
    ),
    'omega-3': MedicineProfile(
      bnName: 'ওমেগা-৩',
      categoryBn: 'হার্ট ও স্বাস্থ্য সাপ্লিমেন্ট',
      categoryEn: 'Heart & Health Supplement',
      summaryBn: 'এই ওমেগা-৩ রক্তের ক্ষতিকর চর্বি কমাতে এবং হার্ট ও শরীর সুস্থ রাখতে সাহায্য করে।',
      summaryEn: 'Dietary supplement to reduce blood triglycerides and support heart health.',
      precautionBn: 'খাবারের সাথে বা ভরা পেটে সেবন করুন।',
      precautionEn: 'Take with or immediately after meals.',
    ),

    // --- CNS & Sleep ---
    'clonazepam': MedicineProfile(
      bnName: 'ক্লোনাজেপাম',
      categoryBn: 'খিঁচুনি ও উদ্বেগ নিয়ন্ত্রণ',
      categoryEn: 'Anxiety & Seizure Relief',
      summaryBn: 'এই ওষুধটি স্নায়ু শান্ত করে প্যানিক অ্যাটাক, অতিরিক্ত উদ্বেগ ও খিঁচুনি নিয়ন্ত্রণে ব্যবহৃত হয়।',
      summaryEn: 'Calms nerves to treat panic attacks, severe anxiety, and seizure disorders.',
    ),
    'alprazolam': MedicineProfile(
      bnName: 'আলপ্রাজোলাম',
      categoryBn: 'উদ্বেগ ও মানসিক চাপ',
      categoryEn: 'Short-term Anxiety Relief',
      summaryBn: 'এই ওষুধটি অতিরিক্ত দুশ্চিন্তা, মানসিক উদ্বেগ এবং অস্থিরতা কমাতে স্বল্পমেয়াদে ব্যবহৃত হয়।',
      summaryEn: 'Fast-acting anxiolytic for temporary management of severe anxiety and stress.',
    ),
    'pregabalin': MedicineProfile(
      bnName: 'প্রেগাবালিন',
      categoryBn: 'স্নায়ুর ব্যথা ও জ্বালাপোড়া',
      categoryEn: 'Nerve Pain Relief',
      summaryBn: 'এই ওষুধটি স্নায়বিক জ্বালাপোড়া ব্যথা, হাত-পায়ের অবশ ভাব ও ব্যথায় ব্যবহৃত হয়।',
      summaryEn: 'Relieves neuropathic pain, diabetic nerve pain, and fibromyalgia discomfort.',
    ),

    // --- Antifungals & Parasites ---
    'fluconazole': MedicineProfile(
      bnName: 'ফ্লুকোনাজল',
      categoryBn: 'ছত্রাক সংক্রমণ নাশক',
      categoryEn: 'Antifungal Infection Care',
      summaryBn: 'এই ওষুধটি ত্বক, নখ, মুখ ও যৌনাঙ্গের ছত্রাকজনিত সংক্রমণ নিরাময়ে কার্যকর।',
      summaryEn: 'Antifungal medication for fungal and yeast infections of skin, mouth, and body.',
    ),
    'albendazole': MedicineProfile(
      bnName: 'অ্যালবেনডাজল',
      categoryBn: 'কৃমিনাশক',
      categoryEn: 'Anthelmintic (Deworming)',
      summaryBn: 'এই কৃমিনাশক ওষুধ পেটের বিভিন্ন প্রকার কৃমি সংক্রমণ দূর করতে নির্দিষ্ট মাত্রায় ব্যবহার করা হয়।',
      summaryEn: 'Broad-spectrum deworming medication for eliminating intestinal parasites.',
    ),
  };
}