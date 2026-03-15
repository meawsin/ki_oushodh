// lib/core/utils/date_utils.dart

import 'package:hive/hive.dart';

import '../../data/local/hive_setup.dart';
import '../../domain/models/scan_history_model.dart';

class AppDateUtils {
  AppDateUtils._();

  static const int _retentionDays = 30;

  /// Purges scan history entries older than 30 days.
  /// HiveSetup must run BEFORE this — box must already be open and typed.
  static Future<void> purgeExpiredScanHistory() async {
    final box = Hive.box<ScanHistoryModel>(HiveSetup.scanHistoryBoxName);
    if (box.isEmpty) return;

    final cutoff =
        DateTime.now().subtract(const Duration(days: _retentionDays));
    final keysToDelete = <dynamic>[];

    for (final key in box.keys) {
      final record = box.get(key);
      if (record != null && record.scannedAt.isBefore(cutoff)) {
        keysToDelete.add(key);
      }
    }

    if (keysToDelete.isNotEmpty) await box.deleteAll(keysToDelete);
  }

  /// e.g. "15 Mar 2026, 3:45 PM"
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