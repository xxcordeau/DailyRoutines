// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_record.dart';

class DailyRecordAdapter extends TypeAdapter<DailyRecord> {
  @override
  final int typeId = 2;

  @override
  DailyRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return DailyRecord(
      date: fields[0] as DateTime,
      totalTasks: fields[1] as int,
      completedTasks: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DailyRecord obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.totalTasks)
      ..writeByte(2)
      ..write(obj.completedTasks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
