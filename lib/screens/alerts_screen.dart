import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/app_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/notification_card.dart';

/// Alerts screen — fetches notifications from Firestore.
/// Falls back to an empty state when no notifications exist.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  CollectionReference<Map<String, dynamic>> _notificationsRef(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications');

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(),
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alerts', style: AppTextStyles.headlineLarge),
                      const SizedBox(height: 2),
                      Text(
                        'Your latest updates.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (uid != null)
                    GestureDetector(
                      onTap: () => _markAllAsRead(uid),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfacePurple,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          'Mark all as read',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Notifications list
            Expanded(
              child: uid == null
                  ? const EmptyState(
                      icon: Icons.login_rounded,
                      title: 'Sign in to see alerts',
                      subtitle: 'Log in to receive notifications.',
                    )
                  : _buildNotificationsList(uid),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _notificationsRef(uid)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const EmptyState(
            icon: Icons.notifications_off_outlined,
            title: 'No notifications yet',
            subtitle:
                'When someone joins your group or a session\nstarts, you\'ll see it here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final type = _parseType(data['type'] as String? ?? '');
            return NotificationCard(
              title: data['title'] as String? ?? 'Notification',
              subtitle: data['subtitle'] as String? ?? '',
              type: type,
              time: _formatTime(data['createdAt'] as Timestamp?),
              isUnread: data['isUnread'] as bool? ?? false,
              actionLabel: data['actionLabel'] as String?,
              onActionTap: data['actionLabel'] != null
                  ? () {
                      // Mark as read on tap
                      docs[index].reference.update({'isUnread': false});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Joining study room...'),
                        ),
                      );
                    }
                  : null,
            );
          },
        );
      },
    );
  }

  NotificationType _parseType(String type) {
    return switch (type) {
      'study_session' => NotificationType.studySession,
      'member_joined' => NotificationType.memberJoined,
      'ai_generated' => NotificationType.aiGenerated,
      'file_upload' => NotificationType.fileUpload,
      _ => NotificationType.studySession,
    };
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final now = DateTime.now();
    final dt = ts.toDate();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} hr';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }

  Future<void> _markAllAsRead(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final docs = await _notificationsRef(uid)
        .where('isUnread', isEqualTo: true)
        .get();
    for (final doc in docs.docs) {
      batch.update(doc.reference, {'isUnread': false});
    }
    await batch.commit();
  }
}
