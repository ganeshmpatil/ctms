import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../api/client.dart';
import '../api/models.dart';
import '../widgets/glass.dart';
import '../widgets/photo_picker.dart';
import 'student_detail.dart';
import 'students_table.dart';

class StudentsScreen extends StatefulWidget {
  final ApiClient api;
  final String? initialDivisionId;
  const StudentsScreen({super.key, required this.api, this.initialDivisionId});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<Division> _divisions = [];
  List<Student> _students = [];
  String? _selectedDivisionId;
  String _query = '';
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _selectedDivisionId = widget.initialDivisionId;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final divs = await widget.api.divisions();
      final studs = await widget.api.students(divisionId: _selectedDivisionId);
      if (!mounted) return;
      setState(() {
        _divisions = divs;
        _students = studs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e.toString();
        _loading = false;
      });
    }
  }

  List<Student> get _filtered {
    if (_query.isEmpty) return _students;
    final q = _query.toLowerCase();
    return _students.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  Map<String, Division> get _divisionsById =>
      {for (final d in _divisions) d.id: d};

  Future<void> _openCreate() async {
    if (_divisions.isEmpty) return;
    final created = await showModalBottomSheet<Student>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateStudentSheet(api: widget.api, divisions: _divisions),
    );
    if (created != null) await _load();
  }

  Future<void> _confirmYearEndReset() async {
    if (_selectedDivisionId == null) return;
    final div = _divisionsById[_selectedDivisionId!];
    if (div == null) return;

    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Year-end reset',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will:\n'
              '• Delete ALL attendance records for ${div.label} students\n'
              '• Delete ALL results for ${div.label} students\n'
              '• Unassign students from this division (students themselves are preserved)\n\n'
              'This cannot be undone.',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            const Text('Type the division name to confirm:',
                style: TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: glassInputDecoration(label: div.label),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.muted))),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, v, __) => FilledButton(
              onPressed: v.text.trim() == div.label
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Reset'),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final c = await widget.api.resetDivision(_selectedDivisionId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${div.label} reset · ${c.studentsUnassigned} students, ${c.attendanceDeleted} attendance, ${c.resultsDeleted} results cleared'),
      ));
      setState(() => _selectedDivisionId = null);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canMutate = widget.api.user?.role == 'admin' ||
        widget.api.user?.role == 'teacher';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    const Text('Students',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    if (widget.api.user?.role == 'admin' &&
                        _selectedDivisionId != null)
                      TapScale(
                        onTap: _confirmYearEndReset,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.15),
                            border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.restart_alt_rounded,
                                  size: 16, color: AppColors.danger),
                              SizedBox(width: 6),
                              Text('Year-end reset',
                                  style: TextStyle(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: glassInputDecoration(
                    label: 'Search by name…',
                    icon: Icons.search_rounded,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _DivisionChip(
                      label: 'All',
                      selected: _selectedDivisionId == null,
                      onTap: () {
                        setState(() => _selectedDivisionId = null);
                        _load();
                      },
                    ),
                    for (final d in _divisions)
                      _DivisionChip(
                        label: d.label,
                        selected: _selectedDivisionId == d.id,
                        onTap: () {
                          setState(() => _selectedDivisionId = d.id);
                          _load();
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accentA))
                    : _err != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: GlassCard(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        size: 36, color: Colors.white70),
                                    const SizedBox(height: 8),
                                    Text(_err!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    const SizedBox(height: 12),
                                    GradientButton(
                                      label: 'Retry',
                                      onPressed: _load,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : _filtered.isEmpty
                            ? const Center(
                                child: Text('No students',
                                    style: TextStyle(color: AppColors.muted)))
                            : RefreshIndicator(
                                onRefresh: _load,
                                color: AppColors.accentA,
                                backgroundColor: Colors.white,
                                child: _selectedDivisionId != null
                                    ? StudentsTableView(
                                        api: widget.api,
                                        students: _filtered,
                                        divisionLabel: _divisionsById[
                                                    _selectedDivisionId!]
                                                ?.label ??
                                            '—',
                                      )
                                    : ListView.separated(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 8, 16, 100),
                                        itemCount: _filtered.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (ctx, i) {
                                          final s = _filtered[i];
                                          final div =
                                              _divisionsById[s.divisionId];
                                          return _StudentTile(
                                            student: s,
                                            divisionLabel: div?.label ?? '—',
                                            onTap: () async {
                                              final changed =
                                                  await Navigator.of(context)
                                                      .push<bool>(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      StudentDetailScreen(
                                                    api: widget.api,
                                                    student: s,
                                                    divisionLabel:
                                                        div?.label ?? '—',
                                                  ),
                                                ),
                                              );
                                              if (changed == true) await _load();
                                            },
                                          );
                                        },
                                      ),
                              ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: canMutate
          ? Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: GradientButton(
                label: 'Add',
                icon: Icons.add_rounded,
                onPressed: _openCreate,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            )
          : null,
    );
  }
}

class _DivisionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DivisionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: TapScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [AppColors.accentA, AppColors.accentB])
                : null,
            color: selected ? null : AppColors.glassFill,
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppColors.glassStroke,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.accentA.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final Student student;
  final String divisionLabel;
  final VoidCallback onTap;

  const _StudentTile({
    required this.student,
    required this.divisionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentC, AppColors.accentA],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(student.initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '$divisionLabel${student.primaryMobile != null ? " · ${student.primaryMobile}" : ""}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _CreateStudentSheet extends StatefulWidget {
  final ApiClient api;
  final List<Division> divisions;
  const _CreateStudentSheet({required this.api, required this.divisions});

  @override
  State<_CreateStudentSheet> createState() => _CreateStudentSheetState();
}

class _CreateStudentSheetState extends State<_CreateStudentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile1 = TextEditingController();
  final _mobile2 = TextEditingController();
  final _mobile3 = TextEditingController();
  final _address = TextEditingController();
  final _aadhar = TextEditingController();
  final _schoolName = TextEditingController();
  final _reference = TextEditingController();
  String? _divisionId;
  String? _gender;
  DateTime? _dob;
  String? _photoBase64;
  bool _busy = false;

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
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentA,
            onPrimary: Colors.white,
            surface: AppColors.bg2,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _dob = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _divisionId == null) return;
    setState(() => _busy = true);
    try {
      final s = await widget.api.createStudent(
        name: _name.text.trim(),
        divisionId: _divisionId!,
        mobile1: _mobile1.text.trim().isEmpty ? null : _mobile1.text.trim(),
        mobile2: _mobile2.text.trim().isEmpty ? null : _mobile2.text.trim(),
        mobile3: _mobile3.text.trim().isEmpty ? null : _mobile3.text.trim(),
        aadhar: _aadhar.text.trim().isEmpty ? null : _aadhar.text.trim(),
        schoolName: _schoolName.text.trim().isEmpty ? null : _schoolName.text.trim(),
        reference: _reference.text.trim().isEmpty ? null : _reference.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        photoBase64: _photoBase64,
        dob: _dob,
        gender: _gender,
      );
      if (!mounted) return;
      Navigator.of(context).pop(s);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + inset),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        tint: AppColors.bg2.withValues(alpha: 0.85),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text('New student',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Center(
                  child: TapScale(
                    onTap: _pickPhoto,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        PhotoAvatar(
                          base64: _photoBase64,
                          fallbackInitials: '+',
                          radius: 44,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.accentA, AppColors.accentB],
                            ),
                            shape: BoxShape.circle,
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
                  style: const TextStyle(color: Colors.white),
                  decoration: glassInputDecoration(label: 'Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _divisionId,
                  dropdownColor: AppColors.bg2,
                  style: const TextStyle(color: Colors.white),
                  iconEnabledColor: Colors.white70,
                  decoration: glassInputDecoration(label: 'Division'),
                  items: widget.divisions
                      .map((d) =>
                          DropdownMenuItem(value: d.id, child: Text(d.label)))
                      .toList(),
                  onChanged: (v) => setState(() => _divisionId = v),
                  validator: (v) => v == null ? 'Pick a division' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        dropdownColor: AppColors.bg2,
                        style: const TextStyle(color: Colors.white),
                        iconEnabledColor: Colors.white70,
                        decoration: glassInputDecoration(label: 'Gender'),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(value: 'female', child: Text('Female')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
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
                            color: const Color(0x14FFFFFF),
                            border: Border.all(color: AppColors.glassStroke),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cake_rounded,
                                  size: 18, color: AppColors.muted),
                              const SizedBox(width: 8),
                              Text(
                                _dob == null
                                    ? 'Date of birth'
                                    : DateFormat('dd MMM yyyy').format(_dob!),
                                style: TextStyle(
                                  color: _dob == null
                                      ? AppColors.muted
                                      : Colors.white,
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
                  style: const TextStyle(color: Colors.white),
                  decoration: glassInputDecoration(
                      label: 'Mobile #1', icon: Icons.phone_rounded),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mobile2,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      glassInputDecoration(label: 'Mobile #2 (optional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mobile3,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      glassInputDecoration(label: 'Mobile #3 (optional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _aadhar,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: glassInputDecoration(label: 'Aadhar number'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _schoolName,
                  style: const TextStyle(color: Colors.white),
                  decoration: glassInputDecoration(label: 'School name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      glassInputDecoration(label: 'Address (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reference,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      glassInputDecoration(label: 'Reference (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Save',
                  onPressed: _busy ? null : _submit,
                  busy: _busy,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
