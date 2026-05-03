import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/client.dart';
import '../api/models.dart';

class RollCallScreen extends StatefulWidget {
  final ApiClient api;
  const RollCallScreen({super.key, required this.api});

  @override
  State<RollCallScreen> createState() => _RollCallScreenState();
}

class _RollCallScreenState extends State<RollCallScreen> {
  List<Division> _divisions = [];
  List<Student> _students = [];
  String? _divisionId;
  DateTime _date = DateTime.now();
  final Map<String, bool> _present = {};
  bool _loading = true;
  bool _saving = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _loadDivisions();
  }

  Future<void> _loadDivisions() async {
    try {
      final divs = await widget.api.divisions();
      if (!mounted) return;
      setState(() {
        _divisions = divs;
        if (divs.isNotEmpty) _divisionId = divs.first.id;
        _loading = false;
      });
      if (_divisionId != null) await _loadStudents();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadStudents() async {
    if (_divisionId == null) return;
    setState(() => _loading = true);
    try {
      final studs = await widget.api.students(divisionId: _divisionId);
      if (!mounted) return;
      setState(() {
        _students = studs;
        _present.clear();
        for (final s in studs) {
          _present[s.id] = true;
        }
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

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      for (final s in _students) {
        await widget.api.markAttendance(
          studentId: s.id,
          date: _date,
          isPresent: _present[s.id] ?? true,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${_students.length} entries')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int get _presentCount =>
      _present.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roll Call'),
        actions: [
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Date',
          ),
        ],
      ),
      body: _loading
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
                          onPressed: _loadDivisions,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _divisionId,
                              decoration: const InputDecoration(
                                labelText: 'Division',
                                isDense: true,
                              ),
                              items: _divisions
                                  .map((d) => DropdownMenuItem(
                                        value: d.id,
                                        child: Text(d.label),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                setState(() => _divisionId = v);
                                _loadStudents();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.event_rounded, size: 18),
                            label: Text(DateFormat('dd MMM').format(_date)),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.fact_check_rounded,
                                color: Color(0xFF4F46E5)),
                            const SizedBox(width: 8),
                            Text(
                              '$_presentCount present · ${_students.length - _presentCount} absent',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4F46E5)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: _students.isEmpty
                          ? const Center(
                              child: Text('No students in this division'))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                              itemCount: _students.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (ctx, i) {
                                final s = _students[i];
                                final isPresent = _present[s.id] ?? true;
                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFFEEF2FF),
                                      child: Text(s.initials,
                                          style: const TextStyle(
                                              color: Color(0xFF4F46E5),
                                              fontWeight: FontWeight.w700)),
                                    ),
                                    title: Text(s.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    trailing: Switch.adaptive(
                                      value: isPresent,
                                      activeColor: const Color(0xFF059669),
                                      onChanged: (v) =>
                                          setState(() => _present[s.id] = v),
                                    ),
                                    subtitle: Text(isPresent
                                        ? 'Present'
                                        : 'Absent'),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      bottomNavigationBar: _students.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving
                      ? 'Saving...'
                      : 'Save attendance for ${DateFormat('dd MMM').format(_date)}'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
    );
  }
}
