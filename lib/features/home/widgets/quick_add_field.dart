import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/tasks_provider.dart';

class QuickAddField extends ConsumerStatefulWidget {
  const QuickAddField({super.key});

  @override
  ConsumerState<QuickAddField> createState() => _QuickAddFieldState();
}

class _QuickAddFieldState extends ConsumerState<QuickAddField> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  bool _isRequired = false;
  bool _showMemo = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _addTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    ref.read(tasksProvider.notifier).addTask(
      title: title,
      memo: _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim(),
      isRequired: _isRequired,
      isRoutine: !_isRequired,
    );

    _titleController.clear();
    _memoController.clear();
    setState(() => _showMemo = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단: 루틴입력 + 필수 루틴 토글
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: '루틴입력',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _isRequired = !_isRequired),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '필수 루틴',
                        style: TextStyle(
                          fontSize: 13,
                          color: _isRequired
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
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

          // 메모 입력 (토글 시 표시)
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: TextField(
                controller: _memoController,
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
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                maxLines: 3,
                minLines: 1,
                autofocus: true,
              ),
            ),
            crossFadeState: _showMemo
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),

          // 구분선
          Divider(height: 1, thickness: 0.8, color: AppColors.border),

          // 하단: 메모 버튼 + 등록 하기
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Row(
              children: [
                // 메모 토글 버튼
                GestureDetector(
                  onTap: () => setState(() => _showMemo = !_showMemo),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedNote01,
                        size: 16,
                        color: _showMemo
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '메모',
                        style: TextStyle(
                          fontSize: 13,
                          color: _showMemo
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: _showMemo
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // 등록 하기 버튼
                GestureDetector(
                  onTap: _addTask,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: _titleController.text.trim().isNotEmpty
                          ? AppColors.primary
                          : AppColors.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '등록 하기',
                      style: TextStyle(
                        fontSize: 13,
                        color: _titleController.text.trim().isNotEmpty
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
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
