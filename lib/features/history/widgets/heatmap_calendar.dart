import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/daily_record.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/completion_repository.dart';

class HeatmapCalendar extends StatefulWidget {
  final Map<String, DailyRecord> records;
  final List<Task> tasks;

  const HeatmapCalendar({
    super.key,
    required this.records,
    required this.tasks,
  });

  @override
  State<HeatmapCalendar> createState() => _HeatmapCalendarState();
}

class _HeatmapCalendarState extends State<HeatmapCalendar> {
  final ScrollController _scrollController = ScrollController();
  _TooltipInfo? _tooltip;

  static const double cellSize = 28;
  static const double cellGap = 4;
  static const double cellStep = cellSize + cellGap;
  static const double monthLabelH = 22;
  static const double dayLabelW = 22;
  static const List<String> dayLabels = ['일', '월', '화', '수', '목', '금', '토'];

  // 총 그리드 높이: 월 라벨 + 7행
  static const double gridHeight = monthLabelH + 7 * cellStep;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<List<DateTime?>> _buildColumns() {
    final today = AppDateUtils.today;
    final daysToSat = 6 - today.weekday % 7;
    final endDate = today.add(Duration(days: daysToSat));
    final startDate = endDate.subtract(const Duration(days: 7 * 52 - 1));

    final columns = <List<DateTime?>>[];
    var current = startDate;

    while (!current.isAfter(endDate)) {
      final week = <DateTime?>[];
      for (int d = 0; d < 7; d++) {
        final day = current.add(Duration(days: d));
        week.add(day.isAfter(today) ? null : day);
      }
      columns.add(week);
      current = current.add(const Duration(days: 7));
    }
    return columns;
  }

  Color _cellColor(DateTime? date) {
    if (date == null) return Colors.transparent;
    final key = date.toIso8601String().substring(0, 10);
    final r = widget.records[key];
    if (r == null) return AppColors.heatmapEmpty;
    final rate = r.completionRate;
    if (rate <= 0) return AppColors.heatmapEmpty;
    if (rate <= 0.25) return AppColors.heatmapLevel1;
    if (rate <= 0.50) return AppColors.heatmapLevel2;
    if (rate <= 0.75) return AppColors.heatmapLevel3;
    return AppColors.heatmapLevel4;
  }

  String? _monthLabel(List<DateTime?> week, int colIdx) {
    final first = week.firstWhere((d) => d != null, orElse: () => null);
    if (first == null) return null;
    if (first.day <= 7 || colIdx == 0) {
      return DateFormat('M월').format(first);
    }
    return null;
  }

