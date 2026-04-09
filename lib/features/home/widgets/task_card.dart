import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/task.dart';
import '../providers/tasks_provider.dart';
import '../providers/completion_provider.dart';

class TaskCard extends ConsumerStatefulWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> {
  bool _expanded = false;
  bool _isEditing = false;

  bool get _hasDetail =>
      (widget.task.memo != null && widget.task.memo!.isNotEmpty) ||
      widget.task.subItems.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return _InlineEditCard(
        task: widget.task,
        onSave: (updated) async {
          await ref.read(tasksProvider.notifier).updateTask(updated);
          setState(() => _isEditing = false);
        },
        onCancel: () => setState(() => _isEditing = false),
      );
    }

    final completions = ref.watch(todayCompletionsProvider);
    final isCompleted = completions[widget.task.id] ?? false;
    final showCoralBorder = _expanded && _hasDetail;

    return GestureDetector(
      onTap: _hasDetail ? () => setState(() => _expanded = !_expanded) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: showCoralBorder
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.055),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 체크박스
                  GestureDetector(
                    onTap: () => ref
                        .read(todayCompletionsProvider.notifier)
                        .toggleCompletion(widget.task.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.primary
                            : const Color(0xFFDDDDDD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.check, size: 14,
                          color: isCompleted
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.55)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 제목
                  Expanded(
                    child: Text(
                      widget.task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isCompleted
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.textSecondary,
                        decorationThickness: 1.5,
                      ),
                    ),
                  ),
                  // 수정 (인라인)
                  GestureDetector(
                    onTap: () => setState(() {
                      _isEditing = true;
                      _expanded = false;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedPencilEdit01,
                        size: 17,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  // 삭제
                  GestureDetector(
                    onTap: () => _showDeleteDialog(context),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        size: 17,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              // 펼쳤을 때 상세 내용
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: _DetailContent(task: widget.task),
                crossFadeState: _expanded && _hasDetail
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
              ),
              // ··· 하단 가운데 (접힌 상태 + 내용 있을 때)
              if (_hasDetail && !_expanded) ...[
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    '···',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: const Text('삭제'),
        content: Text("'${widget.task.title}'을(를) 삭제할까요?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(tasksProvider.notifier).deleteTask(widget.task.id);
              Navigator.pop(ctx);
            },
            style:
                TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

// ─── 인라인 편집 카드 ─────────────────────────────────────────

class _InlineEditCard extends StatefulWidget {
  final Task task;
  final Future<void> Function(Task updated) onSave;
  final VoidCallback onCancel;

  const _InlineEditCard({
    required this.task,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_InlineEditCard> createState() => _InlineEditCardState();
}

class _InlineEditCardState extends State<_InlineEditCard> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _memoCtrl;
  late final List<TextEditingController> _subCtrls;
  late bool _isRequired;
  bool _showMemo = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _memoCtrl = TextEditingController(text: widget.task.memo ?? '');
    _subCtrls = widget.task.subItems
        .map((s) => TextEditingController(text: s))
        .toList();
    _isRequired = widget.task.isRequired;
    _showMemo = widget.task.memo?.isNotEmpty == true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    for (final c in _subCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addSubItem() {
    setState(() => _subCtrls.add(TextEditingController()));
  }

  void _removeSubItem(int i) {
    setState(() {
      _subCtrls[i].dispose();
      _subCtrls.removeAt(i);
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);

    final updated = widget.task.copyWith(
      title: title,
      memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
      isRequired: _isRequired,
      isRoutine: !_isRequired,
      subItems: _subCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
    );
    await widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 제목 + 필수 토글
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '루틴입력',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _isRequired = !_isRequired),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '필수',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isRequired
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Transform.scale(
                        scale: 0.72,
                        alignment: Alignment.centerRight,
                        child: Switch(
                          value: _isRequired,
                          onChanged: (v) => setState(() => _isRequired = v),
                          activeThumbColor: Colors.white,
                          activeTrackColor: AppColors.primary,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: AppColors.border,
                          trackOutlineColor: WidgetStateProperty.resolveWith(
                            (states) => Colors.transparent,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 메모 입력 (토글 시)
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: TextField(
                controller: _memoCtrl,
                decoration: InputDecoration(
                  hintText: '메모를 입력하세요...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
                maxLines: 2,
                minLines: 1,
              ),
            ),
            crossFadeState: _showMemo
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),

          // 서브아이템
          if (_subCtrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Column(
                children: [
                  for (int i = 0; i < _subCtrls.length; i++)
                    Row(
                      children: [
                        const Text('• ',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                        Expanded(
                          child: TextField(
                            controller: _subCtrls[i],
                            decoration: InputDecoration(
                              hintText: '항목 ${i + 1}',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.5)),
                            ),
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _removeSubItem(i),
                          child: Icon(Icons.close,
                              size: 16, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                ],
              ),
            ),

          // 구분선
          Divider(height: 1, thickness: 0.8, color: AppColors.border),

          // 하단 액션
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Row(
              children: [
                // 메모 토글
                GestureDetector(
                  onTap: () => setState(() => _showMemo = !_showMemo),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedNote01,
                        size: 15,
                        color: _showMemo
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text('메모',
                          style: TextStyle(
                            fontSize: 12,
                            color: _showMemo
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: _showMemo
                                ? FontWeight.w600
                                : FontWeight.normal,
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // 세부 항목 추가
                GestureDetector(
                  onTap: _addSubItem,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedAddCircle,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text('항목',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Spacer(),
                // 취소
                GestureDetector(
                  onTap: widget.onCancel,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('취소',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                  ),
                ),
                // 저장
                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _saving ? '저장 중...' : '저장',
                      style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 상세 내용 (서브아이템 + 메모) ────────────────────────────

class _DetailContent extends StatelessWidget {
  final Task task;
  const _DetailContent({required this.task});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.memo != null && task.memo!.isNotEmpty) ...[
            Text(task.memo!,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            if (task.subItems.isNotEmpty) const SizedBox(height: 6),
          ],
          ...task.subItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  Expanded(
                    child: Text(item,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
