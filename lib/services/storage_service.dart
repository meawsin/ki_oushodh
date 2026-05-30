// lib/services/storage_service.dart
//
// Key fixes vs original:
//   - Added deleteScan(key) for swipe-to-delete in history screen
//   - HiveObject.key used as the stable record identifier

import 'package:hive/hive.dart';

import '../data/local/hive_setup.dart';
import '../domain/models/scan_history_model.dart';

class StorageService {
  Box<ScanHistoryModel> get _box =>
      Hive.box<ScanHistoryModel>(HiveSetup.scanHistoryBoxName);

  Future<void> saveScan({
    required String brandName,
    required String genericName,
    required String summary,
    required String language,
  }) async {
    await _box.add(ScanHistoryModel(
      brandName: brandName,
      genericName: genericName,
      summary: summary,
      language: language,
      scannedAt: DateTime.now(),
    ));
  }

  List<ScanHistoryModel> getHistory() {
    final items = _box.values.toList();
    items.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return items;
  }

  /// Deletes a single record. HiveObject.key is a stable Hive-assigned identifier.
  Future<void> deleteScan(dynamic key) async {
    await _box.delete(key);
  }

  Future<void> deleteAll() async => await _box.clear();
}
