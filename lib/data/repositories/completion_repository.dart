import '../local/hive_service.dart';
import '../models/task_completion.dart';
import '../models/daily_record.dart';
import '../../core/utils/date_utils.dart';

class CompletionRepository {
  Map<String, bool> getCompletionsForDate(DateTime date) {
    final normalized = AppDateUtils.normalizeDate(date);
    final dateStr = normalized.toIso8601String().substring(0, 10);
    final map = <String, bool>{};

    for (final completion in HiveService.completions.values) {
      final cDateStr = completion.date.toIso8601String().substring(0, 10);
      if (cDateStr == dateStr) {
        map[completion.taskId] = completion.isCompleted;
      }
    }
    return map;
  }

  Future<void> toggleCompletion(String taskId, DateTime date) async {
    final normalized = AppDateUtils.normalizeDate(date);
    final key = '${taskId}_${normalized.toIso8601String().substring(0, 10)}';

    final existing = HiveService.completions.get(key);
    if (existing != null) {
      existing.isCompleted = !existing.isCompleted;
      existing.completedAt = existing.isCompleted ? DateTime.now() : null;
      await existing.save();
    } else {
      final completion = TaskCompletion(
        taskId: taskId,
        date: normalized,
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      await HiveService.completions.put(key, completion);
    }
  }

  Future<void> setCompletion(String taskId, DateTime date, bool value) async {
    final normalized = AppDateUtils.normalizeDate(date);
    final key = '${taskId}_${normalized.toIso8601String().substring(0, 10)}';

    final existing = HiveService.completions.get(key);
    if (existing != null) {
      existing.isCompleted = value;
      existing.completedAt = value ? DateTime.now() : null;
      await existing.save();
    } else {
      final completion = TaskCompletion(
        taskId: taskId,
        date: normalized,
        isCompleted: value,
        completedAt: value ? DateTime.now() : null,
      );
      await HiveService.completions.put(key, completion);
    }
  }

  Future<void> saveDailyRecord(DateTime date, int total, int completed) async {
    final normalized = AppDateUtils.normalizeDate(date);
    final key = normalized.toIso8601String().substring(0, 10);

    final record = DailyRecord(
      date: normalized,
      totalTasks: total,
      completedTasks: completed,
    );
    await HiveService.dailyRecords.put(key, record);
  }

  Map<String, DailyRecord> getAllDailyRecords() {
    final map = <String, DailyRecord>{};
    for (final record in HiveService.dailyRecords.values) {
      map[record.dateKey] = record;
    }
    return map;
  }

  Future<void> deleteCompletionsForTask(String taskId) async {
    final keysToDelete = <String>[];
    for (final entry in HiveService.completions.toMap().entries) {
      if (entry.value.taskId == taskId) {
        keysToDelete.add(entry.key as String);
      }
    }
    for (final key in keysToDelete) {
      await HiveService.completions.delete(key);
    }
  }
}
