import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/client.dart';
import '../api/models.dart';
import '../widgets/glass.dart';

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
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
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

  int get _presentCount => _present.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: SafeArea(
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
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
                                  style:
                                      const TextStyle(color: Colors.white)),
                              const SizedBox(height: 12),
                              GradientButton(
                                label: 'Retry',
                                onPressed: _loadDivisions,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                          child: Row(
                            children: [
                              Text('Roll Call',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                          child: GlassCard(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _divisionId,
                                      dropdownColor: AppColors.bg2,
                                      iconEnabledColor: Colors.white70,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600),
                                      isExpanded: true,
                                      items: _divisions
                                          .map((d) => DropdownMenuItem(
                                              value: d.id,
                                              child: Text(d.label)))
                                          .toList(),
                                      onChanged: (v) {
                                        setState(() => _divisionId = v);
                                        _loadStudents();
                                      },
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 28,
                                  width: 1,
                                  color: AppColors.glassStroke,
                                ),
                                const SizedBox(width: 8),
                                TapScale(
                                  onTap: _pickDate,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.event_rounded,
                                            color: Colors.white70, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          DateFormat('dd MMM').format(_date),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.success,
                                        AppColors.accent
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.fact_check_rounded,
                                      color: Colors.white,
                                      size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '$_presentCount present · ${_students.length - _presentCount} absent',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: _students.isEmpty
                              ? const Center(
                                  child: Text('No students in this division',
                                      style: TextStyle(color: AppColors.muted)))
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 8, 16, 100),
                                  itemCount: _students.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (ctx, i) {
                                    final s = _students[i];
                                    final isPresent = _present[s.id] ?? true;
                                    return GlassCard(
                                      padding: const EdgeInsets.all(12),
                                      onTap: () => setState(
                                          () => _present[s.id] = !isPresent),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isPresent
                                                    ? [
                                                        AppColors.success,
                                                        AppColors.accent
                                                      ]
                                                    : [
                                                        AppColors.danger,
                                                        AppColors.primary
                                                      ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Text(s.initials,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    fontSize: 14)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(s.name,
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                const SizedBox(height: 2),
                                                Text(
                                                    isPresent
                                                        ? 'Present'
                                                        : 'Absent',
                                                    style: TextStyle(
                                                        color: isPresent
                                                            ? AppColors.success
                                                            : AppColors.danger,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                          Switch.adaptive(
                                            value: isPresent,
                                            activeColor: AppColors.success,
                                            onChanged: (v) => setState(
                                                () => _present[s.id] = v),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
        ),
      ),
      bottomNavigationBar: _students.isEmpty || _loading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                child: GradientButton(
                  label: _saving
                      ? 'Saving…'
                      : 'Save attendance for ${DateFormat('dd MMM').format(_date)}',
                  icon: Icons.save_rounded,
                  onPressed: _saving ? null : _save,
                  busy: _saving,
                ),
              ),
            ),
    );
  }
}
