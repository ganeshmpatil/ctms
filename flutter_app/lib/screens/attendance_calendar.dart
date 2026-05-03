import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/client.dart';
import '../api/models.dart';
import '../widgets/glass.dart';

/// Calendar view of a single student's attendance for a chosen month.
/// Tapping a day toggles present/absent for admin/teacher.
class AttendanceCalendarView extends StatefulWidget {
  final ApiClient api;
  final Student student;
  const AttendanceCalendarView({
    super.key,
    required this.api,
    required this.student,
  });

  @override
  State<AttendanceCalendarView> createState() => _AttendanceCalendarViewState();
}

class _AttendanceCalendarViewState extends State<AttendanceCalendarView> {
  late int _year;
  late int _month;
  Map<DateTime, Attendance> _byDate = {};
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final all = await widget.api.attendance(studentId: widget.student.id);
      if (!mounted) return;
      _byDate = {
        for (final a in all)
          DateTime(a.date.year, a.date.month, a.date.day): a,
      };
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggle(DateTime day) async {
    final canMutate = widget.api.user?.role == 'admin' ||
        widget.api.user?.role == 'teacher';
    if (!canMutate) return;
    final existing = _byDate[day];
    final markPresent = !(existing?.isPresent ?? false);
    try {
      await widget.api.markAttendance(
        studentId: widget.student.id,
        date: day,
        isPresent: markPresent,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_err != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_err!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.text)),
                const SizedBox(height: 12),
                GradientButton(label: 'Retry', onPressed: _load),
              ],
            ),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _MonthYearPicker(
          year: _year,
          month: _month,
          onChanged: (y, m) => setState(() {
            _year = y;
            _month = m;
          }),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(12),
          child: _CalendarGrid(
            year: _year,
            month: _month,
            attendance: _byDate,
            onTap: _toggle,
          ),
        ),
        const SizedBox(height: 16),
        const _Legend(),
      ],
    );
  }
}

class _MonthYearPicker extends StatelessWidget {
  final int year;
  final int month;
  final void Function(int year, int month) onChanged;

  const _MonthYearPicker({
    required this.year,
    required this.month,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.muted,
            onPressed: () {
              var y = year, m = month - 1;
              if (m < 1) {
                m = 12;
                y -= 1;
              }
              onChanged(y, m);
            },
          ),
          Expanded(
            child: Center(
              child: Text(
                DateFormat('MMMM yyyy').format(DateTime(year, month)),
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.muted,
            onPressed: () {
              var y = year, m = month + 1;
              if (m > 12) {
                m = 1;
                y += 1;
              }
              onChanged(y, m);
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final Map<DateTime, Attendance> attendance;
  final void Function(DateTime) onTap;

  const _CalendarGrid({
    required this.year,
    required this.month,
    required this.attendance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Monday = 1 ... Sunday = 7. Make grid start on Sun for India convention.
    final leadingBlanks = firstDay.weekday % 7;

    final cells = <Widget>[];
    for (final dow in const ['S', 'M', 'T', 'W', 'T', 'F', 'S']) {
      cells.add(Center(
        child: Text(
          dow,
          style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700),
        ),
      ));
    }
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(year, month, d);
      final att = attendance[day];
      cells.add(_DayCell(
        day: d,
        attendance: att,
        isToday: _isSameDay(day, DateTime.now()),
        onTap: () => onTap(day),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: cells,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayCell extends StatelessWidget {
  final int day;
  final Attendance? attendance;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.attendance,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.bg2;
    Color fg = AppColors.text;
    Widget? overlay;

    if (attendance?.isPresent == true) {
      bg = AppColors.successLight;
      fg = AppColors.success;
      overlay = const Positioned(
        right: 4,
        top: 4,
        child:
            Icon(Icons.check_rounded, color: AppColors.success, size: 12),
      );
    } else if (attendance?.isAbsent == true) {
      bg = AppColors.dangerLight;
      fg = AppColors.danger;
      overlay = const Positioned(
        right: 4,
        top: 4,
        child: Icon(Icons.close_rounded, color: AppColors.danger, size: 12),
      );
    }

    return TapScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: isToday
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight:
                      isToday ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            if (overlay != null) overlay,
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _LegendChip(
            color: AppColors.success,
            bg: AppColors.successLight,
            label: 'Present'),
        _LegendChip(
            color: AppColors.danger,
            bg: AppColors.dangerLight,
            label: 'Absent'),
        _LegendChip(
            color: AppColors.text, bg: AppColors.bg2, label: 'No record'),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final Color bg;
  final String label;
  const _LegendChip({
    required this.color,
    required this.bg,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
