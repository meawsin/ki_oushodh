// lib/domain/models/scan_history_model.dart

import 'package:hive/hive.dart';

part 'scan_history_model.g.dart';

@HiveType(typeId: 0)
class ScanHistoryModel extends HiveObject {
  @HiveField(0)
  final String brandName;

  @HiveField(1)
  final String genericName;

  @HiveField(2)
  final String summary;

  @HiveField(3)
  final String language;

  @HiveField(4)
  final DateTime scannedAt;

  ScanHistoryModel({
    required this.brandName,
    required this.genericName,
    required this.summary,
    required this.language,
    required this.scannedAt,
  });
}