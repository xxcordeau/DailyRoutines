import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HeatmapCell extends StatelessWidget {
  final GlobalKey cellKey;
  final double size;
  final double completionRate; // -1 = no data, 0.0-1.0 = completion rate
  final bool isSelected;
  final VoidCallback onTap;

  const HeatmapCell({
    super.key,
    required this.cellKey,
    required this.size,
    required this.completionRate,
    required this.isSelected,
    required this.onTap,
  });

  Color get _color {
    if (completionRate < 0) return AppColors.heatmapEmpty;
    if (completionRate == 0) return AppColors.heatmapEmpty;
    if (completionRate <= 0.25) return AppColors.heatmapLevel1;
    if (completionRate <= 0.50) return AppColors.heatmapLevel2;
    if (completionRate <= 0.75) return AppColors.heatmapLevel3;
    return AppColors.heatmapLevel4;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _color,
          borderRadius: BorderRadius.circular(3),
          border: isSelected
              ? Border.all(color: AppColors.textPrimary, width: 1.5)
              : null,
        ),
      ),
    );
  }
}
