import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/task.dart';
import '../../../data/local/hive_service.dart';
import '../../home/providers/tasks_provider.dart';

class TaskEditScreen extends ConsumerStatefulWidget {
  final String? taskId;

  const TaskEditScreen({super.key, this.taskId});

  @override
  ConsumerState<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends ConsumerState<TaskEditScreen> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _subItemControllers = <TextEditingController>[];
  bool _isRequired = true;
  bool _isRoutine = false;
  Task? _existingTask;

  bool get isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _existingTask = HiveService.tasks.get(widget.taskId);
      if (_existingTask != null) {
        _titleController.text = _existingTask!.title;
        _memoController.text = _existingTask!.memo ?? '';
        _isRequired = _existingTask!.isRequired;
        _isRoutine = _existingTask!.isRoutine;
        for (final item in _existingTask!.subItems) {
          _subItemControllers.add(TextEditingController(text: item));
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    for (final c in _subItemControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addSubItem() {
    setState(() {
      _subItemControllers.add(TextEditingController());
    });
  }

  void _removeSubItem(int index) {
    setState(() {
      _subItemControllers[index].dispose();
      _subItemControllers.removeAt(index);
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final subItems = _subItemControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final memo =
        _memoController.text.trim().isEmpty ? null : _memoController.text.trim();

    if (isEditing && _existingTask != null) {
      final updated = _existingTask!.copyWith(
        title: title,
        memo: memo,
        isRequired: _isRequired,
        isRoutine: _isRoutine,
        subItems: subItems,
      );
      ref.read(tasksProvider.notifier).updateTask(updated);
    } else {
      ref.read(tasksProvider.notifier).addTask(
        title: title,
        memo: memo,
        isRequired: _isRequired,
        isRoutine: _isRoutine,
        subItems: subItems,
      );
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '할일 수정' : '할일 추가'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              '저장',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '할일을 입력하세요',
              ),
              autofocus: !isEditing,
            ),
            const SizedBox(height: 16),

            // Memo
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: '메모',
                hintText: '메모를 입력하세요',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Task Type
            const Text(
              '유형',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeChip(
                  label: '필수 할일',
                  isSelected: _isRequired && !_isRoutine,
                  onTap: () => setState(() {
                    _isRequired = true;
                    _isRoutine = false;
                  }),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: '평소 루틴',
                  isSelected: _isRoutine,
                  onTap: () => setState(() {
                    _isRequired = false;
                    _isRoutine = true;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sub Items
            Row(
              children: [
                const Text(
                  '세부 항목',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addSubItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('추가'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._subItemControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: '항목 ${index + 1}',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeSubItem(index),
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
