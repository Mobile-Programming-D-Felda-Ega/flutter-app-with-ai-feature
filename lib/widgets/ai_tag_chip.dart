import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// AI tag chip — used for AI suggested tags on group form
/// and detected keywords on scan results.
class AiTagChip extends StatelessWidget {
  const AiTagChip({
    super.key,
    required this.label,
    this.isFilled = false,
    this.showAdd = false,
    this.icon,
    this.onTap,
    this.onDelete,
  });

  final String label;
  final bool isFilled;
  final bool showAdd;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFilled ? AppColors.primary : AppColors.surfacePurple,
          borderRadius: BorderRadius.circular(20),
          border: isFilled
              ? null
              : Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isFilled ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 4),
            ],
            if (showAdd) ...[
              Icon(
                Icons.add,
                size: 14,
                color: isFilled ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 2),
            ],
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isFilled ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: isFilled ? Colors.white70 : AppColors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
