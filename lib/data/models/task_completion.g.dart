// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_completion.dart';

class TaskCompletionAdapter extends TypeAdapter<TaskCompletion> {
  @override
  final int typeId = 1;

  @override
  TaskCompletion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return TaskCompletion(
      taskId: fields[0] as String,
      date: fields[1] as DateTime,
      isCompleted: fields[2] as bool,
      completedAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskCompletion obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.taskId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.isCompleted)
      ..writeByte(3)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskCompletionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
