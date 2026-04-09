import 'package:hive/hive.dart';

part 'task_completion.g.dart';

@HiveType(typeId: 1)
class TaskCompletion extends HiveObject {
  @HiveField(0)
  final String taskId;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  bool isCompleted;

  @HiveField(3)
  DateTime? completedAt;

  TaskCompletion({
    required this.taskId,
    required this.date,
    this.isCompleted = false,
    this.completedAt,
  });

  String get compositeKey => '${taskId}_${date.toIso8601String().substring(0, 10)}';
}
