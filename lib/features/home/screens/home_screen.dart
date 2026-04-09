import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/completion_repository.dart';
import '../../../core/utils/date_utils.dart';
import '../providers/tasks_provider.dart';
import '../providers/completion_provider.dart';
import '../widgets/home_header.dart';
import '../widgets/quick_add_field.dart';
import '../widgets/task_section.dart';
import '../widgets/task_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  bool _routineExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveDailyRecord();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveDailyRecord();
    }
    if (state == AppLifecycleState.resumed) {
      ref.read(tasksProvider.notifier).refresh();
      ref.read(todayCompletionsProvider.notifier).refresh();
    }
  }

  void _saveDailyRecord() {
    final allTasks = ref.read(tasksProvider);
    final completions = ref.read(todayCompletionsProvider);
    final total = allTasks.length;
    final completed =
        allTasks.where((t) => completions[t.id] == true).length;
    if (total > 0) {
      CompletionRepository()
          .saveDailyRecord(AppDateUtils.today, total, completed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requiredTasks = ref.watch(requiredTasksProvider);
    final routineTasks = ref.watch(routineTasksProvider);
    final completions = ref.watch(todayCompletionsProvider);
    final routProgress = ref.watch(routineProgressProvider);

    final uncompletedRequired =
        requiredTasks.where((t) => completions[t.id] != true).toList();
    final completedRequired =
        requiredTasks.where((t) => completions[t.id] == true).toList();
    final uncompletedRoutine =
        routineTasks.where((t) => completions[t.id] != true).toList();
    final completedRoutine =
        routineTasks.where((t) => completions[t.id] == true).toList();

    final allCompleted = [...completedRequired, ...completedRoutine];

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: const HomeHeader()),
          SliverToBoxAdapter(child: const QuickAddField()),

          // 필수 루틴
          if (uncompletedRequired.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: TaskSectionHeader(
                title: '필수 루틴',
                completed: 0,
                total: uncompletedRequired.length,
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    TaskCard(task: uncompletedRequired[index]),
                childCount: uncompletedRequired.length,
              ),
            ),
          ],

          // 평소 루틴
          if (routineTasks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: TaskSectionHeader(
                title: '평소 루틴',
                completed: routProgress.completed,
                total: routProgress.total,
                isCollapsible: true,
                isExpanded: _routineExpanded,
                onToggle: () =>
                    setState(() => _routineExpanded = !_routineExpanded),
              ),
            ),
            if (_routineExpanded && uncompletedRoutine.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      TaskCard(task: uncompletedRoutine[index]),
                  childCount: uncompletedRoutine.length,
                ),
              ),
          ],

          // 완료 루틴
          if (allCompleted.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: TaskSectionHeader(
                title: '완료 루틴',
                completed: allCompleted.length,
                total: allCompleted.length,
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => TaskCard(task: allCompleted[index]),
                childCount: allCompleted.length,
              ),
            ),
          ],

          // 아무것도 없을 때
          if (requiredTasks.isEmpty && routineTasks.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Text(
                  '할일을 추가해보세요!',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
