// lib/features/history/history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../domain/models/scan_history_model.dart';
import '../../services/storage_service.dart';
import '../../services/tts_service.dart';
import '../scanner/scanner_viewmodel.dart';
import '../results/results_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final language = ref.watch(languageProvider);
    final storage = ref.read(storageServiceProvider);
    final history = storage.getHistory();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Text(
          language == 'bn' ? 'আগের স্ক্যান' : 'Scan History',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: language == 'bn' ? 'সব মুছুন' : 'Clear all',
              onPressed: () => _confirmClear(context, ref, language),
            ),
        ],
      ),
      body: history.isEmpty
          ? _EmptyHistory(language: language)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _HistoryCard(
                  item: history[index],
                  language: language,
                  ref: ref,
                );
              },
            ),
    );
  }

  void _confirmClear(
      BuildContext context, WidgetRef ref, String language) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(language == 'bn' ? 'সব মুছে ফেলবেন?' : 'Clear all history?'),
        content: Text(language == 'bn'
            ? 'আগের সব স্ক্যান মুছে যাবে।'
            : 'All scan history will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(language == 'bn' ? 'না' : 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(storageServiceProvider).deleteAll();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(language == 'bn' ? 'হ্যাঁ, মুছুন' : 'Clear',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ScanHistoryModel item;
  final String language;
  final WidgetRef ref;

  const _HistoryCard(
      {required this.item, required this.language, required this.ref});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand name + date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.brandName,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontSize: 22,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  AppDateUtils.formatForDisplay(item.scannedAt),
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Generic name
            Text(
              item.genericName,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            // Summary
            Text(
              item.summary,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 16, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Play button
            OutlinedButton.icon(
              onPressed: () {
                final spoken = '${item.brandName}. ${item.summary}';
                ref.read(ttsServiceProvider).speak(spoken, language: item.language);
              },
              icon: const Icon(Icons.volume_up_rounded, size: 20),
              label: Text(language == 'bn' ? 'শুনুন' : 'Play'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: colorScheme.primary),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final String language;
  const _EmptyHistory({required this.language});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded,
              size: 80,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            language == 'bn'
                ? 'এখনো কোনো স্ক্যান নেই'
                : 'No scans yet',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}