// lib/services/storage_service.dart

import 'package:hive/hive.dart';

import '../data/local/hive_setup.dart';
import '../domain/models/scan_history_model.dart';

// ---------------------------------------------------------------------------
// StorageService
// Saves scan results to Hive. 30-day cleanup runs at app startup (main.dart).
// ---------------------------------------------------------------------------
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
    // Most recent first
    items.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return items;
  }

  Future<void> deleteAll() async => await _box.clear();
}