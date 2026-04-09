import '../local/hive_service.dart';
import '../models/task.dart';

class TaskRepository {
  List<Task> getAllTasks() {
    return HiveService.tasks.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<Task> getRequiredTasks() {
    return getAllTasks().where((t) => t.isRequired && !t.isRoutine).toList();
  }

  List<Task> getRoutineTasks() {
    return getAllTasks().where((t) => t.isRoutine).toList();
  }

  Future<void> addTask(Task task) async {
    await HiveService.tasks.put(task.id, task);
  }

  Future<void> updateTask(Task task) async {
    await HiveService.tasks.put(task.id, task);
  }

  Future<void> deleteTask(String taskId) async {
    await HiveService.tasks.delete(taskId);
  }

  Future<void> reorderTasks(List<Task> tasks) async {
    for (int i = 0; i < tasks.length; i++) {
      tasks[i].order = i;
      await HiveService.tasks.put(tasks[i].id, tasks[i]);
    }
  }

  // 특정 섹션 내 순서를 변경할 때 기존 order 슬롯을 유지하며 재배정
  Future<void> reorderSection(List<Task> reorderedSection) async {
    if (reorderedSection.isEmpty) return;
    final allSorted = getAllTasks();
    final sectionIds = reorderedSection.map((t) => t.id).toSet();

    final existingOrders = allSorted
        .where((t) => sectionIds.contains(t.id))
        .map((t) => t.order)
        .toList()
      ..sort();

    for (int i = 0; i < reorderedSection.length; i++) {
      reorderedSection[i].order = existingOrders[i];
      await HiveService.tasks.put(reorderedSection[i].id, reorderedSection[i]);
    }
  }

  int getNextOrder() {
    final tasks = getAllTasks();
    if (tasks.isEmpty) return 0;
    return tasks.last.order + 1;
  }
}
