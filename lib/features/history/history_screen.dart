// lib/features/history/history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../domain/models/scan_history_model.dart';
import '../../services/storage_service.dart';
import '../../services/tts_service.dart';
import '../results/results_screen.dart';
import '../scanner/scanner_viewmodel.dart';

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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); Navigator.of(context).pop(); },
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Icon(Icons.arrow_back_rounded, color: cs.onSurfaceVariant, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(language == 'bn' ? 'আগের স্ক্যান' : 'History',
                          style: TextStyle(color: cs.onSurface, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                      Text('${_history.length} ${language == 'bn' ? 'টি' : 'scans'}',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                    ]),
                  ),
                  if (_history.isNotEmpty)
                    GestureDetector(
                      onTap: () => _confirmClear(context, cs, language),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.outline),
                        ),
                        child: Text(language == 'bn' ? 'মুছুন' : 'Clear',
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: _history.isEmpty
                  ? _EmptyState(language: language, cs: cs)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _history.length,
                      itemBuilder: (_, i) => _HistoryCard(
                        item: _history[i],
                        language: language,
                        cs: cs,
                        index: i,
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
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: cs.outline, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(language == 'bn' ? 'সব স্ক্যান মুছে ফেলবেন?' : 'Clear all history?',
              style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () async {
              await ref.read(storageServiceProvider).deleteAll();
              if (mounted) { Navigator.pop(context); setState(() => _history = []); }
            },
            child: Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.error.withValues(alpha: 0.3)),
              ),
              child: Center(child: Text(language == 'bn' ? 'হ্যাঁ, মুছুন' : 'Clear all',
                  style: TextStyle(color: cs.error, fontSize: 15, fontWeight: FontWeight.w700))),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(language == 'bn' ? 'বাতিল' : 'Cancel',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.w500))),
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
  final int index;

  const _HistoryCard({required this.item, required this.language, required this.cs, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.brandName,
                    style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(item.genericName,
                    style: TextStyle(color: cs.primary.withValues(alpha: 0.7), fontSize: 11, fontStyle: FontStyle.italic)),
              ]),
            ),
            Text(AppDateUtils.formatForDisplay(item.scannedAt),
                style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 10)),
          ]),
          const SizedBox(height: 10),
          Text(item.summary,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, height: 1.55),
              maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(ttsServiceProvider).speak(
                '${item.brandName}. ${item.summary}',
                language: item.language,
                englishFallback: '${item.brandName}. ${item.summary}',
              );
            },
            child: Container(
              width: double.infinity, height: 40,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.volume_up_rounded, color: cs.primary.withValues(alpha: 0.7), size: 16),
                const SizedBox(width: 6),
                Text(language == 'bn' ? 'শুনুন' : 'Play',
                    style: TextStyle(color: cs.primary.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
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
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outline),
          ),
          child: Icon(Icons.history_rounded, size: 32, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
        ),
        const SizedBox(height: 16),
        Text(language == 'bn' ? 'এখনো কোনো স্ক্যান নেই' : 'No scans yet',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(language == 'bn' ? 'আপনার প্রথম ওষুধ স্ক্যান করুন' : 'Scan your first medicine to see it here',
            style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 13)),
      ]),
    );
  }
}