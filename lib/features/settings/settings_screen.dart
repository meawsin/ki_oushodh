// lib/features/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../../services/storage_service.dart';
import '../../services/tts_service.dart';
import '../results/results_screen.dart';
import '../scanner/scanner_viewmodel.dart';

// ---------------------------------------------------------------------------
// Settings State
// ---------------------------------------------------------------------------
class AppSettings {
  final bool isDarkMode;
  final double fontScale;    // 1.0 = normal, 1.3 = large, 1.6 = very large
  final bool saveHistory;
  final bool highContrast;

  const AppSettings({
    this.isDarkMode = true,
    this.fontScale = 1.0,
    this.saveHistory = true,
    this.highContrast = false,
  });

  AppSettings copyWith({
    bool? isDarkMode,
    double? fontScale,
    bool? saveHistory,
    bool? highContrast,
  }) => AppSettings(
    isDarkMode: isDarkMode ?? this.isDarkMode,
    fontScale: fontScale ?? this.fontScale,
    saveHistory: saveHistory ?? this.saveHistory,
    highContrast: highContrast ?? this.highContrast,
  );
}

// ---------------------------------------------------------------------------
// Settings Provider
// ---------------------------------------------------------------------------
final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  static const _darkKey = 'dark_mode';
  static const _fontKey = 'font_scale';
  static const _historyKey = 'save_history';
  static const _contrastKey = 'high_contrast';

  @override
  AppSettings build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return AppSettings(
      isDarkMode: prefs.getBool(_darkKey) ?? true,
      fontScale: prefs.getDouble(_fontKey) ?? 1.0,
      saveHistory: prefs.getBool(_historyKey) ?? true,
      highContrast: prefs.getBool(_contrastKey) ?? false,
    );
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_darkKey, value);
    state = state.copyWith(isDarkMode: value);
  }

  Future<void> setFontScale(double value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble(_fontKey, value);
    state = state.copyWith(fontScale: value);
  }

  Future<void> setSaveHistory(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_historyKey, value);
    state = state.copyWith(saveHistory: value);
  }

  Future<void> setHighContrast(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_contrastKey, value);
    state = state.copyWith(highContrast: value);
  }
}

