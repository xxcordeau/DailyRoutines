// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Task(
      id: fields[0] as String,
      title: fields[1] as String,
      memo: fields[2] as String?,
      isRequired: fields[3] as bool,
      isRoutine: fields[4] as bool,
      subItems: (fields[5] as List).cast<String>(),
      createdAt: fields[6] as DateTime,
      order: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.memo)
      ..writeByte(3)
      ..write(obj.isRequired)
      ..writeByte(4)
      ..write(obj.isRoutine)
      ..writeByte(5)
      ..write(obj.subItems)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
