import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/client.dart';
import '../api/models.dart';
import '../widgets/glass.dart';
import '../widgets/photo_picker.dart';
import 'student_detail.dart';

/// Tabular view of students for a single division. Each row is tappable
/// and navigates to the 360° detail screen.
class StudentsTableView extends StatelessWidget {
  final ApiClient api;
  final List<Student> students;
  final String divisionLabel;

  const StudentsTableView({
    super.key,
    required this.api,
    required this.students,
    required this.divisionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.06)),
              dataRowMinHeight: 56,
              dataRowMaxHeight: 64,
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.4,
              ),
              dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
              dividerThickness: 0.4,
              columns: const [
                DataColumn(label: Text('PHOTO')),
                DataColumn(label: Text('NAME')),
                DataColumn(label: Text('GENDER')),
                DataColumn(label: Text('DOB')),
                DataColumn(label: Text('MOBILE')),
                DataColumn(label: Text('AADHAR')),
              ],
              rows: students.map((s) {
                return DataRow(
                  onSelectChanged: (_) => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudentDetailScreen(
                        api: api,
                        student: s,
                        divisionLabel: divisionLabel,
                      ),
                    ),
                  ),
                  cells: [
                    DataCell(PhotoAvatar(
                      base64: s.photo,
                      fallbackInitials: s.initials,
                      radius: 16,
                    )),
                    DataCell(SizedBox(
                      width: 130,
                      child: Text(s.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    )),
                    DataCell(Text(_genderShort(s.gender))),
                    DataCell(Text(s.dob == null
                        ? '—'
                        : DateFormat('dd MMM yyyy').format(s.dob!))),
                    DataCell(SizedBox(
                      width: 120,
                      child: Text(s.primaryMobile ?? '—',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    )),
                    DataCell(SizedBox(
                      width: 110,
                      child: Text(s.aadhar ?? '—',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _genderShort(String? g) {
    switch (g) {
      case 'male':
        return 'M';
      case 'female':
        return 'F';
      case 'other':
        return 'O';
      default:
        return '—';
    }
  }
}
