import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/study_group.dart';
import '../services/recommendation_service.dart';

/// AI Recommendation card matching the Stitch design.
/// Shows match percentage badge, course tag, AI Insight,
/// member avatars, and Request to Join / View Details button.
class AiRecommendationCard extends StatelessWidget {
  const AiRecommendationCard({
    super.key,
    required this.recommendation,
    this.isTopMatch = false,
    this.onRequestJoin,
    this.onViewDetails,
  });

  final GroupRecommendation recommendation;
  final bool isTopMatch;
  final VoidCallback? onRequestJoin;
  final VoidCallback? onViewDetails;

  StudyGroup get group => recommendation.group;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTopMatch
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.cardBorder,
        ),
        boxShadow: isTopMatch
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match badge + Course tag row
          Row(
            children: [
              // Match percentage badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: isTopMatch
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        )
                      : null,
                  color: isTopMatch ? null : AppColors.surfacePurple,
                  borderRadius: BorderRadius.circular(20),
                  border: isTopMatch
                      ? null
                      : Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 14,
                      color: isTopMatch ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isTopMatch
                          ? 'Top Match: ${recommendation.score}%'
                          : '${recommendation.score}% Match',
                      style: AppTextStyles.caption.copyWith(
                        color: isTopMatch ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Course tag
              if (group.course != null && group.course!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfacePurple,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorderLight),
                  ),
                  child: Text(
                    group.course!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
          const SizedBox(height: 10),
          // AI Insight card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfacePurple,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Insight:',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _buildInsightText(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Bottom row: avatars + button
          Row(
            children: [
              // Stacked member avatars
              SizedBox(
                width: 60,
                height: 28,
                child: Stack(
                  children: List.generate(
                    group.memberIds.length.clamp(0, 3),
                    (i) => Positioned(
                      left: i * 18.0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              _avatarColors[i % _avatarColors.length],
                              _avatarColors[(i + 1) % _avatarColors.length],
                            ],
                          ),
                          border: Border.all(color: AppColors.surface, width: 2),
                        ),
                        child: const Icon(Icons.person, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              if (group.memberIds.length > 3) ...[
                const SizedBox(width: 4),
                Text(
                  '+${group.memberIds.length - 3}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                const SizedBox(width: 4),
                Text(
                  '${group.memberIds.length} Members',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const Spacer(),
              // Action button
              if (isTopMatch)
                FilledButton(
                  onPressed: onRequestJoin,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Request to Join',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white, fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                    ],
                  ),
                )
              else
                OutlinedButton(
                  onPressed: onViewDetails,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  child: Text(
                    'View Details',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary, fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildInsightText() {
    if (recommendation.matchReasons.isNotEmpty) {
      return '${recommendation.matchReasons.take(2).join('. ')}. Matches concepts from your recent scan.';
    }
    return 'This group aligns well with your scanned study material.';
  }

  static const List<Color> _avatarColors = [
    AppColors.primary,
    AppColors.primaryLight,
    Color(0xFF06B6D4),
    Color(0xFF10B981),
  ];
}
