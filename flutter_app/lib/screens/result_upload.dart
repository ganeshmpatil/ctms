import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/models.dart';
import '../widgets/glass.dart';
import '../widgets/photo_picker.dart';

/// Bottom sheet to add a result for a single student.
/// Returns the created [ExamResult] on save, or null on cancel.
class ResultUploadSheet extends StatefulWidget {
  final ApiClient api;
  final String studentId;
  final String studentName;
  const ResultUploadSheet({
    super.key,
    required this.api,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<ResultUploadSheet> createState() => _ResultUploadSheetState();
}

class _ResultUploadSheetState extends State<ResultUploadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _totalCtrl = TextEditingController();
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  String? _photoBase64;
  bool _busy = false;

  List<Subject> _subjects = [];
  bool _loadingSubjects = true;
  final List<_SubjectRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    try {
      final s = await widget.api.subjects();
      if (!mounted) return;
      setState(() {
        _subjects = s;
        _loadingSubjects = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSubjects = false);
    }
  }

  Future<void> _pickPhoto() async {
    final b64 = await capturePhotoBase64(context);
    if (b64 != null && mounted) setState(() => _photoBase64 = b64);
  }

  void _addSubjectRow() {
    setState(() => _rows.add(_SubjectRow()));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final subjects = <ResultSubject>[];
    for (final r in _rows) {
      if (r.subjectId == null) continue;
      final marks = double.tryParse(r.marksCtrl.text);
      final outOf = double.tryParse(r.outOfCtrl.text);
      if (marks == null || outOf == null) continue;
      subjects.add(ResultSubject(
        subjectId: r.subjectId!,
        marks: marks,
        outOfMarks: outOf,
      ));
    }
    setState(() => _busy = true);
    try {
      final created = await widget.api.createResult(
        studentId: widget.studentId,
        year: _year,
        month: _month,
        totalMarks: _totalCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_totalCtrl.text.trim()),
        photoBase64: _photoBase64,
        subjects: subjects,
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
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
        tint: AppColors.bg2.withValues(alpha: 0.92),
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
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('New result · ${widget.studentName}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _year,
                        dropdownColor: AppColors.bg2,
                        style: const TextStyle(color: Colors.white),
                        iconEnabledColor: Colors.white70,
                        decoration: glassInputDecoration(label: 'Year'),
                        items: List.generate(8, (i) {
                          final y = DateTime.now().year - i;
                          return DropdownMenuItem(value: y, child: Text('$y'));
                        }),
                        onChanged: (v) {
                          if (v != null) setState(() => _year = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _month,
                        dropdownColor: AppColors.bg2,
                        style: const TextStyle(color: Colors.white),
                        iconEnabledColor: Colors.white70,
                        decoration: glassInputDecoration(label: 'Month'),
                        items: List.generate(12, (i) {
                          final m = i + 1;
                          return DropdownMenuItem(
                              value: m, child: Text(_monthName(m)));
                        }),
                        onChanged: (v) {
                          if (v != null) setState(() => _month = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _totalCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      glassInputDecoration(label: 'Total marks (optional)'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Per-subject marks',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TapScale(
                      onTap: _loadingSubjects ? () {} : _addSubjectRow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.glassFill,
                          border: Border.all(color: AppColors.glassStroke),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded,
                                size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Add subject',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_loadingSubjects)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: LinearProgressIndicator(
                        color: AppColors.accentA,
                        backgroundColor: Colors.white12),
                  )
                else
                  Column(
                    children: [
                      for (int i = 0; i < _rows.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _SubjectRowWidget(
                            row: _rows[i],
                            subjects: _subjects,
                            onChanged: () => setState(() {}),
                            onRemove: () => setState(() {
                              _rows[i].dispose();
                              _rows.removeAt(i);
                            }),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                TapScale(
                  onTap: _pickPhoto,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.glassFill,
                      border: Border.all(color: AppColors.glassStroke),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.image_rounded,
                            color: AppColors.muted, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _photoBase64 == null
                                ? 'Attach marksheet photo (optional)'
                                : 'Photo attached (${(_photoBase64!.length / 1024).toStringAsFixed(0)} KB)',
                            style: TextStyle(
                              color: _photoBase64 == null
                                  ? AppColors.muted
                                  : Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (_photoBase64 != null)
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: AppColors.muted),
                            onPressed: () =>
                                setState(() => _photoBase64 = null),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Save result',
                  onPressed: _busy ? null : _save,
                  busy: _busy,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _monthName(int m) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m - 1];
}

class _SubjectRow {
  String? subjectId;
  final marksCtrl = TextEditingController();
  final outOfCtrl = TextEditingController(text: '100');

  void dispose() {
    marksCtrl.dispose();
    outOfCtrl.dispose();
  }
}

class _SubjectRowWidget extends StatelessWidget {
  final _SubjectRow row;
  final List<Subject> subjects;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _SubjectRowWidget({
    required this.row,
    required this.subjects,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: DropdownButtonFormField<String>(
            value: row.subjectId,
            isExpanded: true,
            dropdownColor: AppColors.bg2,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            iconEnabledColor: Colors.white70,
            decoration: glassInputDecoration(label: 'Subject'),
            items: subjects
                .map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.description, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) {
              row.subjectId = v;
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: row.marksCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: glassInputDecoration(label: 'Marks'),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: row.outOfCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: glassInputDecoration(label: '/of'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
          onPressed: onRemove,
        ),
      ],
    );
  }
}
