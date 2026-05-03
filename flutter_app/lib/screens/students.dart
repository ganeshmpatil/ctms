import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/models.dart';
import 'student_detail.dart';

class StudentsScreen extends StatefulWidget {
  final ApiClient api;
  const StudentsScreen({super.key, required this.api});

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
      builder: (_) => _CreateStudentSheet(api: widget.api, divisions: _divisions),
    );
    if (created != null) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _err != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 36),
                              const SizedBox(height: 8),
                              Text(_err!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filtered.isEmpty
                        ? const Center(child: Text('No students'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (ctx, i) {
                                final s = _filtered[i];
                                final div = _divisionsById[s.divisionId];
                                return _StudentTile(
                                  student: s,
                                  divisionLabel: div?.label ?? '—',
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => StudentDetailScreen(
                                        api: widget.api,
                                        student: s,
                                        divisionLabel: div?.label ?? '—',
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: widget.api.user?.role == 'admin' ||
              widget.api.user?.role == 'teacher'
          ? FloatingActionButton(
              onPressed: _openCreate,
              child: const Icon(Icons.add_rounded),
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEEF2FF),
          child: Text(student.initials,
              style: const TextStyle(
                  color: Color(0xFF4F46E5), fontWeight: FontWeight.w700)),
        ),
        title: Text(student.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$divisionLabel${student.guardianPhone != null ? " · ${student.guardianPhone}" : ""}'),
        trailing: const Icon(Icons.chevron_right_rounded),
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
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String? _divisionId;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _divisionId == null) return;
    setState(() => _busy = true);
    try {
      final s = await widget.api.createStudent(
        name: _name.text.trim(),
        divisionId: _divisionId!,
        guardianPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
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
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + inset),
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('New Student',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _divisionId,
              decoration: const InputDecoration(labelText: 'Division'),
              items: widget.divisions
                  .map((d) => DropdownMenuItem(value: d.id, child: Text(d.label)))
                  .toList(),
              onChanged: (v) => setState(() => _divisionId = v),
              validator: (v) => v == null ? 'Pick a division' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Guardian phone (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
