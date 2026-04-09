import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/goal.dart';
import '../../../data/local/hive_service.dart';
import '../../../core/utils/id_generator.dart';

final goalProvider = StateNotifierProvider<GoalNotifier, Goal?>((ref) {
  return GoalNotifier();
});

class GoalNotifier extends StateNotifier<Goal?> {
  GoalNotifier() : super(null) {
    _load();
  }

  void _load() {
    final goals = HiveService.goals.values.toList();
    if (goals.isNotEmpty) {
      state = goals.where((g) => !g.isCompleted).firstOrNull ?? goals.last;
    }
  }

  Future<void> addGoal({required String title, String? subtitle}) async {
    final goal = Goal(
      id: IdGenerator.generate(),
      title: title,
      subtitle: subtitle,
    );
    await HiveService.goals.put(goal.id, goal);
    state = goal;
  }

  Future<void> completeGoal() async {
    if (state != null) {
      state!.isCompleted = true;
      await state!.save();
      _load();
    }
  }

  Future<void> deleteGoal() async {
    if (state != null) {
      await HiveService.goals.delete(state!.id);
      _load();
    }
  }
}
