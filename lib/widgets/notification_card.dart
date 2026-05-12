import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Notification card widget for the Alerts screen.
/// Supports different notification types with distinct icons and styles.
enum NotificationType {
  studySession,
  memberJoined,
  aiGenerated,
  fileUpload,
}

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.type,
    this.time,
    this.isUnread = false,
    this.actionLabel,
    this.onActionTap,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final NotificationType type;
  final String? time;
  final bool isUnread;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread ? AppColors.primary.withValues(alpha: 0.3) : AppColors.cardBorder,
          ),
          boxShadow: isUnread
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            _buildIcon(),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + time row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.titleMedium,
                        ),
                      ),
                      if (time != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          time!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                      if (isUnread) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (actionLabel != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: FilledButton(
                        onPressed: onActionTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        child: Text(actionLabel!),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color bgColor;
    Color iconColor;

    switch (type) {
      case NotificationType.studySession:
        iconData = Icons.notifications_outlined;
        bgColor = AppColors.surfacePurple;
        iconColor = AppColors.primary;
      case NotificationType.memberJoined:
        iconData = Icons.person_add_outlined;
        bgColor = AppColors.surfacePurple;
        iconColor = AppColors.primary;
      case NotificationType.aiGenerated:
        iconData = Icons.auto_awesome_rounded;
        bgColor = AppColors.primary;
        iconColor = Colors.white;
      case NotificationType.fileUpload:
        iconData = Icons.description_outlined;
        bgColor = AppColors.surfacePurple;
        iconColor = AppColors.primary;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor, size: 22),
    );
  }
}
