import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/task_completion.dart';
import '../models/daily_record.dart';
import '../models/goal.dart';

class HiveService {
  static const String tasksBox = 'tasks';
  static const String completionsBox = 'completions';
  static const String dailyRecordsBox = 'daily_records';
  static const String goalsBox = 'goals';
  static const String settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(TaskCompletionAdapter());
    Hive.registerAdapter(DailyRecordAdapter());
    Hive.registerAdapter(GoalAdapter());

    await Hive.openBox<Task>(tasksBox);
    await Hive.openBox<TaskCompletion>(completionsBox);
    await Hive.openBox<DailyRecord>(dailyRecordsBox);
    await Hive.openBox<Goal>(goalsBox);
    await Hive.openBox(settingsBox);
  }

  static Box<Task> get tasks => Hive.box<Task>(tasksBox);
  static Box<TaskCompletion> get completions => Hive.box<TaskCompletion>(completionsBox);
  static Box<DailyRecord> get dailyRecords => Hive.box<DailyRecord>(dailyRecordsBox);
  static Box<Goal> get goals => Hive.box<Goal>(goalsBox);
  static Box get settings => Hive.box(settingsBox);
}
