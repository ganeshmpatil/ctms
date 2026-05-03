import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/client.dart';
import '../api/models.dart';
import '../widgets/glass.dart';
import '../widgets/photo_picker.dart';
import 'attendance_calendar.dart';
import 'result_upload.dart';

class StudentDetailScreen extends StatefulWidget {
  final ApiClient api;
  final Student student;
  final String divisionLabel;
  const StudentDetailScreen({
    super.key,
    required this.api,
    required this.student,
    required this.divisionLabel,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late Student _student;
  late String _divisionLabel;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _student = widget.student;
    _divisionLabel = widget.divisionLabel;
    _results = widget.api.results(studentId: widget.student.id);
  }

  late Future<List<ExamResult>> _results;

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _openEdit() async {
    final divisions = await widget.api.divisions().catchError((_) => <Division>[]);
    if (!mounted || divisions.isEmpty) return;
    final updated = await showModalBottomSheet<Student>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditStudentSheet(
        api: widget.api,
        student: _student,
        divisions: divisions,
      ),
    );
    if (updated != null) {
      setState(() {
        _student = updated;
        final d = divisions.firstWhere(
          (x) => x.id == updated.divisionId,
          orElse: () => divisions.first,
        );
        _divisionLabel = d.label;
      });
    }
  }

  Future<void> _openAddResult() async {
    final added = await showModalBottomSheet<ExamResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ResultUploadSheet(
        api: widget.api,
        studentId: _student.id,
        studentName: _student.name,
      ),
    );
    if (added != null && mounted) {
      setState(() {
        _results = widget.api.results(studentId: _student.id);
      });
    }
  }

  Future<void> _confirmDeleteResult(ExamResult r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Delete result?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'This will permanently remove the ${r.year}-${r.month.toString().padLeft(2, '0')} result for ${_student.name}.',
          style: const TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.muted))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.api.deleteResult(r.id);
      if (!mounted) return;
      setState(() {
        _results = widget.api.results(studentId: _student.id);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Delete student?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '${_student.name} and all linked results/attendance will be permanently removed.',
          style: const TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.muted))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.api.deleteStudent(_student.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _student;
    final canMutate =
        widget.api.user?.role == 'admin' || widget.api.user?.role == 'teacher';
    return Scaffold(
      backgroundColor: AppColors.bg1,
      appBar: AppBar(
        title: const Text('Student'),
        actions: canMutate
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Edit',
                  onPressed: _openEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Delete',
                  onPressed: _confirmDelete,
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          // Non-collapsing header — sits above the TabBar so nothing overlaps.
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: PhotoAvatar(
                    base64: s.photo,
                    fallbackInitials: s.initials,
                    radius: 40,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  s.name,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _divisionLabel,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tab,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.muted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Info'),
                Tab(text: 'Attendance'),
                Tab(text: 'Results'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outline),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _InfoTab(student: s, divisionLabel: _divisionLabel),
                AttendanceCalendarView(api: widget.api, student: _student),
              FutureBuilder<List<ExamResult>>(
                future: _results,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary));
                  }
                  if (snap.hasError) {
                    return Center(
                        child: Text(snap.error.toString(),
                            style: const TextStyle(color: Colors.white70)));
                  }
                  final list = snap.data!;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      if (canMutate)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GradientButton(
                            label: 'Upload result',
                            icon: Icons.add_a_photo_rounded,
                            onPressed: _openAddResult,
                          ),
                        ),
                      if (list.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(
                            child: Text('No results yet',
                                style: TextStyle(color: AppColors.muted)),
                          ),
                        ),
                      ...list.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GlassCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              colors: [
                                                AppColors.accent,
                                                AppColors.primary
                                              ]),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          DateFormat('MMM yyyy')
                                              .format(DateTime(r.year, r.month)),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (r.totalMarks != null)
                                        Text(
                                          r.totalMarks!.toStringAsFixed(0),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18),
                                        ),
                                      if (canMutate) ...[
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: AppColors.muted),
                                          onPressed: () =>
                                              _confirmDeleteResult(r),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ],
                                  ),
                            if (r.subjects.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              ...r.subjects.map((sub) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 3),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text('• ${sub.subjectId}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: AppColors.muted,
                                                  fontSize: 12)),
                                        ),
                                        Text(
                                          '${sub.marks.toStringAsFixed(0)}/${sub.outOfMarks.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                            if (r.photo != null && r.photo!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: PhotoAvatar(
                                    base64: r.photo,
                                    fallbackInitials: '?',
                                    radius: 0,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                            ),
                          )),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}

String _genderLabel(String? g) {
  switch (g) {
    case 'male':
      return 'Male';
    case 'female':
      return 'Female';
    case 'other':
      return 'Other';
    default:
      return '—';
  }
}

