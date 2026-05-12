import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/study_group.dart';
import '../services/geolocation_service.dart';
import '../widgets/ai_tag_chip.dart';
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
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double? _latitude;
  double? _longitude;
  String? _selectedSubject;
  bool _isSaving = false;
  List<String> _tags = [];

  static const List<String> _subjects = [
    'Computer Science', 'Mathematics', 'Physics', 'Chemistry',
    'Biology', 'Engineering', 'Psychology', 'Economics', 'Other',
  ];

  static const List<String> _suggestedTags = [
    'Data Structures', 'Python', 'Linear Algebra', 'Calculus',
    'Machine Learning', 'Algorithms',
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.group;
    if (g != null) {
      _subjectController.text = g.subjectName;
      _descriptionController.text = g.description;
      _locationController.text = g.location;
      _selectedDate = DateTime(g.scheduledAt.year, g.scheduledAt.month, g.scheduledAt.day);
      _selectedTime = TimeOfDay.fromDateTime(g.scheduledAt);
      _latitude = g.latitude;
      _longitude = g.longitude;
      _tags = List.from(g.tags);
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _useCurrentLocation() async {
    try {
      final location = await GeoLocationService.getCurrentLocation();
      setState(() {
        _latitude = location.latitude;
        _longitude = location.longitude;
        if (_locationController.text.trim().isEmpty) _locationController.text = 'GPS Location';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location error: $e')));
      }
    }
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _isSaving = true);
    final scheduledAt = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    final collection = FirebaseFirestore.instance.collection('study_groups');
    final documentRef = widget.group != null ? collection.doc(widget.group!.id) : collection.doc();

    final group = StudyGroup(
      id: documentRef.id, subjectName: _subjectController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      imageUrl: widget.group?.imageUrl, tags: _tags,
      scheduledAt: scheduledAt,
      creatorId: widget.group?.creatorId ?? currentUser.uid,
      memberIds: widget.group?.memberIds ?? [currentUser.uid],
      latitude: _latitude, longitude: _longitude,
    );

    try {
      if (widget.group == null) {
        await documentRef.set(group.toFirestore());
      } else {
        await documentRef.update(group.toFirestore());
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.group != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Group' : 'Create New Group',
                        style: AppTextStyles.headlineSmall,
                      ),
                      Text(
                        'Set up a space to collaborate and study.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Description card
                      _buildCard(children: [
                        Text('GROUP TITLE', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _subjectController,
                          decoration: const InputDecoration(hintText: 'e.g., Intro to Algorithms Prep'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        Text('DESCRIPTION (OPTIONAL)', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(hintText: 'What is the main focus of this group?'),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      // Subject card
                      _buildCard(children: [
                        Text('PRIMARY SUBJECT', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedSubject,
                          hint: Text('Select a subject...', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary)),
                          items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setState(() => _selectedSubject = v),
                          decoration: const InputDecoration(),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      // AI Suggested Tags
                      _buildAiTagsSection(),
                      const SizedBox(height: 16),
                      // Date/Time/Location card
                      _buildCard(children: [
                        Text('DATE', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfacePurpleLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(children: [
                              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textTertiary),
                              const SizedBox(width: 10),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('TIME', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfacePurpleLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(children: [
                              const Icon(Icons.schedule_rounded, size: 18, color: AppColors.textTertiary),
                              const SizedBox(width: 10),
                              Text(
                                _selectedTime.format(context),
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                              ),
                              const Spacer(),
                              const Icon(Icons.schedule_rounded, size: 18, color: AppColors.textTertiary),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('LOCATION', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            hintText: 'Search campus map or building...',
                            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textTertiary),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        // GPS buttons
                        Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _useCurrentLocation,
                              icon: const Icon(Icons.my_location_rounded, size: 18, color: AppColors.primary),
                              label: Text('Use GPS', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                minimumSize: Size.zero,
                                side: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.of(context).push<Map<String, double>?>(
                                  MaterialPageRoute(builder: (_) => PickLocationScreen(initialLat: _latitude, initialLng: _longitude)),
                                );
                                if (result != null && mounted) {
                                  setState(() {
                                    _latitude = result['latitude'];
                                    _longitude = result['longitude'];
                                    if (_locationController.text.trim().isEmpty) _locationController.text = 'Selected location';
                                  });
                                }
                              },
                              icon: const Icon(Icons.map_rounded, size: 18, color: AppColors.primary),
                              label: Text('Pick on Map', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                minimumSize: Size.zero,
                                side: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ),
                        ]),
                        if (_latitude != null && _longitude != null) ...[
                          const SizedBox(height: 10),
                          // Map preview placeholder
                          Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.surfacePurple,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on_rounded, size: 32, color: AppColors.primary),
                                const SizedBox(height: 8),
                                Text(
                                  _locationController.text.isNotEmpty ? _locationController.text : 'Selected Location',
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: FilledButton(
                onPressed: _isSaving ? null : _saveGroup,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.group_add_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(isEdit ? 'Update Study Group' : 'Create Study Group'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildAiTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text('AI SUGGESTED TAGS', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
        ]),
        const SizedBox(height: 4),
        Text('Based on your recent notes and syllabus scans:', style: AppTextStyles.bodySmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            ..._suggestedTags.where((t) => !_tags.contains(t)).map((tag) =>
              AiTagChip(label: tag, showAdd: true, onTap: () => setState(() => _tags.add(tag))),
            ),
            ..._tags.map((tag) =>
              AiTagChip(label: tag, isFilled: true, onDelete: () => setState(() => _tags.remove(tag))),
            ),
            AiTagChip(label: 'Add Custom', showAdd: true, onTap: _showAddCustomTagDialog),
          ],
        ),
      ],
    );
  }

  void _showAddCustomTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Tag'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Enter tag name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => _tags.add(controller.text.trim()));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
