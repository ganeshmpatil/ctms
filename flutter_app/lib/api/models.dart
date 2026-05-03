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

  String get label => 'Std $standard ${medium[0].toUpperCase()}${medium.substring(1)}';
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
  final String divisionId;
  final String? guardianPhone;
  final String? photoUrl;
  final DateTime createdAt;

  Student({
    required this.id,
    required this.name,
    required this.divisionId,
    required this.createdAt,
    this.address,
    this.guardianPhone,
    this.photoUrl,
  });

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        id: j['id'],
        name: j['name'],
        address: j['address'],
        divisionId: j['division_id'],
        guardianPhone: j['guardian_phone'],
        photoUrl: j['photo_url'],
        createdAt: DateTime.parse(j['created_at']),
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
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
