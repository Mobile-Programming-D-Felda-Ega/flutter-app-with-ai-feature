import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/study_group.dart';
import '../widgets/app_header.dart';
import '../widgets/section_header.dart';
import '../widgets/study_group_card.dart';
import '../widgets/nearby_group_tile.dart';
import 'group_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CollectionReference<Map<String, dynamic>> get _groups =>
      FirebaseFirestore.instance.collection('study_groups');

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Student';

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GroupFormScreen()),
          );
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _groups.snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            final groups = docs.map(StudyGroup.fromFirestore).toList();
            groups.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: const AppHeader(),
                ),
                // Greeting
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $displayName! 👋',
                          style: AppTextStyles.headlineLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ready to sync up and study?',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                // Search bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfacePurple,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorderLight),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search subjects, groups, or topics.',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.textTertiary,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Recommended Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 12),
                    child: SectionHeader(
                      title: 'Recommended for you',
                      actionText: 'SEE ALL',
                      onActionTap: () {},
                    ),
                  ),
                ),
                // Horizontal card list
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : groups.isEmpty
                            ? Center(
                                child: Text(
                                  'No study groups yet. Create one!',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              )
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: groups.length.clamp(0, 5),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 14),
                                itemBuilder: (context, index) {
                                  return StudyGroupCard(
                                    group: groups[index],
                                    showAiMatch: index == 0,
                                  );
                                },
                              ),
                  ),
                ),
                // Happening Nearby Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 28, bottom: 12),
                    child: SectionHeader(
                      title: 'Happening Nearby',
                      onActionTap: () {},
                    ),
                  ),
                ),
                // Nearby list
                if (groups.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Text(
                          'No nearby groups found.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: groups.length.clamp(0, 5),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return NearbyGroupTile(
                          title: group.subjectName,
                          location: group.location,
                          distance: group.latitude != null ? '${(index * 0.2 + 0.1).toStringAsFixed(1)} mi' : null,
                          icon: index.isEven
                              ? Icons.menu_book_rounded
                              : Icons.location_on_rounded,
                        );
                      },
                    ),
                  ),
                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
