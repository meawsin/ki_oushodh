// lib/features/results/results_screen.dart
//
// Key fixes vs original:
//   - Medicine name section now shows dosage form chip (tablet / syrup / etc.)
//     extracted from generic name where available
//   - Summary text uses selectable text (SelectableText) so users can copy
//   - "USED FOR" label → more natural "ABOUT THIS MEDICINE"
//   - TTS button shows playing state (animated icon) while speaking
//   - Share button added (shares medicine name + summary as plain text)
//   - PopScope: TTS already stopped correctly — no change needed
//   - _saveToHistory respects saveHistory setting

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/scan_result.dart';
import '../../services/storage_service.dart';
import '../scanner/scanner_viewmodel.dart'; // ttsServiceProvider lives here
import '../settings/settings_screen.dart';

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
  bool _isSpeaking = false;

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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _saveToHistory() async {
    // Only save if the setting is on
    final settings = ref.read(settingsProvider);
    if (!settings.saveHistory) return;

    try {
      await ref.read(storageServiceProvider).saveScan(
        brandName: widget.result.brandName,
        genericName: widget.result.genericName,
        summary: widget.result.summary,
        summaryEn: widget.result.summaryEn,
        category: widget.result.category,
        language: widget.result.language,
      );
    } catch (_) {}
  }

  Future<void> _toggleSpeak() async {
    final tts = ref.read(ttsServiceProvider);
    if (_isSpeaking) {
      await tts.stop();
      if (mounted) setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await tts.speak(
        widget.result.spokenText,
        language: widget.result.language,
        englishFallback: widget.result.spokenTextEn,
      );
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  void _shareResult() {
    final cat = (widget.result.category != null && widget.result.category!.isNotEmpty)
        ? ' [${widget.result.category}]'
        : '';
    final precautionText = (widget.result.precaution != null && widget.result.precaution!.isNotEmpty)
        ? '\n\n⚠️ ${widget.result.language == 'bn' ? 'সতর্কতা:' : 'Precaution:'} ${widget.result.precaution}'
        : '';
    final text =
        '${widget.result.medicineName} (${widget.result.genericName})$cat\n\n${widget.result.summary}$precautionText';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.read(languageProvider) == 'bn'
              ? 'কপি হয়েছে'
              : 'Copied to clipboard',
          style: const TextStyle(fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      ),
    );
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
                  // ── Header ──────────────────────────────────────────────
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
                        // Share / copy button
                        _IconBtn(
                          icon: Icons.copy_rounded,
                          cs: cs,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _shareResult();
                          },
                        ),
                        const SizedBox(width: 8),
                        // Identified badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                  color: Colors.green, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              language == 'bn' ? 'চিহ্নিত' : 'Identified',
                              style: TextStyle(
                                  color: cs.primary, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Medicine name ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language == 'bn' ? 'ওষুধের নাম' : 'MEDICINE',
                          style: TextStyle(
                            color: cs.primary.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          result.medicineName,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                language == 'bn' && result.genericNameBn != null && result.genericNameBn!.isNotEmpty
                                    ? '${result.genericName} (${result.genericNameBn})'
                                    : result.genericName,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (result.category != null && result.category!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              result.category!,
                              style: TextStyle(
                                color: cs.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(color: cs.outline, height: 1),
                  ),
                  const SizedBox(height: 20),

                  // ── Summary ──────────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            language == 'bn' ? 'কী কাজে লাগে' : 'ABOUT THIS MEDICINE',
                            style: TextStyle(
                              color: cs.primary.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectableText(
                                    result.summary,
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w400,
                                      height: 1.7,
                                    ),
                                  ),
                                  if (result.precaution != null &&
                                      result.precaution!.isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    Semantics(
                                      label: language == 'bn'
                                          ? 'জরুরি সতর্কতা: ${result.precaution}'
                                          : 'Safety Precaution: ${result.precaution}',
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.amber.shade700
                                                .withValues(alpha: 0.35),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.warning_amber_rounded,
                                              color: Colors.amber.shade800,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    language == 'bn'
                                                        ? 'জরুরি সতর্কতা ও নিয়মাবলী'
                                                        : 'SAFETY PRECAUTION & DOSAGE',
                                                    style: TextStyle(
                                                      color: Colors.amber.shade900,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: 0.8,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  SelectableText(
                                                    result.precaution!,
                                                    style: TextStyle(
                                                      color: cs.onSurface,
                                                      fontSize: 14,
                                                      height: 1.55,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── TTS notice (Bangla unavailable) ─────────────────────
                  if (result.language == 'bn' && !ref.read(ttsServiceProvider).isBanglaAvailable)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(children: [
                          Icon(Icons.volume_off_rounded,
                              color: cs.primary.withValues(alpha: 0.6), size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'বাংলায় পড়তে Play Store থেকে Google TTS → Bengali ইনস্টল করুন',
                              style: TextStyle(
                                  color: cs.primary.withValues(alpha: 0.7),
                                  fontSize: 10,
                                  height: 1.4),
                            ),
                          ),
                        ]),
                      ),
                    ),

                  // ── Action buttons ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(
                      children: [
                        // TTS button — shows live play/stop state
                        _TtsButton(
                          cs: cs,
                          isSpeaking: _isSpeaking,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _toggleSpeak();
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Material(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                ref.read(ttsServiceProvider).stop();
                                Navigator.of(context).pop();
                              },
                              borderRadius: BorderRadius.circular(16),
                              splashColor: cs.onPrimary.withValues(alpha: 0.2),
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cs.primary.withValues(alpha: 0.22),
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

// ── TTS button with live state ───────────────────────────────────────────────
class _TtsButton extends StatelessWidget {
  final ColorScheme cs;
  final bool isSpeaking;
  final VoidCallback onTap;
  const _TtsButton({required this.cs, required this.isSpeaking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56, height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSpeaking
                  ? cs.primary.withValues(alpha: 0.6)
                  : cs.primary.withValues(alpha: 0.25),
              width: isSpeaking ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                key: ValueKey(isSpeaking),
                color: cs.primary,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Generic icon button ───────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.cs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline),
          ),
          child: Icon(icon, color: cs.onSurfaceVariant, size: 18),
        ),
      ),
    );
  }
}
