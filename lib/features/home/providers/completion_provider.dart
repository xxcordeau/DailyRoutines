import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/completion_repository.dart';
import '../../../core/utils/date_utils.dart';
import 'tasks_provider.dart';

final todayCompletionsProvider =
    StateNotifierProvider<TodayCompletionsNotifier, Map<String, bool>>((ref) {
  return TodayCompletionsNotifier(ref.read(completionRepositoryProvider));
});

class TodayCompletionsNotifier extends StateNotifier<Map<String, bool>> {
  final CompletionRepository _repository;

  TodayCompletionsNotifier(this._repository) : super({}) {
    _load();
  }

  void _load() {
    state = _repository.getCompletionsForDate(AppDateUtils.today);
  }

  Future<void> toggleCompletion(String taskId) async {
    await _repository.toggleCompletion(taskId, AppDateUtils.today);
    _load();
  }

  bool isCompleted(String taskId) => state[taskId] ?? false;

  void refresh() => _load();
}

final requiredProgressProvider = Provider<({int completed, int total})>((ref) {
  final tasks = ref.watch(requiredTasksProvider);
  final completions = ref.watch(todayCompletionsProvider);

  final total = tasks.length;
  final completed = tasks.where((t) => completions[t.id] == true).length;
  return (completed: completed, total: total);
});

final routineProgressProvider = Provider<({int completed, int total})>((ref) {
  final tasks = ref.watch(routineTasksProvider);
  final completions = ref.watch(todayCompletionsProvider);

  final total = tasks.length;
  final completed = tasks.where((t) => completions[t.id] == true).length;
  return (completed: completed, total: total);
});