// ---------------------------------------------------------------------------
// Settings Screen
// ---------------------------------------------------------------------------
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final language = ref.watch(languageProvider);

    String t(String bn, String en) => language == 'bn' ? bn : en;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          color: Colors.white.withValues(alpha: 0.7), size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    t('সেটিংস', 'Settings'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [

                  // ── DISPLAY ──────────────────────────────────────────
                  _SectionHeader(label: t('ডিসপ্লে', 'Display')),

                  // Dark mode
                  _SettingsTile(
                    icon: settings.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    title: t('থিম', 'Theme'),
                    subtitle: settings.isDarkMode
                        ? t('ডার্ক মোড চালু', 'Dark mode on')
                        : t('লাইট মোড চালু', 'Light mode on'),
                    trailing: _Switch(
                      value: settings.isDarkMode,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        ref.read(settingsProvider.notifier).setDarkMode(v);
                      },
                    ),
                  ),

                  // High contrast
                  _SettingsTile(
                    icon: Icons.contrast_rounded,
                    title: t('উচ্চ কন্ট্রাস্ট', 'High contrast'),
                    subtitle: settings.highContrast
                        ? t('চালু — বর্ডার উজ্জ্বল', 'On — bright borders')
                        : t('বন্ধ', 'Off'),
                    trailing: _Switch(
                      value: settings.highContrast,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        ref.read(settingsProvider.notifier).setHighContrast(v);
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── FONT SIZE ─────────────────────────────────────────
                  _SectionHeader(label: t('লেখার আকার', 'Text size')),

                  _FontSizePicker(
                    value: settings.fontScale,
                    language: language,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      ref.read(settingsProvider.notifier).setFontScale(v);
                    },
                  ),

                  const SizedBox(height: 8),

                  // ── LANGUAGE ─────────────────────────────────────────
                  _SectionHeader(label: t('ভাষা', 'Language')),

                  _LanguagePicker(),

                  const SizedBox(height: 8),

                  // ── HISTORY ──────────────────────────────────────────
                  _SectionHeader(label: t('ইতিহাস', 'History')),

                  _SettingsTile(
                    icon: Icons.history_rounded,
                    title: t('স্ক্যান সংরক্ষণ', 'Save scan history'),
                    subtitle: t('৩০ দিন পর্যন্ত', 'Kept for 30 days'),
                    trailing: _Switch(
                      value: settings.saveHistory,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        ref.read(settingsProvider.notifier).setSaveHistory(v);
                      },
                    ),
                  ),

                  _SettingsTile(
                    icon: Icons.delete_outline_rounded,
                    title: t('সব ইতিহাস মুছুন', 'Clear all history'),
                    subtitle: t('এটি পূর্বাবস্থায় ফেরানো যাবে না',
                        'Cannot be undone'),
                    iconColor: const Color(0xFFFF5252),
                    onTap: () => _confirmClearHistory(context, ref, language),
                  ),

                  const SizedBox(height: 8),

                  // ── ABOUT ─────────────────────────────────────────────
                  _SectionHeader(label: t('অ্যাপ সম্পর্কে', 'About')),

                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: t('কি ঔষধ', 'Ki Oushodh'),
                    subtitle: 'Version 1.0.0 · MVP',
                  ),

                  _SettingsTile(
                    icon: Icons.medication_rounded,
                    title: t('ডেটাবেস', 'Database'),
                    subtitle: t('১৩,৯২৯টি বাংলাদেশি ওষুধ',
                        '13,929 Bangladeshi medicines'),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearHistory(
      BuildContext context, WidgetRef ref, String language) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              language == 'bn' ? 'সব ইতিহাস মুছবেন?' : 'Clear all history?',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () async {
                await ref.read(storageServiceProvider).deleteAll();
                if (context.mounted) Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A0000),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    language == 'bn' ? 'হ্যাঁ, মুছুন' : 'Clear all',
                    style: const TextStyle(
                        color: Color(0xFFFF5252),
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    language == 'bn' ? 'বাতিল' : 'Cancel',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Font size picker — three explicit buttons (Normal / Large / Very Large)
// Elderly users should not have to deal with a slider
// ---------------------------------------------------------------------------
class _FontSizePicker extends StatelessWidget {
  final double value;
  final String language;
  final ValueChanged<double> onChanged;

  const _FontSizePicker({
    required this.value,
    required this.language,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      (1.0, language == 'bn' ? 'স্বাভাবিক' : 'Normal', 14.0),
      (1.3, language == 'bn' ? 'বড়' : 'Large', 17.0),
      (1.6, language == 'bn' ? 'অনেক বড়' : 'X-Large', 20.0),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: options.map((opt) {
          final (scale, label, fontSize) = opt;
          final selected = (value - scale).abs() < 0.05;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(scale),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 52,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFFFBF00)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF1A1A00)
                          : Colors.white.withValues(alpha: 0.4),
                      fontSize: fontSize,
                      fontWeight: selected
                          ? FontWeight.w800
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language picker
// ---------------------------------------------------------------------------
class _LanguagePicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _LangOption(
            label: 'বাংলা',
            sublabel: 'Bangla',
            selected: language == 'bn',
            onTap: () => ref.read(languageProvider.notifier).setLanguage('bn'),
          ),
          _LangOption(
            label: 'English',
            sublabel: 'ইংরেজি',
            selected: language == 'en',
            onTap: () => ref.read(languageProvider.notifier).setLanguage('en'),
          ),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 60,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFBF00) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF1A1A00)
                        : Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
                Text(
                  sublabel,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF1A1A00).withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable components
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: const Color(0xFFFFBF00).withValues(alpha: 0.7),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: outline),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFFFFBF00))
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? const Color(0xFFFFBF00),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null)
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.2), size: 20),
          ],
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Switch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFFFFBF00),
      activeTrackColor: const Color(0xFFFFBF00).withValues(alpha: 0.3),
      inactiveThumbColor: Colors.white.withValues(alpha: 0.3),
      inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
    );
  }
}