// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanHistoryModelAdapter extends TypeAdapter<ScanHistoryModel> {
  @override
  final int typeId = 0;

  @override
  ScanHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanHistoryModel(
      brandName: fields[0] as String,
      genericName: fields[1] as String,
      summary: fields[2] as String,
      language: fields[3] as String,
      scannedAt: fields[4] as DateTime,
      summaryEn: fields[5] as String?,
      category: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScanHistoryModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.brandName)
      ..writeByte(1)
      ..write(obj.genericName)
      ..writeByte(2)
      ..write(obj.summary)
      ..writeByte(3)
      ..write(obj.language)
      ..writeByte(4)
      ..write(obj.scannedAt)
      ..writeByte(5)
      ..write(obj.summaryEn)
      ..writeByte(6)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
