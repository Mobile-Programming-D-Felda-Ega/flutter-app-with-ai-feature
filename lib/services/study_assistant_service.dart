import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/study_group.dart';

/// Rule-based AI Study Assistant engine.
///
/// Parses user messages, queries Firestore, and returns
/// formatted responses following the emoji-rich response format.
class StudyAssistantService {
  StudyAssistantService._();
  static final instance = StudyAssistantService._();

  CollectionReference<Map<String, dynamic>> get _groups =>
      FirebaseFirestore.instance.collection('study_groups');

  /// Process a user message and return the assistant's response.
  Future<String> processMessage(String message) async {
    final input = message.trim().toLowerCase();

    if (input.isEmpty) {
      return _noInput();
    }

    // Detect intent
    final intent = _detectIntent(input);

    switch (intent) {
      case _Intent.search:
        return _handleSearch(input);
      case _Intent.recommend:
        return _handleRecommend(input);
      case _Intent.todaySchedule:
        return _handleTodaySchedule();
      case _Intent.myGroups:
        return _handleMyGroups();
      case _Intent.studyTips:
        return _handleStudyTips(input);
      case _Intent.greeting:
        return _handleGreeting();
      case _Intent.help:
        return _handleHelp();
      case _Intent.unknown:
        return _handleUnknown();
    }
  }

  // ---------------------------------------------------------------------------
  // Intent Detection
  // ---------------------------------------------------------------------------

  _Intent _detectIntent(String input) {
    // Greeting
    if (_matchesAny(input, [
      'halo', 'hai', 'hi', 'hello', 'hey', 'selamat',
      'pagi', 'siang', 'sore', 'malam', 'apa kabar',
    ])) {
      return _Intent.greeting;
    }

    // Help
    if (_matchesAny(input, [
      'help', 'bantuan', 'bisa apa', 'cara pakai', 'tutorial',
      'fitur', 'apa yang bisa', 'perintah',
    ])) {
      return _Intent.help;
    }

    // Today schedule
    if (_matchesAny(input, [
      'hari ini', 'today', 'jadwal hari ini', 'schedule today',
      'group hari ini', 'meetup hari ini',
    ])) {
      return _Intent.todaySchedule;
    }

    // My groups
    if (_matchesAny(input, [
      'group saya', 'grup saya', 'my group', 'yang saya ikuti',
      'joined', 'sudah join', 'saya ikut',
    ])) {
      return _Intent.myGroups;
    }

    // Study tips
    if (_matchesAny(input, [
      'tips', 'saran belajar', 'study tips', 'cara belajar',
      'motivasi', 'teknik belajar', 'metode belajar',
      'pomodoro', 'efektif',
    ])) {
      return _Intent.studyTips;
    }

    // Search (explicit)
    if (_matchesAny(input, [
      'cari', 'search', 'find', 'temukan', 'ada group',
      'ada grup', 'kelompok', 'tentang',
    ])) {
      return _Intent.search;
    }

    // Recommend
    if (_matchesAny(input, [
      'rekomendasi', 'recommend', 'suggestion', 'saran',
      'cocok', 'bagus', 'terbaik', 'best', 'top',
      'suggest', 'populer', 'ramai',
    ])) {
      return _Intent.recommend;
    }

    // If contains known subject/course keywords, treat as search
    if (_matchesAny(input, [
      'algoritma', 'struktur data', 'basis data', 'database',
      'mobile', 'jaringan', 'sistem operasi', 'pemrograman',
      'informatika', 'elektro', 'mesin', 'manajemen', 'akuntansi',
      'airlangga', 'its', 'petra', 'unesa', 'untag',
    ])) {
      return _Intent.search;
    }

    return _Intent.unknown;
  }

  bool _matchesAny(String input, List<String> keywords) {
    return keywords.any((keyword) => input.contains(keyword));
  }

  // ---------------------------------------------------------------------------
  // Intent Handlers
  // ---------------------------------------------------------------------------

  Future<String> _handleSearch(String input) async {
    final groups = await _fetchAllGroups();
    final results = _filterByQuery(groups, input);

    if (results.isEmpty) {
      return _noResults(input);
    }

    return _formatGroupList(
      results.take(5).toList(),
      title: '📚 Hasil Pencarian:',
      reasonBuilder: (g) => _searchReason(g, input),
    );
  }

  Future<String> _handleRecommend(String input) async {
    final groups = await _fetchAllGroups();

    // Filter out past groups
    final now = DateTime.now();
    var upcoming = groups.where((g) => g.scheduledAt.isAfter(now)).toList();

    if (upcoming.isEmpty) {
      return '❌ Tidak ada group yang akan datang saat ini.\n\n'
          '💡 Saran:\nBuat study group baru dengan tombol "Buat Group" '
          'di halaman utama!';
    }

    // Sort by soonest first
    upcoming.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    // Prefer groups the user hasn't joined
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final notJoined =
          upcoming.where((g) => !g.memberIds.contains(user.uid)).toList();
      if (notJoined.isNotEmpty) {
        upcoming = notJoined;
      }
    }

