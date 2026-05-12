import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/user_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import 'assistant_screen.dart';

/// Profile screen — dynamically loads user info and joined groups from Firestore.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userProvider = context.watch<UserProvider>();
    final appUser = userProvider.appUser;

    final displayName =
        appUser?.name ?? user?.displayName ?? 'Student';
    final email = appUser?.email ?? user?.email ?? '';
    final university = appUser?.university ?? '';
    final major = appUser?.major ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(),
              const SizedBox(height: 16),
              // Avatar with AI badge
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.15),
                            AppColors.primaryLight.withValues(alpha: 0.1),
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.cardBorder,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 52,
                        color: AppColors.primary,
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(displayName, style: AppTextStyles.headlineLarge),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  university.isNotEmpty ? university : email,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              const SizedBox(height: 14),
              // Dynamic achievement chips from user profile
              Center(
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (major.isNotEmpty)
                      _buildAchievementChip(major),
                    if (university.isNotEmpty)
                      _buildAchievementChip(university),
                    if (major.isEmpty && university.isEmpty)
                      _buildAchievementChip('StudyLink Member'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // My Joined Groups — dynamic from Firestore
              SectionHeader(
                title: 'My Joined Groups',
                actionText:
                    userProvider.joinedGroups.isNotEmpty ? 'View All' : null,
                onActionTap: () {},
              ),
              const SizedBox(height: 12),
              _buildJoinedGroupsSection(context, userProvider),
              const SizedBox(height: 24),
              // Study Preferences — synced to Firestore
              _buildPreferencesSection(context, userProvider),
              const SizedBox(height: 20),
              // Log Out
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      userProvider.clear();
                      await FirebaseAuth.instance.signOut();
                    },
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.error),
                    label: Text(
                      'Log Out',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.error, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  /// Dynamic joined groups — shows empty state or real group cards.
  Widget _buildJoinedGroupsSection(
    BuildContext context,
    UserProvider userProvider,
  ) {
    if (userProvider.isLoading) {
      return const SizedBox(
        height: 145,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final groups = userProvider.joinedGroups;

    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.surfacePurple,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorderLight),
          ),
          child: const EmptyState(
            icon: Icons.group_outlined,
            title: 'No joined groups yet',
            subtitle:
                'Discover study groups and join one\nto see them here.',
          ),
        ),
      );
    }

    return SizedBox(
      height: 145,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: groups.length + 1, // +1 for AI assistant card
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          // Last card: AI Study Assistant shortcut
          if (index == groups.length) {
            return _buildGroupMiniCard(
              icon: Icons.auto_awesome,
              iconColor: AppColors.primary,
              title: 'AI Study Assistant',
              subtitle: 'Chat with AI',
              members: 0,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      backgroundColor: AppColors.background,
                      appBar: AppBar(
                        title: const Text('AI Study Assistant'),
                      ),
                      body: const AssistantScreen(),
                    ),
                  ),
                );
              },
            );
          }

          final group = groups[index];
          return _buildGroupMiniCard(
            icon: _iconForCourse(group.course),
            iconColor: index.isEven ? AppColors.primary : AppColors.primaryLight,
            title: group.subjectName,
            subtitle: group.course ?? group.description,
            members: group.memberIds.length,
          );
        },
      ),
    );
  }

  /// Study Preferences — synced to Firestore via UserProvider.
  Widget _buildPreferencesSection(
    BuildContext context,
    UserProvider userProvider,
  ) {
    final prefs = userProvider.preferences;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Study Preferences',
                style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            _buildPreferenceTile(
              icon: Icons.notifications_active_rounded,
              title: 'Study Session Alerts',
              subtitle: 'Notify me when groups are active',
              value: prefs.sessionAlerts,
              onChanged: (v) => userProvider.updatePreferences(
                prefs.copyWith(sessionAlerts: v),
              ),
            ),
            const Divider(height: 24, color: AppColors.divider),
            _buildPreferenceTile(
              icon: Icons.visibility_rounded,
              title: 'Profile Visibility',
              subtitle: 'Allow others to invite me',
              value: prefs.profileVisibility,
              onChanged: (v) => userProvider.updatePreferences(
                prefs.copyWith(profileVisibility: v),
              ),
            ),
            const Divider(height: 24, color: AppColors.divider),
            _buildPreferenceTile(
              icon: Icons.auto_awesome_rounded,
              title: 'AI Matchmaking',
              subtitle: 'Suggest groups based on notes',
              value: prefs.aiMatchmaking,
              onChanged: (v) => userProvider.updatePreferences(
                prefs.copyWith(aiMatchmaking: v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCourse(String? course) {
    if (course == null) return Icons.menu_book_rounded;
    final lower = course.toLowerCase();
    if (lower.contains('computer') || lower.contains('cs') || lower.contains('data')) {
      return Icons.code_rounded;
    }
    if (lower.contains('math') || lower.contains('calc') || lower.contains('algebra')) {
      return Icons.functions_rounded;
    }
    if (lower.contains('phys')) return Icons.science_rounded;
    if (lower.contains('eng')) return Icons.engineering_rounded;
    return Icons.menu_book_rounded;
  }

  Widget _buildAchievementChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfacePurple,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderLight),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGroupMiniCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required int members,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfacePurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const Spacer(),
            Text(
              title,
              style: AppTextStyles.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (members > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.group_outlined,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '$members Members',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfacePurple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleMedium),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: AppColors.divider,
        ),
      ],
    );
  }
}
