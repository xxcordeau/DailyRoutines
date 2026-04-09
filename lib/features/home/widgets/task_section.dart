import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TaskSectionHeader extends StatelessWidget {
  final String title;
  final String? badge;
  final int completed;
  final int total;
  final bool isCollapsible;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const TaskSectionHeader({
    super.key,
    required this.title,
    this.badge,
    required this.completed,
    required this.total,
    this.isCollapsible = false,
    this.isExpanded = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (isCollapsible) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onToggle,
              child: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