  void _onCellTap(DateTime date) {
    final key = date.toIso8601String().substring(0, 10);
    final record = widget.records[key];
    final completions = CompletionRepository().getCompletionsForDate(date);
    setState(() {
      _tooltip = _TooltipInfo(
        date: date,
        percent: record != null ? (record.completionRate * 100).toInt() : 0,
        hasRecord: record != null,
        completions: completions,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final columns = _buildColumns();
    final totalW = columns.length * cellStep;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 그리드 (요일 고정 라벨 + 가로 스크롤)
        SizedBox(
          height: gridHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 요일 라벨 (좌측 고정)
              Column(
                children: [
                  SizedBox(height: monthLabelH), // 월 라벨 공간
                  ...dayLabels.map(
                    (label) => SizedBox(
                      width: dayLabelW,
                      height: cellStep,
                      child: Center(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              // 가로 스크롤 그리드
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalW,
                    height: gridHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 월 라벨 행
                        SizedBox(
                          height: monthLabelH,
                          width: totalW,
                          child: Stack(
                            children: [
                              for (int i = 0; i < columns.length; i++)
                                if (_monthLabel(columns[i], i) != null)
                                  Positioned(
                                    left: i * cellStep,
                                    child: Text(
                                      _monthLabel(columns[i], i)!,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                        // 셀 그리드
                        SizedBox(
                          height: 7 * cellStep,
                          width: totalW,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int col = 0; col < columns.length; col++)
                                _buildColumn(columns[col], col),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 범례 + 툴팁 (한 줄)
        const SizedBox(height: 14),
        Row(
          children: [
            const Text('적음',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(width: 6),
            _LegendCell(color: AppColors.heatmapEmpty),
            _LegendCell(color: AppColors.heatmapLevel1),
            _LegendCell(color: AppColors.heatmapLevel2),
            _LegendCell(color: AppColors.heatmapLevel3),
            _LegendCell(color: AppColors.heatmapLevel4),
            const SizedBox(width: 6),
            const Text('많음',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            if (_tooltip != null) ...[
              const SizedBox(width: 10),
              _TooltipBadge(info: _tooltip!),
            ],
          ],
        ),
        // 날짜별 태스크 상세 카드
        if (_tooltip != null && widget.tasks.isNotEmpty) ...[
          const SizedBox(height: 16),
          _DayDetailCard(
            info: _tooltip!,
            tasks: widget.tasks,
          ),
        ],
      ],
    );
  }

  Widget _buildColumn(List<DateTime?> week, int colIdx) {
    return SizedBox(
      width: cellStep,
      child: Column(
        children: week.map((date) => _buildCell(date)).toList(),
      ),
    );
  }

  Widget _buildCell(DateTime? date) {
    final color = _cellColor(date);
    final isSelected = _tooltip != null &&
        date != null &&
        AppDateUtils.isSameDay(date, _tooltip!.date);

    return GestureDetector(
      onTapDown: date != null ? (_) => _onCellTap(date) : null,
      child: Container(
        width: cellSize,
        height: cellSize,
        margin: const EdgeInsets.only(bottom: cellGap, right: cellGap),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
          border: isSelected
              ? Border.all(color: AppColors.textPrimary, width: 1.5)
              : null,
        ),
      ),
    );
  }
}

class _TooltipInfo {
  final DateTime date;
  final int percent;
  final bool hasRecord;
  final Map<String, bool> completions;
  _TooltipInfo({
    required this.date,
    required this.percent,
    required this.hasRecord,
    required this.completions,
  });
}

class _DayDetailCard extends StatelessWidget {
  final _TooltipInfo info;
  final List<Task> tasks;

  const _DayDetailCard({required this.info, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final done = tasks.where((t) => info.completions[t.id] == true).toList();
    final notDone = tasks.where((t) => info.completions[t.id] != true).toList();
    final dateStr = DateFormat('yy.MM.dd (E)', 'ko').format(info.date);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (done.isNotEmpty) ...[
            _SectionLabel(label: '완료', color: AppColors.primary),
            const SizedBox(height: 6),
            ...done.map((t) => _TaskRow(title: t.title, done: true)),
            const SizedBox(height: 10),
          ],
          if (notDone.isNotEmpty) ...[
            _SectionLabel(label: '미완료', color: AppColors.textSecondary),
            const SizedBox(height: 6),
            ...notDone.map((t) => _TaskRow(title: t.title, done: false)),
          ],
          if (done.isEmpty && notDone.isEmpty)
            const Text(
              '기록된 루틴이 없습니다',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String title;
  final bool done;
  const _TaskRow({required this.title, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 15,
            color: done ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: done ? AppColors.textPrimary : AppColors.textSecondary,
                decoration: done ? TextDecoration.none : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TooltipBadge extends StatelessWidget {
  final _TooltipInfo info;
  const _TooltipBadge({required this.info});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yy.MM.dd').format(info.date);
    final label =
        info.hasRecord ? '$dateStr  ${info.percent}%완료' : '$dateStr  기록 없음';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500)),
    );
  }
}

class _LegendCell extends StatelessWidget {
  final Color color;
  const _LegendCell({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(3)),
    );
  }
}
