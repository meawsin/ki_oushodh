// lib/features/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';
import '../results/results_screen.dart';
import '../scanner/scanner_viewmodel.dart';

// ---------------------------------------------------------------------------
// Settings State
// ---------------------------------------------------------------------------
class AppSettings {
  final bool isDarkMode;
  final double fontScale;
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
// Provider
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

  Future<void> setDarkMode(bool v) async {
    await ref.read(sharedPreferencesProvider).setBool(_darkKey, v);
    state = state.copyWith(isDarkMode: v);
  }

  Future<void> setFontScale(double v) async {
    await ref.read(sharedPreferencesProvider).setDouble(_fontKey, v);
    state = state.copyWith(fontScale: v);
  }

  Future<void> setSaveHistory(bool v) async {
    await ref.read(sharedPreferencesProvider).setBool(_historyKey, v);
    state = state.copyWith(saveHistory: v);
  }

  Future<void> setHighContrast(bool v) async {
    await ref.read(sharedPreferencesProvider).setBool(_contrastKey, v);
    state = state.copyWith(highContrast: v);
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
    final cs = Theme.of(context).colorScheme;

    String t(String bn, String en) => language == 'bn' ? bn : en;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
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
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          color: cs.onSurfaceVariant, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(t('সেটিংস', 'Settings'),
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      )),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [

                  // ── DISPLAY ───────────────────────────────────────
                  _SectionLabel(t('ডিসপ্লে', 'Display'), cs),

                  _Tile(
                    icon: settings.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    title: t('থিম', 'Theme'),
                    subtitle: settings.isDarkMode
                        ? t('ডার্ক মোড চালু', 'Dark mode on')
                        : t('লাইট মোড চালু', 'Light mode on'),
                    cs: cs,
                    trailing: _ThemedSwitch(
                      value: settings.isDarkMode,
                      cs: cs,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        ref.read(settingsProvider.notifier).setDarkMode(v);
                      },
                    ),
                  ),

                  _Tile(
                    icon: Icons.contrast_rounded,
                    title: t('উচ্চ কন্ট্রাস্ট', 'High contrast'),
                    subtitle: settings.highContrast
                        ? t('চালু — বর্ডার উজ্জ্বল', 'On — bright borders')
                        : t('বন্ধ', 'Off'),
                    cs: cs,
                    trailing: _ThemedSwitch(
                      value: settings.highContrast,
                      cs: cs,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        ref.read(settingsProvider.notifier).setHighContrast(v);
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── TEXT SIZE ─────────────────────────────────────
                  _SectionLabel(t('লেখার আকার', 'Text size'), cs),

                  _FontSizePicker(
                    value: settings.fontScale,
                    language: language,
                    cs: cs,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      ref.read(settingsProvider.notifier).setFontScale(v);
                    },
                  ),

                  const SizedBox(height: 8),

                  // ── LANGUAGE ──────────────────────────────────────
                  _SectionLabel(t('ভাষা', 'Language'), cs),
                  _LanguagePicker(cs: cs),

                  const SizedBox(height: 8),

                  // ── HISTORY ───────────────────────────────────────
                  _SectionLabel(t('ইতিহাস', 'History'), cs),

                  _Tile(
                    icon: Icons.history_rounded,
                    title: t('স্ক্যান সংরক্ষণ', 'Save scan history'),
                    subtitle: t('৩০ দিন পর্যন্ত', 'Kept for 30 days'),
                    cs: cs,
                    trailing: _ThemedSwitch(
                      value: settings.saveHistory,
                      cs: cs,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        ref.read(settingsProvider.notifier).setSaveHistory(v);
                      },
                    ),
                  ),

                  _Tile(
                    icon: Icons.delete_outline_rounded,
                    title: t('সব ইতিহাস মুছুন', 'Clear all history'),
                    subtitle: t('পূর্বাবস্থায় ফেরানো যাবে না', 'Cannot be undone'),
                    cs: cs,
                    iconColor: cs.error,
                    onTap: () => _confirmClear(context, ref, cs, language),
                  ),

