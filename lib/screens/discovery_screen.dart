import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/study_group.dart';
import '../providers/user_provider.dart';
import '../services/group_service.dart';
import '../widgets/app_header.dart';
import '../widgets/group_list_card.dart';

/// Discovery screen matching the Stitch design — search bar,
/// horizontal filter chips, and vertical group list cards.
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  CollectionReference<Map<String, dynamic>> get _groups =>
      FirebaseFirestore.instance.collection('study_groups');

  final TextEditingController _searchController = TextEditingController();
  String _selectedChip = 'All Groups';

  static const List<String> _filterChips = [
    'All Groups',
    'CS 101',
    'Mathematics',
    'Physics',
    'Engineering',
    'Biology',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StudyGroup> _applyFilters(List<StudyGroup> groups) {
    final search = _searchController.text.trim().toLowerCase();
    return groups.where((group) {
      final chipMatch = _selectedChip == 'All Groups' ||
          (group.course ?? '').toLowerCase().contains(_selectedChip.toLowerCase()) ||
          group.subjectName.toLowerCase().contains(_selectedChip.toLowerCase()) ||
          group.tags.any((t) => t.toLowerCase().contains(_selectedChip.toLowerCase()));
      final searchMatch = search.isEmpty ||
          group.subjectName.toLowerCase().contains(search) ||
          group.description.toLowerCase().contains(search) ||
          (group.course ?? '').toLowerCase().contains(search) ||
          group.tags.any((t) => t.toLowerCase().contains(search));
      return chipMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(),
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfacePurple,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorderLight),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search study groups, subjects, or topics',
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
                      horizontal: 16, vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            // Filter chips
            const SizedBox(height: 14),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filterChips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final chip = _filterChips[index];
                  final isSelected = _selectedChip == chip;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedChip = chip),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (chip != 'All Groups' && !isSelected) ...[
                            const Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            chip,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Group list
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _groups.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final groups = docs.map(StudyGroup.fromFirestore).toList();
                  final filtered = _applyFilters(groups);
                  filtered.sort(
                    (a, b) => a.scheduledAt.compareTo(b.scheduledAt),
                  );

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No groups match your search.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final group = filtered[index];
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      final joinedIds = context.watch<UserProvider>().joinedGroupIds;
                      final isJoined = joinedIds.contains(group.id);

                      return GroupListCard(
                        group: group,
                        isAiRecommended: group.tags.isNotEmpty && index < 3,
                        maxMembers: 15,
                        onJoin: () async {
                          if (uid == null) return;
                          try {
                            if (isJoined) {
                              await GroupService.instance.leaveGroup(
                                groupId: group.id, uid: uid,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Left "${group.subjectName}"'),
                                  ),
                                );
                              }
                            } else {
                              await GroupService.instance.joinGroup(
                                groupId: group.id, uid: uid,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Joined "${group.subjectName}"!'),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
