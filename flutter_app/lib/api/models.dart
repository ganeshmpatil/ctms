class AuthUser {
  final String id;
  final String email;
  final String role;

  AuthUser({required this.id, required this.email, required this.role});

  factory AuthUser.fromJson(Map<String, dynamic> j) =>
      AuthUser(id: j['id'], email: j['email'], role: j['role']);
}

class Division {
  final String id;
  final int standard;
  final String medium;

  Division({required this.id, required this.standard, required this.medium});

  factory Division.fromJson(Map<String, dynamic> j) =>
      Division(id: j['id'], standard: j['standard'], medium: j['medium']);

  String get label =>
      'Std $standard ${medium[0].toUpperCase()}${medium.substring(1)}';
}

class Subject {
  final String id;
  final String description;

  Subject({required this.id, required this.description});

  factory Subject.fromJson(Map<String, dynamic> j) =>
      Subject(id: j['id'], description: j['description']);
}

class Student {
  final String id;
  final String name;
  final String? address;
  final String? divisionId;
  final String? mobile1;
  final String? mobile2;
  final String? mobile3;
  final String? photo;
  final String? schoolName;
  final String? aadhar;
  final String? reference;
  final DateTime? dob;
  final String? gender;
  final DateTime createdAt;

  Student({
    required this.id,
    required this.name,
    required this.createdAt,
    this.address,
    this.divisionId,
    this.mobile1,
    this.mobile2,
    this.mobile3,
    this.photo,
    this.schoolName,
    this.aadhar,
    this.reference,
    this.dob,
    this.gender,
  });

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        id: j['id'],
        name: j['name'],
        address: j['address'],
        divisionId: j['division_id'],
        mobile1: j['mobile_1'],
        mobile2: j['mobile_2'],
        mobile3: j['mobile_3'],
        photo: j['photo'],
        schoolName: j['school_name'],
        aadhar: j['aadhar'],
        reference: j['reference'],
        dob: j['dob'] != null ? DateTime.parse(j['dob'] as String) : null,
        gender: j['gender'],
        createdAt: DateTime.parse(j['created_at']),
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// First non-empty mobile number, for compact display.
  String? get primaryMobile {
    for (final m in [mobile1, mobile2, mobile3]) {
      if (m != null && m.isNotEmpty) return m;
    }
    return null;
  }
}

class Attendance {
  final String id;
  final String studentId;
  final DateTime date;
  final bool isPresent;
  final bool isAbsent;
  final String? absentReason;

  Attendance({
    required this.id,
    required this.studentId,
    required this.date,
    required this.isPresent,
    required this.isAbsent,
    this.absentReason,
  });

  factory Attendance.fromJson(Map<String, dynamic> j) => Attendance(
        id: j['id'],
        studentId: j['student_id'],
        date: DateTime.parse(j['date']),
        isPresent: j['is_present'] == true,
        isAbsent: j['is_absent'] == true,
        absentReason: j['absent_reason'],
      );
}

class ResultSubject {
  final String subjectId;
  final double marks;
  final double outOfMarks;

  ResultSubject({
    required this.subjectId,
    required this.marks,
    required this.outOfMarks,
  });

  factory ResultSubject.fromJson(Map<String, dynamic> j) => ResultSubject(
        subjectId: j['subject_id'],
        marks: (j['marks'] as num).toDouble(),
        outOfMarks: (j['out_of_marks'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'subject_id': subjectId,
        'marks': marks,
        'out_of_marks': outOfMarks,
      };
}

class ExamResult {
  final String id;
  final String studentId;
  final int year;
  final int month;
  final double? totalMarks;
  final String? photo;
  final DateTime createdAt;
  final List<ResultSubject> subjects;

  ExamResult({
    required this.id,
    required this.studentId,
    required this.year,
    required this.month,
    required this.createdAt,
    this.totalMarks,
    this.photo,
    this.subjects = const [],
  });

  factory ExamResult.fromJson(Map<String, dynamic> j) => ExamResult(
        id: j['id'],
        studentId: j['student_id'],
        year: j['year'],
        month: j['month'],
        totalMarks: j['total_marks'] == null
            ? null
            : (j['total_marks'] as num).toDouble(),
        photo: j['photo'],
        createdAt: DateTime.parse(j['created_at']),
        subjects: ((j['subjects'] as List?) ?? [])
            .map((e) => ResultSubject.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ResetCounts {
  final int studentsUnassigned;
  final int attendanceDeleted;
  final int resultsDeleted;

  ResetCounts({
    required this.studentsUnassigned,
    required this.attendanceDeleted,
    required this.resultsDeleted,
  });

  factory ResetCounts.fromJson(Map<String, dynamic> j) => ResetCounts(
        studentsUnassigned: (j['students_unassigned'] ?? 0) as int,
        attendanceDeleted: (j['attendance_deleted'] ?? 0) as int,
        resultsDeleted: (j['results_deleted'] ?? 0) as int,
      );
}
