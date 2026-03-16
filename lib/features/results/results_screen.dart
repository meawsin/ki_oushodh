// lib/features/results/results_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/scan_result.dart';
import '../../services/storage_service.dart';
import '../scanner/scanner_viewmodel.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

class ResultsScreen extends ConsumerStatefulWidget {
  final ScanResult result;
  const ResultsScreen({super.key, required this.result});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    _saveToHistory();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _saveToHistory() async {
    try {
      await ref.read(storageServiceProvider).saveScan(
        brandName: widget.result.brandName,
        genericName: widget.result.genericName,
        summary: widget.result.summary,
        language: widget.result.language,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final language = ref.watch(languageProvider);
    final result = widget.result;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(ttsServiceProvider).stop();
          ref.read(scannerViewModelProvider.notifier).reset();
        }
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        _IconBtn(
                          icon: Icons.arrow_back_rounded,
                          cs: cs,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(ttsServiceProvider).stop();
                            Navigator.of(context).pop();
                          },
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 6, height: 6,
                                decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(
                              language == 'bn' ? 'ওষুধ চিহ্নিত' : 'Identified',
                              style: TextStyle(color: cs.primary, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Medicine name ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language == 'bn' ? 'ওষুধের নাম' : 'MEDICINE',
                          style: TextStyle(
                            color: cs.primary.withValues(alpha: 0.7),
                            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 6),
                        Text(result.medicineName,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 36, fontWeight: FontWeight.w800,
                              height: 1.1, letterSpacing: -1)),
                        const SizedBox(height: 4),
                        Text(result.genericName,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 13, fontStyle: FontStyle.italic, height: 1.4)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(color: cs.outline, height: 1),
                  ),
                  const SizedBox(height: 24),

                  // ── Summary ──────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            language == 'bn' ? 'কী কাজে লাগে?' : 'USED FOR',
                            style: TextStyle(
                              color: cs.primary.withValues(alpha: 0.7),
                              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(result.summary,
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: 20, fontWeight: FontWeight.w400, height: 1.65)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── TTS notice ───────────────────────────────────────
                  if (result.language == 'bn' && !ref.read(ttsServiceProvider).isBanglaAvailable)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(children: [
                          Icon(Icons.volume_off_rounded, color: cs.primary.withValues(alpha: 0.6), size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'বাংলায় পড়তে Play Store থেকে Google TTS → Bengali ইনস্টল করুন',
                              style: TextStyle(color: cs.primary.withValues(alpha: 0.7), fontSize: 10, height: 1.4),
                            ),
                          ),
                        ]),
                      ),
                    ),

                  // ── Action buttons ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(
                      children: [
                        _IconBtn(
                          icon: Icons.volume_up_rounded,
                          cs: cs,
                          accentBorder: true,
                          size: 56,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(ttsServiceProvider).speak(
                              result.spokenText,
                              language: result.language,
                              englishFallback: result.spokenTextEn,
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              ref.read(ttsServiceProvider).stop();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.primary.withValues(alpha: 0.2),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  language == 'bn' ? 'আবার স্ক্যান করুন' : 'Scan Again',
                                  style: TextStyle(
                                    color: cs.onPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final ColorScheme cs;
  final VoidCallback onTap;
  final bool accentBorder;
  final double size;

  const _IconBtn({
    required this.icon,
    required this.cs,
    required this.onTap,
    this.accentBorder = false,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(size == 40 ? 12 : 16),
          border: Border.all(
            color: accentBorder ? cs.primary.withValues(alpha: 0.3) : cs.outline,
          ),
        ),
        child: Icon(icon,
            color: accentBorder ? cs.primary : cs.onSurfaceVariant,
            size: size == 40 ? 18 : 22),
      ),
    );
  }
}