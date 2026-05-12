import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/user_provider.dart';

/// Functional settings screen with profile editing, preferences,
/// and logout — all synced to Firestore.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userProvider = context.watch<UserProvider>();
    final appUser = userProvider.appUser;

    final displayName = appUser?.name ?? user?.displayName ?? 'Student';
    final email = appUser?.email ?? user?.email ?? '';
    final university = appUser?.university ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Settings', style: AppTextStyles.headlineMedium),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Profile Card ───
            _buildSectionCard(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.15),
                            AppColors.primaryLight.withValues(alpha: 0.1),
                          ],
                        ),
                        border: Border.all(color: AppColors.cardBorder, width: 2),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 30,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName, style: AppTextStyles.titleLarge),
                          const SizedBox(height: 2),
                          Text(email, style: AppTextStyles.bodySmall),
                          if (university.isNotEmpty)
                            Text(university, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditProfileDialog(
                      context, displayName, university, appUser?.major ?? '',
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── Notification Settings ───
            Text('NOTIFICATIONS',
                style: AppTextStyles.labelLarge.copyWith(letterSpacing: 1.5)),
            const SizedBox(height: 10),
            _buildSectionCard(
              children: [
                _buildToggle(
                  icon: Icons.notifications_active_rounded,
                  title: 'Study Session Alerts',
                  subtitle: 'Get notified when sessions start',
                  value: userProvider.preferences.sessionAlerts,
                  onChanged: (v) {
                    userProvider.updatePreferences(
                      userProvider.preferences.copyWith(sessionAlerts: v),
                    );
                  },
                ),
                const Divider(height: 24, color: AppColors.divider),
                _buildToggle(
                  icon: Icons.visibility_rounded,
                  title: 'Profile Visibility',
                  subtitle: 'Allow others to invite me',
                  value: userProvider.preferences.profileVisibility,
                  onChanged: (v) {
                    userProvider.updatePreferences(
                      userProvider.preferences.copyWith(profileVisibility: v),
                    );
                  },
                ),
                const Divider(height: 24, color: AppColors.divider),
                _buildToggle(
                  icon: Icons.auto_awesome_rounded,
                  title: 'AI Matchmaking',
                  subtitle: 'Suggest groups based on notes',
                  value: userProvider.preferences.aiMatchmaking,
                  onChanged: (v) {
                    userProvider.updatePreferences(
                      userProvider.preferences.copyWith(aiMatchmaking: v),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── About ───
            Text('ABOUT',
                style: AppTextStyles.labelLarge.copyWith(letterSpacing: 1.5)),
            const SizedBox(height: 10),
            _buildSectionCard(
              children: [
                _buildMenuItem(
                  icon: Icons.info_outline_rounded,
                  label: 'About StudyLink AI',
                  onTap: () => _showAboutDialog(context),
                ),
                const Divider(height: 1, indent: 48),
                _buildMenuItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help coming soon!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── Logout ───
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: Text(
                  'Log Out',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'StudyLink AI v1.0.0',
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surfacePurple,
            borderRadius: BorderRadius.circular(10),
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

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surfacePurple,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label, style: AppTextStyles.titleMedium),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
        size: 22,
      ),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    String currentName,
    String currentUniversity,
    String currentMajor,
  ) {
    final nameCtrl = TextEditingController(text: currentName);
    final uniCtrl = TextEditingController(text: currentUniversity);
    final majorCtrl = TextEditingController(text: currentMajor);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: uniCtrl,
              decoration: const InputDecoration(labelText: 'University'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: majorCtrl,
              decoration: const InputDecoration(labelText: 'Major'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final provider = context.read<UserProvider>();
              await provider.updateProfile(
                name: nameCtrl.text.trim(),
                university: uniCtrl.text.trim(),
                major: majorCtrl.text.trim(),
              );

              // Also update FirebaseAuth display name
              await FirebaseAuth.instance.currentUser
                  ?.updateDisplayName(nameCtrl.text.trim());

              if (ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('StudyLink AI', style: AppTextStyles.headlineSmall),
          ],
        ),
        content: Text(
          'StudyLink AI is a university study group finder with '
          'Edge AI-powered OCR note scanning and intelligent group recommendations.\n\n'
          'Version 1.0.0\n'
          'Built with Flutter & Firebase',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              context.read<UserProvider>().clear();
              await FirebaseAuth.instance.signOut();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
