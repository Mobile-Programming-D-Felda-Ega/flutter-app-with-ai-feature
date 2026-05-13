import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/study_group.dart';
import 'user_service.dart';

/// Centralized study group operations with atomic join/leave.
class GroupService {
  GroupService._();
  static final instance = GroupService._();

  final _groups = FirebaseFirestore.instance.collection('study_groups');

  /// Join a group: adds user to group.memberIds AND group to user.joinedGroups.
  Future<void> joinGroup({
    required String groupId,
    required String uid,
  }) async {
    // Pastikan dokumen group ada sebelum update
    final groupDoc = await _groups.doc(groupId).get();
    if (!groupDoc.exists) {
      throw Exception('Study group tidak ditemukan (id: $groupId)');
    }
    // set+merge aman meski field memberIds belum ada di dokumen
    await _groups.doc(groupId).set({
      'memberIds': FieldValue.arrayUnion([uid]),
    }, SetOptions(merge: true));
    await UserService.instance.addJoinedGroup(uid, groupId);
  }

  /// Leave a group: removes user from group.memberIds AND group from user.joinedGroups.
  Future<void> leaveGroup({
    required String groupId,
    required String uid,
  }) async {
    await _groups.doc(groupId).set({
      'memberIds': FieldValue.arrayRemove([uid]),
    }, SetOptions(merge: true));
    await UserService.instance.removeJoinedGroup(uid, groupId);
  }

  /// Check if a user is a member of a group.
  Future<bool> isMember(String groupId, String uid) async {
    final doc = await _groups.doc(groupId).get();
    if (!doc.exists) return false;
    final members = List<String>.from(doc.data()?['memberIds'] ?? []);
    return members.contains(uid);
  }

  /// Get a single group by ID.
  Future<StudyGroup?> getGroupById(String groupId) async {
    final doc = await _groups.doc(groupId).get();
    if (!doc.exists) return null;
    // Use the QueryDocumentSnapshot-compatible constructor
    return StudyGroup(
      id: doc.id,
      subjectName: doc.data()?['subjectName'] ?? '',
      description: doc.data()?['description'] ?? '',
      location: doc.data()?['location'] ?? '',
      scheduledAt:
          (doc.data()?['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creatorId: doc.data()?['creatorId'] ?? '',
      memberIds: List<String>.from(doc.data()?['memberIds'] ?? []),
      latitude: (doc.data()?['latitude'] as num?)?.toDouble(),
      longitude: (doc.data()?['longitude'] as num?)?.toDouble(),
      university: doc.data()?['university'] as String?,
      major: doc.data()?['major'] as String?,
      course: doc.data()?['course'] as String?,
      imageUrl: doc.data()?['imageUrl'] as String?,
      tags: List<String>.from(doc.data()?['tags'] ?? []),
    );
  }

  /// Get all groups that the user has joined (by group IDs).
  Future<List<StudyGroup>> getJoinedGroups(List<String> groupIds) async {
    if (groupIds.isEmpty) return [];

    final groups = <StudyGroup>[];
    // Firestore 'whereIn' limited to 30 items
    for (var i = 0; i < groupIds.length; i += 30) {
      final batch = groupIds.sublist(
        i,
        i + 30 > groupIds.length ? groupIds.length : i + 30,
      );
      final snapshot =
          await _groups.where(FieldPath.documentId, whereIn: batch).get();
      groups.addAll(snapshot.docs.map(StudyGroup.fromFirestore));
    }
    return groups;
  }

  /// Stream all groups (for discovery/home).
  Stream<List<StudyGroup>> allGroupsStream() {
    return _groups.snapshots().map(
      (snapshot) => snapshot.docs.map(StudyGroup.fromFirestore).toList(),
    );
  }
}
