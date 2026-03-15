// lib/data/local/hive_setup.dart

import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/models/scan_history_model.dart';

class HiveSetup {
  HiveSetup._();
  static const String scanHistoryBoxName = 'scan_history';

  static Future<void> registerAdaptersAndOpenBoxes() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ScanHistoryModelAdapter());
    }
    await Hive.openBox<ScanHistoryModel>(scanHistoryBoxName);
  }
}