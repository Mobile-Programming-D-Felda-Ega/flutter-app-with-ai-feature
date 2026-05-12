import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/study_group.dart';
import '../services/geolocation_service.dart';
import 'pick_location.dart';

class GroupFormScreen extends StatefulWidget {
  const GroupFormScreen({super.key, this.group});

  final StudyGroup? group;

  @override
  State<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends State<GroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double? _latitude;
  double? _longitude;
  String? _university;
  String? _major;
  String? _course;
  bool _isSaving = false;
  String? _gpsMessage;

  // Simple lists for Surabaya universities and common majors
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

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    if (group != null) {
      _subjectController.text = group.subjectName;
      _descriptionController.text = group.description;
      _locationController.text = group.location;
      _selectedDate = DateTime(
        group.scheduledAt.year,
        group.scheduledAt.month,
        group.scheduledAt.day,
      );
      _selectedTime = TimeOfDay.fromDateTime(group.scheduledAt);
      _latitude = group.latitude;
      _longitude = group.longitude;
      _university = group.university ?? 'All';
      _major = group.major ?? 'All';
      _course = group.course ?? 'All';
      _tagsController.text = group.tags.join(', ');
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _gpsMessage = 'Memeriksa izin lokasi...';
    });

    try {
      final location = await GeoLocationService.getCurrentLocation();

      setState(() {
        _latitude = location.latitude;
        _longitude = location.longitude;
        _gpsMessage =
            'GPS tersimpan: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        if (_locationController.text.trim().isEmpty) {
          _locationController.text = 'Lokasi GPS';
        }
      });
    } catch (e) {
      setState(() {
        _gpsMessage = 'Error mendapatkan lokasi: ${e.toString()}';
      });
    }
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final collection = FirebaseFirestore.instance.collection('study_groups');
    final documentRef = widget.group != null
        ? collection.doc(widget.group!.id)
        : collection.doc();

    final group = StudyGroup(
      id: documentRef.id,
      subjectName: _subjectController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      university: _university == 'All' ? null : _university,
      major: _major == 'All' ? null : _major,
      course: _course == 'All' ? null : _course,
      imageUrl: widget.group?.imageUrl,
      tags: _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      scheduledAt: scheduledAt,
      creatorId: widget.group?.creatorId ?? currentUser.uid,
      memberIds: widget.group?.memberIds ?? [currentUser.uid],
      latitude: _latitude,
      longitude: _longitude,
    );

    try {
      if (widget.group == null) {
        await documentRef.set(group.toFirestore());
        // Debug log
        // ignore: avoid_print
        print('StudyGroup created: ${documentRef.id}');
      } else {
        await documentRef.update(group.toFirestore());
        // ignore: avoid_print
        print('StudyGroup updated: ${widget.group!.id}');
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      // Log and show error to user
      // ignore: avoid_print
      print('Failed to save StudyGroup: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan group: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _formatDateTime() {
    final date =
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';
    final time = _selectedTime.format(context);
    return '$date, $time';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.group != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Study Group' : 'Create Study Group'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Nama mata kuliah',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama mata kuliah wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // University & Major selectors
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _university ?? 'All',
                      items: _universities
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(u)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _university = v),
                      decoration: const InputDecoration(
                        labelText: 'Universitas',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _major ?? 'All',
                      items: _majors
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _major = v),
                      decoration: const InputDecoration(
                        labelText: 'Jurusan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _course ?? 'All',
                items: _courses
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _course = v),
                decoration: const InputDecoration(
                  labelText: 'Mata kuliah',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Deskripsi wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (pisahkan dengan koma)',
                  hintText: 'Contoh: machine learning, python, CNN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi meetup',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lokasi wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  'Pilih tanggal: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.schedule),
                label: Text('Pilih jam: ${_selectedTime.format(context)}'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _useCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Gunakan GPS perangkat'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context)
                      .push<Map<String, double>?>(
                        MaterialPageRoute(
                          builder: (_) => PickLocationScreen(
                            initialLat: _latitude,
                            initialLng: _longitude,
                          ),
                        ),
                      );

                  if (result != null && mounted) {
                    setState(() {
                      _latitude = result['latitude'];
                      _longitude = result['longitude'];
                      _gpsMessage =
                          'Lokasi dipilih: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}';
                      if (_locationController.text.trim().isEmpty) {
                        _locationController.text = 'Lokasi terpilih';
                      }
                    });
                  }
                },
                icon: const Icon(Icons.map),
                label: const Text('Pilih lokasi di peta'),
              ),
              if (_latitude != null && _longitude != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Koordinat: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                ),
              ],
              if (_gpsMessage != null) ...[
                const SizedBox(height: 8),
                Text(_gpsMessage!),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _saveGroup,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Update group' : 'Create group'),
              ),
              const SizedBox(height: 12),
              Text(
                'Jadwal meetup: ${_formatDateTime()}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
