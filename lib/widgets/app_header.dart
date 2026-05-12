import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../screens/settings_screen.dart';

/// Custom app header matching the Stitch design.
/// Shows avatar + "StudyLink AI" title + settings icon.
/// Settings icon navigates to SettingsScreen by default.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.onSettingsTap});

  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfacePurple,
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Text(
            'StudyLink AI',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // Settings — navigates to SettingsScreen if no custom callback
          IconButton(
            onPressed: onSettingsTap ??
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