class _InfoTab extends StatelessWidget {
  final Student student;
  final String divisionLabel;
  const _InfoTab({required this.student, required this.divisionLabel});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _section('Personal', Icons.person_rounded, [
          _row('Name', student.name),
          _row('Division', divisionLabel),
          _row('Gender', _genderLabel(student.gender)),
          _row(
              'DOB',
              student.dob == null
                  ? '—'
                  : DateFormat('dd MMM yyyy').format(student.dob!)),
          _row('Aadhar', student.aadhar ?? '—'),
          _row('Address', student.address ?? '—'),
          _row('School', student.schoolName ?? '—'),
          _row('Joined', DateFormat('dd MMM yyyy').format(student.createdAt)),
        ]),
        const SizedBox(height: 12),
        _section('Contact', Icons.phone_rounded, [
          _row('Mobile #1', student.mobile1 ?? '—'),
          _row('Mobile #2', student.mobile2 ?? '—'),
          _row('Mobile #3', student.mobile3 ?? '—'),
        ]),
        if (student.reference != null && student.reference!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _section('Reference', Icons.bookmark_rounded, [
            _row('Note', student.reference!),
          ]),
        ],
      ],
    );
  }

  Widget _section(String title, IconData icon, List<Widget> rows) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accent, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _EditStudentSheet extends StatefulWidget {
  final ApiClient api;
  final Student student;
  final List<Division> divisions;
  const _EditStudentSheet({
    required this.api,
    required this.student,
    required this.divisions,
  });

  @override
  State<_EditStudentSheet> createState() => _EditStudentSheetState();
}

class _EditStudentSheetState extends State<_EditStudentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _mobile1;
  late final TextEditingController _mobile2;
  late final TextEditingController _mobile3;
  late final TextEditingController _address;
  late final TextEditingController _aadhar;
  late final TextEditingController _schoolName;
  late final TextEditingController _reference;
  String? _divisionId;
  String? _gender;
  DateTime? _dob;
  String? _photoBase64;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.student.name);
    _mobile1 = TextEditingController(text: widget.student.mobile1 ?? '');
    _mobile2 = TextEditingController(text: widget.student.mobile2 ?? '');
    _mobile3 = TextEditingController(text: widget.student.mobile3 ?? '');
    _address = TextEditingController(text: widget.student.address ?? '');
    _aadhar = TextEditingController(text: widget.student.aadhar ?? '');
    _schoolName = TextEditingController(text: widget.student.schoolName ?? '');
    _reference = TextEditingController(text: widget.student.reference ?? '');
    _divisionId = widget.student.divisionId;
    _gender = widget.student.gender;
    _dob = widget.student.dob;
    _photoBase64 = widget.student.photo;
  }

  Future<void> _pickPhoto() async {
    final b64 = await capturePhotoBase64(context);
    if (b64 != null && mounted) setState(() => _photoBase64 = b64);
  }

  Future<void> _pickDob() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2014, 1, 1),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.text,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _dob = d);
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile1.dispose();
    _mobile2.dispose();
    _mobile3.dispose();
    _address.dispose();
    _aadhar.dispose();
    _schoolName.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final updated = await widget.api.updateStudent(
        id: widget.student.id,
        name: _name.text.trim(),
        divisionId: _divisionId,
        mobile1: _mobile1.text.trim(),
        mobile2: _mobile2.text.trim(),
        mobile3: _mobile3.text.trim(),
        aadhar: _aadhar.text.trim(),
        schoolName: _schoolName.text.trim(),
        reference: _reference.text.trim(),
        address: _address.text.trim(),
        photoBase64: _photoBase64,
        dob: _dob,
        gender: _gender,
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final maxH = MediaQuery.of(context).size.height * 0.88;
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, inset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('Edit student',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: TapScale(
                            onTap: _pickPhoto,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                PhotoAvatar(
                                  base64: _photoBase64,
                                  fallbackInitials: widget.student.initials,
                                  radius: 40,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.surface, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded,
                                      size: 14, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _name,
                          decoration: glassInputDecoration(label: 'Name'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _divisionId,
                          decoration: glassInputDecoration(label: 'Division'),
                          items: widget.divisions
                              .map((d) => DropdownMenuItem(
                                  value: d.id, child: Text(d.label)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _divisionId = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _gender,
                                decoration:
                                    glassInputDecoration(label: 'Gender'),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'male', child: Text('Male')),
                                  DropdownMenuItem(
                                      value: 'female', child: Text('Female')),
                                  DropdownMenuItem(
                                      value: 'other', child: Text('Other')),
                                ],
                                onChanged: (v) => setState(() => _gender = v),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TapScale(
                                onTap: _pickDob,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.bg2,
                                    border:
                                        Border.all(color: AppColors.outline),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.cake_rounded,
                                          size: 18, color: AppColors.muted),
                                      const SizedBox(width: 8),
                                      Text(
                                        _dob == null
                                            ? 'DOB'
                                            : DateFormat('dd MMM yyyy')
                                                .format(_dob!),
                                        style: TextStyle(
                                          color: _dob == null
                                              ? AppColors.muted
                                              : AppColors.text,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _mobile1,
                          keyboardType: TextInputType.phone,
                          decoration: glassInputDecoration(
                              label: 'Mobile #1', icon: Icons.phone_rounded),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _mobile2,
                          keyboardType: TextInputType.phone,
                          decoration: glassInputDecoration(
                              label: 'Mobile #2 (optional)'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _mobile3,
                          keyboardType: TextInputType.phone,
                          decoration: glassInputDecoration(
                              label: 'Mobile #3 (optional)'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _aadhar,
                          keyboardType: TextInputType.number,
                          decoration:
                              glassInputDecoration(label: 'Aadhar number'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _schoolName,
                          decoration:
                              glassInputDecoration(label: 'School name'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _address,
                          decoration: glassInputDecoration(label: 'Address'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _reference,
                          decoration:
                              glassInputDecoration(label: 'Reference (optional)'),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Save',
                onPressed: _busy ? null : _save,
                busy: _busy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