                  const SizedBox(height: 8),

                  // ── ABOUT ─────────────────────────────────────────
                  _SectionLabel(t('অ্যাপ সম্পর্কে', 'About'), cs),

                  _Tile(
                    icon: Icons.info_outline_rounded,
                    title: 'কি ঔষধ',
                    subtitle: 'Version 1.0.0 · MVP',
                    cs: cs,
                  ),

                  _Tile(
                    icon: Icons.medication_rounded,
                    title: t('ডেটাবেস', 'Database'),
                    subtitle: t('১৩,৯২৯টি বাংলাদেশি ওষুধ',
                        '13,929 Bangladeshi medicines'),
                    cs: cs,
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

  void _confirmClear(BuildContext context, WidgetRef ref,
      ColorScheme cs, String language) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: cs.outline, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(
            language == 'bn' ? 'সব ইতিহাস মুছবেন?' : 'Clear all history?',
            style: TextStyle(
                color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () async {
              await ref.read(storageServiceProvider).deleteAll();
              if (context.mounted) Navigator.pop(context);
            },
            child: Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.error.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  language == 'bn' ? 'হ্যাঁ, মুছুন' : 'Clear all',
                  style: TextStyle(
                      color: cs.error, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  language == 'bn' ? 'বাতিল' : 'Cancel',
                  style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Font size picker
// ---------------------------------------------------------------------------
class _FontSizePicker extends StatelessWidget {
  final double value;
  final String language;
  final ColorScheme cs;
  final ValueChanged<double> onChanged;

  const _FontSizePicker({
    required this.value,
    required this.language,
    required this.cs,
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
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
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
                  color: selected ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(label,
                      style: TextStyle(
                        color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                        fontSize: fontSize,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w400,
                      )),
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
  final ColorScheme cs;
  const _LanguagePicker({required this.cs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          _LangOption(
            label: 'বাংলা', sublabel: 'Bangla',
            selected: language == 'bn', cs: cs,
            onTap: () => ref.read(languageProvider.notifier).setLanguage('bn'),
          ),
          _LangOption(
            label: 'English', sublabel: 'ইংরেজি',
            selected: language == 'en', cs: cs,
            onTap: () => ref.read(languageProvider.notifier).setLanguage('en'),
          ),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label, sublabel;
  final bool selected;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _LangOption({
    required this.label, required this.sublabel,
    required this.selected, required this.cs, required this.onTap,
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
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: TextStyle(
                      color: selected ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    )),
                Text(sublabel,
                    style: TextStyle(
                      color: selected
                          ? cs.onPrimary.withValues(alpha: 0.6)
                          : cs.onSurfaceVariant,
                      fontSize: 11,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable tile
// ---------------------------------------------------------------------------
class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final ColorScheme cs;

  const _Tile({
    required this.icon,
    required this.title,
    required this.cs,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? cs.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: effectiveIconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: effectiveIconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ],
            ]),
          ),
          if (trailing != null) trailing!,
          if (onTap != null && trailing == null)
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4), size: 20),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  const _SectionLabel(this.label, this.cs);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(label.toUpperCase(),
          style: TextStyle(
            color: cs.primary.withValues(alpha: 0.7),
            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5,
          )),
    );
  }
}

// ---------------------------------------------------------------------------
// Themed switch
// ---------------------------------------------------------------------------
class _ThemedSwitch extends StatelessWidget {
  final bool value;
  final ColorScheme cs;
  final ValueChanged<bool> onChanged;

  const _ThemedSwitch({
    required this.value,
    required this.cs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: cs.onPrimary,
      activeTrackColor: cs.primary,
      inactiveThumbColor: cs.onSurfaceVariant.withValues(alpha: 0.6),
      inactiveTrackColor: cs.surfaceContainerHighest,
    );
  }
}