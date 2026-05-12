import 'package:cloud_firestore/cloud_firestore.dart';

class StudyGroup {
  StudyGroup({
    required this.id,
    required this.subjectName,
    required this.description,
    required this.location,
    required this.scheduledAt,
    required this.creatorId,
    required this.memberIds,
    this.latitude,
    this.longitude,
    this.university,
    this.major,
    this.course,
    this.imageUrl,
    this.tags = const [],
  });

  final String id;
  final String subjectName;
  final String description;
  final String location;
  final DateTime scheduledAt;
  final String creatorId;
  final List<String> memberIds;
  final double? latitude;
  final double? longitude;
  final String? university;
  final String? major;
  final String? course;
  final String? imageUrl;
  final List<String> tags;

  factory StudyGroup.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return StudyGroup(
      id: doc.id,
      subjectName: data['subjectName'] as String? ?? '',
      description: data['description'] as String? ?? '',
      location: data['location'] as String? ?? '',
      scheduledAt:
          (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creatorId: data['creatorId'] as String? ?? '',
      memberIds: List<String>.from(
        data['memberIds'] as List<dynamic>? ?? const [],
      ),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      university: data['university'] as String?,
      major: data['major'] as String?,
      course: data['course'] as String?,
      imageUrl: data['imageUrl'] as String?,
      tags: List<String>.from(
        data['tags'] as List<dynamic>? ?? const [],
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'subjectName': subjectName,
      'description': description,
      'location': location,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'creatorId': creatorId,
      'memberIds': memberIds,
      'latitude': latitude,
      'longitude': longitude,
      'university': university,
      'major': major,
      'course': course,
      'imageUrl': imageUrl,
      'tags': tags,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  StudyGroup copyWith({
    String? subjectName,
    String? description,
    String? location,
    DateTime? scheduledAt,
    String? creatorId,
    List<String>? memberIds,
    double? latitude,
    double? longitude,
    String? university,
    String? major,
    String? course,
    String? imageUrl,
    List<String>? tags,
  }) {
    return StudyGroup(
      id: id,
      subjectName: subjectName ?? this.subjectName,
      description: description ?? this.description,
      location: location ?? this.location,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      creatorId: creatorId ?? this.creatorId,
      memberIds: memberIds ?? this.memberIds,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      university: university ?? this.university,
      major: major ?? this.major,
      course: course ?? this.course,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
    );
  }
}
