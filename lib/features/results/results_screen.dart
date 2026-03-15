// lib/features/results/results_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/scan_result.dart';
import '../../services/storage_service.dart';
import '../../services/tts_service.dart';
import '../scanner/scanner_viewmodel.dart';

// ---------------------------------------------------------------------------
// ResultsScreen — rebuilt for elderly/low-literacy users
//
// Design principles:
//   - ONE big medicine name at the top
//   - ONE simple sentence what it does
//   - TWO giant buttons: Play Again + Scan Again
//   - No clutter, no clinical jargon
// ---------------------------------------------------------------------------
class ResultsScreen extends ConsumerStatefulWidget {
  final ScanResult result;

  const ResultsScreen({super.key, required this.result});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    // Save to history
    _saveToHistory();
  }

  Future<void> _saveToHistory() async {
    try {
      final storage = ref.read(storageServiceProvider);
      await storage.saveScan(
        brandName: widget.result.brandName,
        genericName: widget.result.genericName,
        summary: widget.result.summary,
        language: widget.result.language,
      );
    } catch (e) {
      debugPrint('History save error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final language = ref.watch(languageProvider);
    final result = widget.result;

    return PopScope(
      // When user presses back, reset the scanner state
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(scannerViewModelProvider.notifier).reset();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'কি ঔষধ',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    _LanguageToggle(),
                  ],
                ),

                const SizedBox(height: 40),

                // ── Medicine Name ────────────────────────────────────────
                Text(
                  language == 'bn' ? 'ওষুধের নাম' : 'Medicine',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.medicineName,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                // Generic name in smaller subtitle
                Text(
                  result.genericName,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 32),
                Divider(color: colorScheme.onSurface.withValues(alpha: 0.15)),
                const SizedBox(height: 24),

                // ── Use / Summary ────────────────────────────────────────
                Text(
                  language == 'bn' ? 'কী কাজে লাগে?' : 'What is it used for?',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      result.summary,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Play Again ───────────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: () {
                    final tts = ref.read(ttsServiceProvider);
                    tts.speak(result.spokenText, language: result.language);
                  },
                  icon: const Icon(Icons.volume_up_rounded, size: 28),
                  label: Text(language == 'bn' ? 'আবার শুনুন' : 'Play Again'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 64),
                    side: BorderSide(color: colorScheme.primary, width: 2),
                    textStyle: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Scan Again ───────────────────────────────────────────
                ElevatedButton.icon(
                  onPressed: () {
                    // Stop audio first, then pop — simple and reliable
                    ref.read(ttsServiceProvider).stop();
                    Navigator.of(context).pop();
                    // Reset happens in PopScope.onPopInvokedWithResult
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 28),
                  label: Text(
                      language == 'bn' ? 'আবার স্ক্যান করুন' : 'Scan Again'),
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
// Language Toggle — shared widget
// ---------------------------------------------------------------------------
class LanguageToggleWidget extends ConsumerWidget {
  const LanguageToggleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _LanguageToggle();
  }
}

class _LanguageToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('EN',
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  language == 'en' ? FontWeight.w800 : FontWeight.w400,
              color: language == 'en'
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.4),
            )),
        Switch(
          value: language == 'bn',
          onChanged: (_) =>
              ref.read(languageProvider.notifier).toggle(),
          activeColor: colorScheme.primary,
        ),
        Text('বাং',
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  language == 'bn' ? FontWeight.w800 : FontWeight.w400,
              color: language == 'bn'
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.4),
            )),
      ],
    );
  }
}

// Provider
final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());