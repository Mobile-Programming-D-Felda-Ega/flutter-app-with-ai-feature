import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/study_group.dart';
import '../services/notification_service.dart';
import 'group_form.dart';
import 'assistant_screen.dart';
import 'group_map_screen.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  CollectionReference<Map<String, dynamic>> get _groups =>
      FirebaseFirestore.instance.collection('study_groups');

  static const String _prefUniversityKey = 'filter_university';
  static const String _prefMajorKey = 'filter_major';
  static const String _prefCourseKey = 'filter_course';
  static const String _prefSubjectKey = 'filter_subject';

  // Filter state
  String _selectedUniversity = 'All';
  String _selectedMajor = 'All';
  String _selectedCourse = 'All';
  final TextEditingController _subjectFilterController =
      TextEditingController();
  bool _preferencesLoaded = false;

  static const List<String> _universities = [
    'All',
    'Universitas Airlangga',
    'Institut Teknologi Sepuluh Nopember',
    'Universitas Negeri Surabaya',
    'Universitas Kristen Petra',
    'Universitas 17 Agustus 1945 Surabaya',
    'Other',
  ];

  static const List<String> _majors = [
    'All',
    'Informatika',
    'Sistem Informasi',
    'Teknik Elektro',
    'Teknik Mesin',
    'Manajemen',
    'Akuntansi',
    'Other',
  ];

  static const List<String> _courses = [
    'All',
    'Algoritma dan Pemrograman',
    'Struktur Data',
    'Basis Data',
    'Pemrograman Mobile',
    'Jaringan Komputer',
    'Sistem Operasi',
    'Other',
  ];

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  void initState() {
    super.initState();
    _loadFilterPreferences();
  }

  Future<void> _loadFilterPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedUniversity = prefs.getString(_prefUniversityKey) ?? 'All';
      _selectedMajor = prefs.getString(_prefMajorKey) ?? 'All';
      _selectedCourse = prefs.getString(_prefCourseKey) ?? 'All';
      _subjectFilterController.text = prefs.getString(_prefSubjectKey) ?? '';
      _preferencesLoaded = true;
    });
  }

  Future<void> _saveFilterPreferences() async {
    if (!_preferencesLoaded) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefUniversityKey, _selectedUniversity);
    await prefs.setString(_prefMajorKey, _selectedMajor);
    await prefs.setString(_prefCourseKey, _selectedCourse);
    await prefs.setString(
      _prefSubjectKey,
      _subjectFilterController.text.trim(),
    );
  }

  Future<void> _updateUniversity(String value) async {
    setState(() => _selectedUniversity = value);
    await _saveFilterPreferences();
  }

  Future<void> _updateMajor(String value) async {
    setState(() => _selectedMajor = value);
    await _saveFilterPreferences();
  }

  Future<void> _updateCourse(String value) async {
    setState(() => _selectedCourse = value);
    await _saveFilterPreferences();
  }

  Future<void> _updateSubjectFilter(String value) async {
    setState(() {});
    await _saveFilterPreferences();
  }

  Future<void> _clearFilters() async {
    setState(() {
      _selectedUniversity = 'All';
      _selectedMajor = 'All';
      _selectedCourse = 'All';
      _subjectFilterController.clear();
    });
    await _saveFilterPreferences();
  }

  Future<void> _joinGroup(StudyGroup group) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    await _groups.doc(group.id).update({
      'memberIds': FieldValue.arrayUnion([user.uid]),
    });
  }

  Future<void> _deleteGroup(StudyGroup group) async {
    await _groups.doc(group.id).delete();
  }

  Future<void> _sendInvite(StudyGroup group) async {
    await NotificationService.instance.showInviteNotification(group);
  }

  Future<void> _setReminder(StudyGroup group) async {
    await NotificationService.instance.scheduleReminder(group);
  }

  Future<void> _testNotification() async {
    await NotificationService.instance.showTestNotification();
  }

  bool _isCreator(StudyGroup group) {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && group.creatorId == user.uid;
  }

  bool _hasJoined(StudyGroup group) {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && group.memberIds.contains(user.uid);
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year • $hour:$minute';
  }

  @override
  void dispose() {
    _subjectFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentTabIndex == 0
              ? 'Study Group Finder'
              : _currentTabIndex == 1
              ? 'Scan Catatan (Edge AI)'
              : 'AI Study Assistant',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GroupFormScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buat Group'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) {
          setState(() => _currentTabIndex = index);
        },
        indicatorColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF7C3AED)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(
              Icons.document_scanner_rounded,
              color: Color(0xFF7C3AED),
            ),
            label: 'Scan Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome, color: Color(0xFF7C3AED)),
            label: 'AI Assistant',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildHomeTab(user),
          const ScannerScreen(),
          const AssistantScreen(),
        ],
      ),
    );
  }

  DropdownButtonFormField<String> _buildFilterDropdown({
    required String value,
    required List<String> items,
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) {
          onChanged(v);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildHomeTab(User? user) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 720;
              final universityDropdown = _buildFilterDropdown(
                value: _selectedUniversity,
                items: _universities,
                label: 'Universitas',
                onChanged: _updateUniversity,
              );
              final majorDropdown = _buildFilterDropdown(
                value: _selectedMajor,
                items: _majors,
                label: 'Jurusan',
                onChanged: _updateMajor,
              );
              final courseDropdown = _buildFilterDropdown(
                value: _selectedCourse,
                items: _courses,
                label: 'Mata kuliah',
                onChanged: _updateCourse,
              );
              final resetButton = IconButton(
                onPressed: _clearFilters,
                tooltip: 'Reset filter',
                icon: const Icon(Icons.clear_all_rounded),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    universityDropdown,
                    const SizedBox(height: 8),
                    majorDropdown,
                    const SizedBox(height: 8),
                    courseDropdown,
                    const SizedBox(height: 4),
                    Align(alignment: Alignment.centerRight, child: resetButton),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: universityDropdown),
                  const SizedBox(width: 8),
                  Expanded(child: majorDropdown),
                  const SizedBox(width: 8),
                  Expanded(child: courseDropdown),
                  const SizedBox(width: 8),
                  resetButton,
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: _subjectFilterController,
            decoration: const InputDecoration(
              labelText: 'Cari mata kuliah (kosong = semua)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (value) => _updateSubjectFilter(value),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _groups.snapshots(),
            builder: (context, snapshot) {
              if (!_preferencesLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Gagal memuat data: ${snapshot.error}'),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              final groups = docs.map(StudyGroup.fromFirestore).toList();
              final filteredGroups = _applyFilters(groups);

              if (filteredGroups.isEmpty) {
                return const Center(
                  child: Text('Tidak ada group yang cocok dengan filter ini.'),
                );
              }

              filteredGroups.sort(
                (a, b) => a.scheduledAt.compareTo(b.scheduledAt),
              );

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredGroups.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildWelcomeCard(user);
                  }

                  final group = filteredGroups[index - 1];
                  return _buildGroupCard(context, group);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<StudyGroup> _applyFilters(List<StudyGroup> groups) {
    final subjectFilter = _subjectFilterController.text.trim().toLowerCase();

    return groups.where((group) {
      final university = group.university ?? 'All';
      final major = group.major ?? 'All';
      final course = group.course ?? '';
      final subjectName = group.subjectName.toLowerCase();

      final universityMatch =
          _selectedUniversity == 'All' || university == _selectedUniversity;
      final majorMatch = _selectedMajor == 'All' || major == _selectedMajor;
      final courseMatch = _selectedCourse == 'All' || course == _selectedCourse;
      final subjectMatch =
          subjectFilter.isEmpty || subjectName.contains(subjectFilter);

      return universityMatch && majorMatch && courseMatch && subjectMatch;
    }).toList();
  }

  Widget _buildWelcomeCard(User? user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.groups_rounded, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Row(
            children: const [
              Text(
                'Selamat datang!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.emoji_emotions_rounded, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'User',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await _testNotification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test notification dikirim')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Test notification gagal: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Test Notif'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Temukan atau buat study group untuk belajar bersama teman-teman.',
            style: TextStyle(color: Colors.white, height: 1.5, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, StudyGroup group) {
    final isCreator = _isCreator(group);
    final hasJoined = _hasJoined(group);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCreator
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                  : const Color(0xFF06B6D4).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCreator
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF06B6D4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.book_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.subjectName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isCreator)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Owner',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(
                  Icons.schedule_rounded,
                  _formatDateTime(group.scheduledAt),
                ),
                const SizedBox(height: 10),
                _infoRow(Icons.location_on_rounded, group.location),
                if (group.latitude != null && group.longitude != null) ...[
                  const SizedBox(height: 10),
                  _infoRow(
                    Icons.gps_fixed_rounded,
                    '${group.latitude!.toStringAsFixed(6)}, ${group.longitude!.toStringAsFixed(6)}',
                  ),
                ],
                const SizedBox(height: 10),
                _infoRow(
                  Icons.people_rounded,
                  '${group.memberIds.length} member(s)',
                ),
                if (group.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      group.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          width: double.infinity,
                          alignment: Alignment.center,
                          color: const Color(0xFFF3F4F6),
                          child: const Text('Foto group tidak bisa dimuat'),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: hasJoined
                          ? null
                          : () async {
                              await _joinGroup(group);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Bergabung dengan group!'),
                                  ),
                                );
                              }
                            },
                      icon: Icon(
                        hasJoined ? Icons.check_rounded : Icons.add_rounded,
                      ),
                      label: Text(hasJoined ? 'Sudah join' : 'Join'),
                    ),
                    if (isCreator)
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GroupFormScreen(group: group),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Edit'),
                      ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GroupMapScreen(group: group),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_rounded),
                      label: const Text('Map'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _sendInvite(group);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Undangan dikirim!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.mail_rounded),
                      label: const Text('Invite'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _setReminder(group);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pengingat diatur!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.notifications_rounded),
                      label: const Text('Reminder'),
                    ),
                    if (isCreator)
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _deleteGroup(group);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Group dihapus')),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_rounded),
                        label: const Text('Delete'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF7C3AED)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
