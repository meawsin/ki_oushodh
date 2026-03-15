import 'package:hive/hive.dart';

import '../../data/local/hive_setup.dart';

// ---------------------------------------------------------------------------
// AppDateUtils
//
// Utility functions related to date/time operations.
// Primary responsibility: enforce the 30-day auto-deletion rule (PRD §4, Step 8).
// Called once on every app startup from main().
// ---------------------------------------------------------------------------
class AppDateUtils {
  AppDateUtils._();

  static const int _retentionDays = 30;

  /// Scans the Hive scan history box and deletes any entry whose stored
  /// [DateTime] timestamp is older than [_retentionDays] days.
  ///
  /// This is intentionally a lightweight operation — it only reads timestamps,
  /// not full record payloads — so it is safe to await in main() before runApp.
  static Future<void> purgeExpiredScanHistory() async {
    final box = Hive.box<dynamic>(HiveSetup.scanHistoryBoxName);

    if (box.isEmpty) return;

    final cutoff = DateTime.now().subtract(const Duration(days: _retentionDays));
    final keysToDelete = <dynamic>[];

    for (final key in box.keys) {
      final record = box.get(key);

      // Once the ScanHistoryModel is implemented (Phase 3), replace the
      // dynamic cast below with: record.timestamp.isBefore(cutoff)
      if (record is Map && record.containsKey('timestamp')) {
        final rawTimestamp = record['timestamp'];
        if (rawTimestamp is String) {
          final timestamp = DateTime.tryParse(rawTimestamp);
          if (timestamp != null && timestamp.isBefore(cutoff)) {
            keysToDelete.add(key);
          }
        }
      }
    }

    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }
  }

  /// Formats a [DateTime] into a human-readable string for display
  /// in the scan history screen.
  /// Example output: "15 Mar 2026, 03:45 PM"
  static String formatForDisplay(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';

    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $period';
  }
}