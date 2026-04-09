import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/repositories/completion_repository.dart';
import '../../../core/utils/id_generator.dart';

final taskRepositoryProvider = Provider((ref) => TaskRepository());
final completionRepositoryProvider = Provider((ref) => CompletionRepository());

final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  return TasksNotifier(ref.read(taskRepositoryProvider));
});

class TasksNotifier extends StateNotifier<List<Task>> {
  final TaskRepository _repository;

  TasksNotifier(this._repository) : super([]) {
    _load();
  }

  void _load() {
    state = _repository.getAllTasks();
  }

  Future<void> addTask({
    required String title,
    String? memo,
    bool isRequired = true,
    bool isRoutine = false,
    List<String>? subItems,
  }) async {
    final task = Task(
      id: IdGenerator.generate(),
      title: title,
      memo: memo,
      isRequired: isRequired,
      isRoutine: isRoutine,
      subItems: subItems,
      order: _repository.getNextOrder(),
    );
    await _repository.addTask(task);
    _load();
  }

  Future<void> updateTask(Task task) async {
    await _repository.updateTask(task);
    _load();
  }

  Future<void> deleteTask(String taskId) async {
    await _repository.deleteTask(taskId);
    _load();
  }

  Future<void> reorderTasks(List<Task> tasks) async {
    await _repository.reorderTasks(tasks);
    _load();
  }

  void refresh() => _load();
}

final requiredTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider);
  return tasks.where((t) => t.isRequired && !t.isRoutine).toList();
});

final routineTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider);
  return tasks.where((t) => t.isRoutine).toList();
});
