// lib/features/results/results_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/scan_result.dart';
import '../../services/tts_service.dart';
import '../scanner/scanner_viewmodel.dart';

// ---------------------------------------------------------------------------
// ResultsScreen
//
// Shown when Gemini returns a successful ScanResult.
// Design mandates (PRD §4 step 6, PRD §6):
//   - Medicine name: very large, bold, high contrast
//   - Summary: large, readable line height
//   - "Scan Again" button: full-width, tall tap target
//   - Replay button: lets user hear the result again without rescanning
//   - Language toggle: visible at all times
// ---------------------------------------------------------------------------
class ResultsScreen extends ConsumerWidget {
  final ScanResult result;

  const ResultsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final language = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top bar: Language toggle ──────────────────────────────
              _LanguageToggle(),
              const SizedBox(height: 32),

              // ── Medicine name ─────────────────────────────────────────
              Text(
                language == 'bn' ? 'ওষুধের নাম:' : 'Medicine:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                result.medicineName,
                style: Theme.of(context).textTheme.displaySmall,
              ),

              const SizedBox(height: 32),
              Divider(color: colorScheme.onSurface.withValues(alpha: 0.2)),
              const SizedBox(height: 24),

              // ── Summary ───────────────────────────────────────────────
              Text(
                language == 'bn' ? 'ব্যবহার:' : 'Used for:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    result.summary,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Replay audio button ───────────────────────────────────
              OutlinedButton.icon(
                onPressed: () {
                  final tts = ref.read(ttsServiceProvider);
                  tts.speak(result.spokenText, language: result.language);
                },
                icon: const Icon(Icons.volume_up_rounded, size: 28),
                label: Text(language == 'bn' ? 'আবার শুনুন' : 'Play Again'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  side: BorderSide(color: colorScheme.primary, width: 2),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Scan Again button ─────────────────────────────────────
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(scannerViewModelProvider.notifier).reset();
                },
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 28),
                label: Text(language == 'bn' ? 'আবার স্ক্যান করুন' : 'Scan Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language Toggle Widget — reusable across screens
// ---------------------------------------------------------------------------
class _LanguageToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'EN',
          style: TextStyle(
            fontSize: 16,
            fontWeight: language == 'en' ? FontWeight.w800 : FontWeight.w400,
            color: language == 'en'
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        Switch(
          value: language == 'bn',
          onChanged: (_) =>
              ref.read(languageProvider.notifier).toggle(),
          activeColor: colorScheme.primary,
        ),
        Text(
          'বাং',
          style: TextStyle(
            fontSize: 16,
            fontWeight: language == 'bn' ? FontWeight.w800 : FontWeight.w400,
            color: language == 'bn'
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}