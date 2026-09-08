// lib/features/history/history_screen.dart
//
// Key fixes vs original:
//   - History cards use InkWell with ripple (was GestureDetector)
//   - Tapping a card now opens the full result view (re-read a past scan)
//   - TTS play from history uses item's language correctly
//   - Empty state illustration is more friendly
//   - "Swipe to delete" (Dismissible) added for individual items
//   - Card summary truncated to 2 lines (was 3 — too long on small screens)
//   - Count badge shows correct "টি স্ক্যান" in Bangla

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/bn_translations.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/models/scan_history_model.dart';
import '../../domain/models/scan_result.dart';
import '../results/results_screen.dart';    // storageServiceProvider lives here
import '../scanner/scanner_viewmodel.dart'; // languageProvider + ttsServiceProvider

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<ScanHistoryModel> _history = [];

  @override
  void initState() {
    super.initState();
    _history = ref.read(storageServiceProvider).getHistory();
  }

  void _deleteItem(ScanHistoryModel item) {
    setState(() => _history.remove(item));
    ref.read(storageServiceProvider).deleteScan(item.key);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final language = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Material(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outline),
                        ),
                        child: Icon(Icons.arrow_back_rounded,
                            color: cs.onSurfaceVariant, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language == 'bn' ? 'আগের স্ক্যান' : 'Scan History',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          _history.isEmpty
                              ? (language == 'bn' ? 'কোনো স্ক্যান নেই' : 'No scans yet')
                              : (language == 'bn'
                                  ? '${_history.length}টি স্ক্যান'
                                  : '${_history.length} scan${_history.length == 1 ? '' : 's'}'),
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (_history.isNotEmpty)
                    Material(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => _confirmClear(context, cs, language),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cs.outline),
                          ),
                          child: Text(
                            language == 'bn' ? 'মুছুন' : 'Clear',
                            style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _history.isEmpty
                  ? _EmptyState(language: language, cs: cs)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _history.length,
                      itemBuilder: (_, i) => Dismissible(
                        key: ValueKey(_history[i].key),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: cs.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete_outline_rounded,
                              color: cs.error, size: 22),
                        ),
                        onDismissed: (_) {
                          HapticFeedback.mediumImpact();
                          _deleteItem(_history[i]);
                        },
                        child: _HistoryCard(
                          item: _history[i],
                          language: language,
                          cs: cs,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, ColorScheme cs, String language) {
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
                color: cs.outline, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Text(
            language == 'bn' ? 'সব স্ক্যান মুছে ফেলবেন?' : 'Clear all history?',
            style: TextStyle(
                color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            language == 'bn'
                ? 'এটি পূর্বাবস্থায় ফেরানো যাবে না।'
                : 'This cannot be undone.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Material(
            color: cs.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () async {
                final nav = Navigator.of(context);
                await ref.read(storageServiceProvider).deleteAll();
                nav.pop();
                if (mounted) setState(() => _history = []);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity, height: 52,
                decoration: BoxDecoration(
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
          ),
          const SizedBox(height: 10),
          Material(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity, height: 52,
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(14)),
                child: Center(
                  child: Text(
                    language == 'bn' ? 'বাতিল' : 'Cancel',
                    style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  final ScanHistoryModel item;
  final String language;
  final ColorScheme cs;

  const _HistoryCard({required this.item, required this.language, required this.cs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            final fullResult = ScanResult(
              medicineName: item.brandName,
              brandName: item.brandName,
              genericName: item.genericName,
              genericNameBn: BnTranslations.getGenericNameBn(item.genericName),
              category: item.category ?? BnTranslations.getCategory(item.genericName, language: item.language),
              summary: item.summary,
              summaryEn: item.summaryEn ?? item.summary,
              language: item.language,
            );
            // Tap the card → open full result view
            Navigator.of(context).push(PageRouteBuilder(
              pageBuilder: (_, a, __) => ResultsScreen(result: fullResult),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 250),
            ));
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      item.brandName,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.genericName,
                      style: TextStyle(
                        color: cs.primary.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (item.category != null && item.category!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.category!,
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
                Text(
                  AppDateUtils.formatForDisplay(item.scannedAt),
                  style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                    fontSize: 10,
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Text(
                item.summary,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.55,
                ),
                maxLines: 2,     // was 3 — 2 is cleaner on small screens
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Play button
              Material(
                color: cs.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    final fullResult = ScanResult(
                      medicineName: item.brandName,
                      brandName: item.brandName,
                      genericName: item.genericName,
                      genericNameBn: BnTranslations.getGenericNameBn(item.genericName),
                      category: item.category ?? BnTranslations.getCategory(item.genericName, language: item.language),
                      summary: item.summary,
                      summaryEn: item.summaryEn ?? item.summary,
                      language: item.language,
                    );
                    ref.read(ttsServiceProvider).speak(
                      fullResult.spokenText,
                      language: item.language,
                      englishFallback: fullResult.spokenTextEn,
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity, height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.volume_up_rounded,
                          color: cs.primary.withValues(alpha: 0.7), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        language == 'bn' ? 'শুনুন' : 'Play',
                        style: TextStyle(
                          color: cs.primary.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String language;
  final ColorScheme cs;
  const _EmptyState({required this.language, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outline),
          ),
          child: Icon(Icons.history_rounded,
              size: 36, color: cs.onSurfaceVariant.withValues(alpha: 0.35)),
        ),
        const SizedBox(height: 18),
        Text(
          language == 'bn' ? 'এখনো কোনো স্ক্যান নেই' : 'No scans yet',
          style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 17,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          language == 'bn'
              ? 'আপনার প্রথম ওষুধ স্ক্যান করুন'
              : 'Scan your first medicine to see it here',
          style: TextStyle(
              color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 13),
        ),
      ]),
    );
  }
}
