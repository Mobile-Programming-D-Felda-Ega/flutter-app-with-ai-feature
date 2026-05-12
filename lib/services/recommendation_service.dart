import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/study_group.dart';

/// A recommended study group with its match score and reasons.
class GroupRecommendation {
  GroupRecommendation({
    required this.group,
    required this.score,
    required this.matchReasons,
  });

  final StudyGroup group;

  /// Match confidence from 0 to 100.
  final int score;

  /// Human-readable reasons why this group was recommended.
  final List<String> matchReasons;
}

/// On-device recommendation engine using weighted keyword matching.
///
/// All scoring runs locally on the device — only the Firestore fetch uses network.
class RecommendationService {
  RecommendationService._();
  static final instance = RecommendationService._();

  /// Generate recommendations based on detected keywords and topic scores.
  Future<List<GroupRecommendation>> recommend({
    required List<String> keywords,
    required Map<String, double> topicScores,
  }) async {
    if (keywords.isEmpty && topicScores.isEmpty) return [];

    final groups = await _fetchAllGroups();
    if (groups.isEmpty) return [];

    final scored = <_Scored>[];

    for (final group in groups) {
      final result = _scoreGroup(group, keywords, topicScores);
      if (result.rawScore > 0) {
        scored.add(result);
      }
    }

    if (scored.isEmpty) return [];

    final maxScore = scored.map((r) => r.rawScore).reduce((a, b) => a > b ? a : b);

    final normalized = scored.map((r) {
      final pct = ((r.rawScore / maxScore) * 100).round().clamp(30, 99);
      return GroupRecommendation(
        group: r.group,
        score: pct,
        matchReasons: r.reasons,
      );
    }).toList();

    normalized.sort((a, b) => b.score.compareTo(a.score));
    return normalized.take(5).toList();
  }

  _Scored _scoreGroup(
    StudyGroup group,
    List<String> keywords,
    Map<String, double> topicScores,
  ) {
    double score = 0;
    final reasons = <String>[];
    final lowKeywords = keywords.map((k) => k.toLowerCase()).toList();
    final topics = topicScores.keys.toList();

    // Tags (weight 3.0)
    for (final tag in group.tags) {
      final lowTag = tag.toLowerCase();
      for (final keyword in lowKeywords) {
        if (lowTag.contains(keyword) || keyword.contains(lowTag)) {
          score += 3.0;
          if (!reasons.contains('Tag cocok: "$tag"')) {
            reasons.add('Tag cocok: "$tag"');
          }
        }
      }
      for (final topic in topics) {
        if (lowTag.contains(topic.toLowerCase()) ||
            topic.toLowerCase().contains(lowTag)) {
          score += 2.5 * (topicScores[topic] ?? 0.5);
          if (!reasons.contains('Topik terkait: $topic')) {
            reasons.add('Topik terkait: $topic');
          }
        }
      }
    }

    // Subject name (weight 2.5)
    final lowSubject = group.subjectName.toLowerCase();
    for (final keyword in lowKeywords) {
      if (lowSubject.contains(keyword)) {
        score += 2.5;
        if (!reasons.contains('Mata kuliah cocok')) {
          reasons.add('Mata kuliah cocok');
        }
      }
    }
    for (final topic in topics) {
      if (lowSubject.contains(topic.toLowerCase())) {
        score += 2.0 * (topicScores[topic] ?? 0.5);
        if (!reasons.contains('Mata kuliah terkait: $topic')) {
          reasons.add('Mata kuliah terkait: $topic');
        }
      }
    }

    // Course (weight 2.0)
    final lowCourse = (group.course ?? '').toLowerCase();
    if (lowCourse.isNotEmpty) {
      for (final keyword in lowKeywords) {
        if (lowCourse.contains(keyword)) {
          score += 2.0;
          if (!reasons.contains('Kategori mata kuliah cocok')) {
            reasons.add('Kategori mata kuliah cocok');
          }
        }
      }
      for (final topic in topics) {
        if (lowCourse.contains(topic.toLowerCase())) {
          score += 1.5 * (topicScores[topic] ?? 0.5);
        }
      }
    }

    // Description (weight 1.5)
    final lowDesc = group.description.toLowerCase();
    for (final keyword in lowKeywords) {
      if (lowDesc.contains(keyword)) {
        score += 1.5;
        if (reasons.length < 3 && !reasons.contains('Deskripsi relevan')) {
          reasons.add('Deskripsi relevan');
        }
      }
    }

    // Major (weight 1.0)
    final lowMajor = (group.major ?? '').toLowerCase();
    if (lowMajor.isNotEmpty) {
      for (final topic in topics) {
        if (lowMajor.contains(topic.toLowerCase())) {
          score += 1.0;
          if (!reasons.contains('Jurusan terkait')) {
            reasons.add('Jurusan terkait');
          }
        }
      }
    }

    return _Scored(group: group, rawScore: score, reasons: reasons);
  }

  Future<List<StudyGroup>> _fetchAllGroups() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('study_groups')
          .get();
      return snapshot.docs.map(StudyGroup.fromFirestore).toList();
    } catch (e) {
      return [];
    }
  }
}

class _Scored {
  _Scored({required this.group, required this.rawScore, required this.reasons});
  final StudyGroup group;
  final double rawScore;
  final List<String> reasons;
}