    return _formatGroupList(
      upcoming.take(3).toList(),
      title: '📚 Rekomendasi Study Group:',
      reasonBuilder: (g) {
        final memberCount = g.memberIds.length;
        final daysUntil = g.scheduledAt.difference(now).inDays;
        if (daysUntil == 0) return 'Meetup hari ini! $memberCount anggota';
        if (daysUntil == 1) return 'Besok! $memberCount anggota';
        return 'Dalam $daysUntil hari, $memberCount anggota';
      },
    );
  }

  Future<String> _handleTodaySchedule() async {
    final groups = await _fetchAllGroups();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final todayGroups = groups
        .where((g) =>
            g.scheduledAt.isAfter(today) && g.scheduledAt.isBefore(tomorrow))
        .toList();

    if (todayGroups.isEmpty) {
      return '❌ Tidak ada study group yang dijadwalkan hari ini.\n\n'
          '💡 Saran:\nManfaatkan waktu luang untuk review materi atau '
          'buat study group baru untuk hari ini!';
    }

    todayGroups.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return _formatGroupList(
      todayGroups,
      title: '📚 Jadwal Hari Ini (${_formatDate(now)}):',
      reasonBuilder: (g) => 'Dimulai pukul ${_formatTime(g.scheduledAt)}',
    );
  }

  Future<String> _handleMyGroups() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return '❌ Kamu belum login.\n\n💡 Saran:\nLogin terlebih dahulu untuk melihat group kamu.';
    }

    final groups = await _fetchAllGroups();
    final myGroups =
        groups.where((g) => g.memberIds.contains(user.uid)).toList();

    if (myGroups.isEmpty) {
      return '❌ Kamu belum bergabung dengan study group manapun.\n\n'
          '💡 Saran:\nCoba ketik "rekomendasi" untuk melihat group yang '
          'bisa kamu ikuti!';
    }

    myGroups.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return _formatGroupList(
      myGroups.take(5).toList(),
      title: '📚 Study Group Kamu (${myGroups.length} total):',
      reasonBuilder: (g) {
        if (g.creatorId == user.uid) return 'Kamu adalah creator';
        return '${g.memberIds.length} anggota';
      },
    );
  }

  String _handleStudyTips(String input) {
    final tips = [
      '📖 **Teknik Pomodoro**: Belajar 25 menit, istirahat 5 menit. '
          'Setelah 4 sesi, istirahat 15-30 menit. Terbukti meningkatkan fokus!',
      '🧠 **Active Recall**: Jangan cuma baca ulang. Tutup buku dan coba '
          'jelaskan materi dengan kata-katamu sendiri.',
      '📝 **Spaced Repetition**: Review materi di hari ke-1, 3, 7, dan 14 '
          'setelah pertama kali belajar untuk memori jangka panjang.',
      '👥 **Study Group**: Belajar bersama terbukti efektif! Jelaskan konsep '
          'ke teman = cara terbaik memahami materi (Feynman Technique).',
      '🎯 **Buat Target Kecil**: Pecah materi besar jadi bagian-bagian kecil. '
          'Selesaikan satu per satu untuk menghindari overwhelm.',
      '🌙 **Tidur Cukup**: Otak memproses dan mengkonsolidasi memori saat '
          'tidur. Jangan begadang sebelum ujian!',
    ];

    // Pick a tip based on time so it feels varied
    final index = DateTime.now().millisecond % tips.length;

    return '💡 Tips Belajar:\n\n${tips[index]}\n\n'
        'Ketik "tips" lagi untuk tips berikutnya!';
  }

  String _handleGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 11) {
      greeting = 'Selamat pagi! ☀️';
    } else if (hour < 15) {
      greeting = 'Selamat siang! 🌤️';
    } else if (hour < 18) {
      greeting = 'Selamat sore! 🌅';
    } else {
      greeting = 'Selamat malam! 🌙';
    }

    return '$greeting\n\n'
        'Saya AI Study Assistant kamu. '
        'Saya bisa membantu kamu:\n\n'
        '🔍 Mencari study group\n'
        '📚 Memberikan rekomendasi group\n'
        '📅 Cek jadwal hari ini\n'
        '💡 Tips belajar efektif\n\n'
        'Ketik pertanyaan atau gunakan tombol quick action di bawah!';
  }

  String _handleHelp() {
    return '🤖 **Panduan AI Study Assistant**\n\n'
        'Berikut perintah yang bisa kamu gunakan:\n\n'
        '🔍 **"cari [topik]"** — Cari group berdasarkan mata kuliah\n'
        '   Contoh: "cari struktur data"\n\n'
        '📚 **"rekomendasi"** — Lihat group terbaik untukmu\n\n'
        '📅 **"jadwal hari ini"** — Lihat meetup hari ini\n\n'
        '👤 **"group saya"** — Lihat group yang kamu ikuti\n\n'
        '💡 **"tips"** — Dapatkan tips belajar\n\n'
        'Kamu juga bisa langsung ketik nama mata kuliah seperti '
        '"pemrograman mobile" atau "basis data"!';
  }

  String _handleUnknown() {
    return '🤔 Maaf, saya kurang memahami pertanyaanmu.\n\n'
        '💡 Saran:\nCoba gunakan kata kunci seperti:\n'
        '• "cari [mata kuliah]" — mencari group\n'
        '• "rekomendasi" — melihat rekomendasi\n'
        '• "jadwal hari ini" — cek jadwal\n'
        '• "tips" — tips belajar\n'
        '• "help" — panduan lengkap';
  }

  String _noInput() {
    return '💡 Ketik pertanyaan atau gunakan tombol quick action di bawah!';
  }

  String _noResults(String input) {
    return '❌ Tidak ditemukan group yang cocok.\n\n'
        '💡 Saran:\n'
        '• Coba kata kunci yang berbeda\n'
        '• Buat study group baru dengan tombol "Buat Group"\n'
        '• Ketik "rekomendasi" untuk melihat semua group tersedia';
  }

  // ---------------------------------------------------------------------------
  // Firestore Queries
  // ---------------------------------------------------------------------------

  Future<List<StudyGroup>> _fetchAllGroups() async {
    try {
      final snapshot = await _groups.get();
      return snapshot.docs.map(StudyGroup.fromFirestore).toList();
    } catch (e) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Filtering & Matching
  // ---------------------------------------------------------------------------

  List<StudyGroup> _filterByQuery(List<StudyGroup> groups, String query) {
    // Extract meaningful search terms
    final stopWords = {
      'cari', 'search', 'find', 'temukan', 'ada', 'group', 'grup',
      'kelompok', 'yang', 'untuk', 'di', 'tentang', 'mata', 'kuliah',
      'buat', 'saya', 'mau', 'ingin', 'study',
    };

    final searchTerms = query
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 1 && !stopWords.contains(word))
        .toList();

    if (searchTerms.isEmpty) {
      // No specific search terms — return upcoming groups
      final now = DateTime.now();
      return groups
          .where((g) => g.scheduledAt.isAfter(now))
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    }

    // Score each group by how many search terms match
    final scored = <MapEntry<StudyGroup, int>>[];

    for (final group in groups) {
      int score = 0;
      final searchable = [
        group.subjectName.toLowerCase(),
        group.description.toLowerCase(),
        group.location.toLowerCase(),
        (group.university ?? '').toLowerCase(),
        (group.major ?? '').toLowerCase(),
        (group.course ?? '').toLowerCase(),
      ].join(' ');

      for (final term in searchTerms) {
        if (searchable.contains(term)) {
          score += 1;
          // Bonus for subject name match
          if (group.subjectName.toLowerCase().contains(term)) {
            score += 2;
          }
        }
      }

      if (score > 0) {
        scored.add(MapEntry(group, score));
      }
    }

    // Sort by score descending, then by schedule
    scored.sort((a, b) {
      final scoreCompare = b.value.compareTo(a.value);
      if (scoreCompare != 0) return scoreCompare;
      return a.key.scheduledAt.compareTo(b.key.scheduledAt);
    });

    return scored.map((e) => e.key).toList();
  }

  String _searchReason(StudyGroup group, String query) {
    final subject = group.subjectName.toLowerCase();
    final course = (group.course ?? '').toLowerCase();
    final university = (group.university ?? '').toLowerCase();

    if (query.split(' ').any((w) => subject.contains(w) && w.length > 2)) {
      return 'Cocok dengan mata kuliah yang dicari';
    }
    if (query.split(' ').any((w) => course.contains(w) && w.length > 2)) {
      return 'Cocok dengan kategori mata kuliah';
    }
    if (query.split(' ').any((w) => university.contains(w) && w.length > 2)) {
      return 'Dari universitas yang dicari';
    }
    return '${group.memberIds.length} anggota aktif';
  }

  // ---------------------------------------------------------------------------
  // Formatting
  // ---------------------------------------------------------------------------

  String _formatGroupList(
    List<StudyGroup> groups, {
    required String title,
    required String Function(StudyGroup) reasonBuilder,
  }) {
    final buffer = StringBuffer(title);
    buffer.writeln();

    for (var i = 0; i < groups.length; i++) {
      final g = groups[i];
      buffer.writeln();
      buffer.writeln('${i + 1}. **${g.subjectName}**');
      buffer.writeln(
          '   🕒 ${_formatDate(g.scheduledAt)} • ${_formatTime(g.scheduledAt)}');
      buffer.writeln('   📍 ${g.location}');
      buffer.writeln('   👥 ${g.memberIds.length} anggota');
      buffer.writeln('   ⭐ ${reasonBuilder(g)}');
    }

    buffer.writeln();
    buffer.writeln('💡 Saran:');

    if (groups.length == 1) {
      buffer.writeln('Group ini cocok untukmu! Bergabung dari halaman utama.');
    } else {
      buffer.writeln(
          'Pilih group yang paling sesuai dengan jadwalmu dan bergabung dari halaman utama.');
    }

    return buffer.toString();
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

enum _Intent {
  search,
  recommend,
  todaySchedule,
  myGroups,
  studyTips,
  greeting,
  help,
  unknown,
}
