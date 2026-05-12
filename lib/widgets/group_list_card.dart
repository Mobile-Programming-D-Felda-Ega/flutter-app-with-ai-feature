import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/study_group.dart';

/// Discovery-style group list card matching the Stitch design.
/// Shows course tag, AI Recommended badge, member count,
/// title, description, schedule, location, and Join button.
class GroupListCard extends StatelessWidget {
  const GroupListCard({
    super.key,
    required this.group,
    this.isAiRecommended = false,
    this.maxMembers = 10,
    this.onJoin,
    this.onTap,
  });

  final StudyGroup group;
  final bool isAiRecommended;
  final int maxMembers;
  final VoidCallback? onJoin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: tags + member count
            Row(
              children: [
                // Course tag
                if (group.course != null && group.course!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      group.course!,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isAiRecommended) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfacePurple,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'AI Recommended',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                // Member count
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.group_outlined, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${group.memberIds.length}/$maxMembers',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Title
            Text(
              group.subjectName,
              style: AppTextStyles.headlineSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Description
            Text(
              group.description,
              style: AppTextStyles.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            // Schedule + Location
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 15, color: AppColors.textTertiary),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    _formatSchedule(group.scheduledAt),
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    group.location,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Join button
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onJoin,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontSize: 13),
                ),
                child: const Text('Join Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSchedule(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final day = days[dt.weekday - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${day}s $hour:$min $period';
  }
}
