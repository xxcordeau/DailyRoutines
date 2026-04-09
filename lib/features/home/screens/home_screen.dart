import '../../history/providers/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/widget_helper.dart';
import '../../../data/local/hive_service.dart';
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
    _updateLastDate();
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
      _updateLastDate();
    }
    if (state == AppLifecycleState.resumed) {
      _checkDateChange();
      ref.read(tasksProvider.notifier).refresh();
    }
  }

  // 자정을 넘겨 날짜가 바뀌었으면 오늘 루틴 리셋, 필수 루틴은 이월
  void _checkDateChange() {
    final lastDateStr =
        HiveService.settings.get('lastDate', defaultValue: '') as String;
    final todayStr = AppDateUtils.today.toIso8601String().substring(0, 10);

    if (lastDateStr.isNotEmpty && lastDateStr != todayStr) {
      final lastDate = DateTime.parse(lastDateStr);
      final diff = AppDateUtils.today.difference(lastDate).inDays;
      if (diff == 1) {
        // 정확히 하루 경과: 필수 루틴 완료 상태 이월
        _carryOverRequiredTasks(lastDate);
      }
      ref.read(todayCompletionsProvider.notifier).refresh();
    }
    _updateLastDate();
  }

  // 어제 완료된 필수 루틴을 오늘 날짜로 복사
  Future<void> _carryOverRequiredTasks(DateTime yesterday) async {
    final repo = CompletionRepository();
    final yesterdayCompletions = repo.getCompletionsForDate(yesterday);
    final requiredTasks = ref.read(requiredTasksProvider);
    for (final task in requiredTasks) {
      if (yesterdayCompletions[task.id] == true) {
        await repo.setCompletion(task.id, AppDateUtils.today, true);
      }
    }
  }

  void _updateLastDate() {
    final today = AppDateUtils.today.toIso8601String().substring(0, 10);
    HiveService.settings.put('lastDate', today);
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
      ref.read(historyProvider.notifier).refresh();
    }
  }

  // 완료 상태 변경 시 iOS 위젯 데이터 갱신
  void _refreshWidget() {
    final allTasks = ref.read(tasksProvider);
    final completions = ref.read(todayCompletionsProvider);
    final total = allTasks.length;
    final completed =
        allTasks.where((t) => completions[t.id] == true).length;
    updateHomeWidget(completed: completed, total: total);
  }

  void _onReorderRequired(int oldIndex, int newIndex, List<dynamic> tasks) {
    if (newIndex > oldIndex) newIndex--;
    final list = [...tasks];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    ref.read(tasksProvider.notifier).reorderSection(list.cast());
  }

  void _onReorderRoutine(int oldIndex, int newIndex, List<dynamic> tasks) {
    if (newIndex > oldIndex) newIndex--;
    final list = [...tasks];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    ref.read(tasksProvider.notifier).reorderSection(list.cast());
  }

  @override
  Widget build(BuildContext context) {
    // 완료 상태 변경마다 위젯 갱신
    ref.listen<Map<String, bool>>(todayCompletionsProvider, (_, __) {
      _refreshWidget();
    });

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
          const SliverToBoxAdapter(child: HomeHeader()),
          const SliverToBoxAdapter(child: QuickAddField()),

          // 필수 루틴 (드래그 가능)
          if (uncompletedRequired.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: TaskSectionHeader(
                title: '필수 루틴',
                completed: 0,
                total: uncompletedRequired.length,
              ),
            ),
            SliverReorderableList(
              itemCount: uncompletedRequired.length,
              itemBuilder: (context, index) {
                final task = uncompletedRequired[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(task.id),
                  index: index,
                  child: TaskCard(task: task),
                );
              },
              onReorder: (oldIndex, newIndex) =>
                  _onReorderRequired(oldIndex, newIndex, uncompletedRequired),
            ),
          ],

          // 평소 루틴 (드래그 가능)
          if (routineTasks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: TaskSectionHeader(
                title: '오늘 루틴',
                completed: routProgress.completed,
                total: routProgress.total,
                isCollapsible: true,
                isExpanded: _routineExpanded,
                onToggle: () =>
                    setState(() => _routineExpanded = !_routineExpanded),
              ),
            ),
            if (_routineExpanded && uncompletedRoutine.isNotEmpty)
              SliverReorderableList(
                itemCount: uncompletedRoutine.length,
                itemBuilder: (context, index) {
                  final task = uncompletedRoutine[index];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(task.id),
                    index: index,
                    child: TaskCard(task: task),
                  );
                },
                onReorder: (oldIndex, newIndex) =>
                    _onReorderRoutine(oldIndex, newIndex, uncompletedRoutine),
              ),
          ],

          // 완료 루틴 (드래그 없음)
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
                (context, index) => TaskCard(
                  key: ValueKey(allCompleted[index].id),
                  task: allCompleted[index],
                ),
                childCount: allCompleted.length,
              ),
            ),
          ],

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
