import 'package:hive/hive.dart';

part 'daily_record.g.dart';

@HiveType(typeId: 2)
class DailyRecord extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  int totalTasks;

  @HiveField(2)
  int completedTasks;

  DailyRecord({
    required this.date,
    this.totalTasks = 0,
    this.completedTasks = 0,
  });

  double get completionRate =>
      totalTasks > 0 ? completedTasks / totalTasks : 0.0;

  String get dateKey => date.toIso8601String().substring(0, 10);
}
