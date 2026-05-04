import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

const _apiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://10.0.2.2:8090',
);
const _tokenKey = 'auth_token';
const _emailKey = 'auth_email';
const _roleKey = 'auth_role';
const _idKey = 'auth_id';

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => 'API $status: $message';
}

class ApiClient {
  String? _token;
  AuthUser? _user;

  AuthUser? get user => _user;
  bool get isLoggedIn => _token != null;
  String get apiBase => _apiBase;

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString(_tokenKey);
    final email = p.getString(_emailKey);
    final role = p.getString(_roleKey);
    final id = p.getString(_idKey);
    if (email != null && role != null && id != null) {
      _user = AuthUser(id: id, email: email, role: role);
    }
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    if (_token == null || _user == null) {
      await p.remove(_tokenKey);
      await p.remove(_emailKey);
      await p.remove(_roleKey);
      await p.remove(_idKey);
      return;
    }
    await p.setString(_tokenKey, _token!);
    await p.setString(_emailKey, _user!.email);
    await p.setString(_roleKey, _user!.role);
    await p.setString(_idKey, _user!.id);
  }

  Future<void> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_apiBase/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    _token = body['token'] as String;
    _user = AuthUser.fromJson(body['user'] as Map<String, dynamic>);
    await _persist();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _persist();
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> _get(String path) async {
    final res = await http.get(Uri.parse('$_apiBase$path'), headers: _headers);
    if (res.statusCode == 401) {
      await logout();
      throw ApiException(401, 'session expired');
    }
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
    return jsonDecode(res.body);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_apiBase$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode == 401) {
      await logout();
      throw ApiException(401, 'session expired');
    }
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
    return jsonDecode(res.body);
  }

  Future<dynamic> _patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$_apiBase$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode == 401) {
      await logout();
      throw ApiException(401, 'session expired');
    }
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
    return jsonDecode(res.body);
  }

  String _errorMessage(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['error'] != null) return body['error'].toString();
    } catch (_) {}
    return res.body.isEmpty ? 'request failed' : res.body;
  }

  Future<List<Division>> divisions() async {
    final list = await _get('/divisions') as List;
    return list.map((j) => Division.fromJson(j)).toList();
  }

  Future<Division> createDivision({required int standard, required String medium}) async {
    final j = await _post('/divisions', {'standard': standard, 'medium': medium});
    return Division.fromJson(j as Map<String, dynamic>);
  }

  Future<Division> updateDivision({
    required String id,
    int? standard,
    String? medium,
  }) async {
    final body = <String, dynamic>{};
    if (standard != null) body['standard'] = standard;
    if (medium != null) body['medium'] = medium;
    final j = await _patch('/divisions/$id', body);
    return Division.fromJson(j as Map<String, dynamic>);
  }

  Future<void> deleteDivision(String id) async {
    await _delete('/divisions/$id');
  }

  Future<List<Subject>> subjects() async {
    final list = await _get('/subjects') as List;
    return list.map((j) => Subject.fromJson(j)).toList();
  }

  Future<Subject> createSubject({
    required String description,
    bool isEnglish = false,
    bool isHindi = false,
  }) async {
    final j = await _post('/subjects', {
      'description': description,
      'is_english': isEnglish,
      'is_hindi': isHindi,
    });
    return Subject.fromJson(j as Map<String, dynamic>);
  }

  Future<void> deleteSubject(String id) async {
    await _delete('/subjects/$id');
  }

  // Leads
  Future<List<Lead>> leads({String? status}) async {
    final qs = status != null ? '?status=$status' : '';
    final list = await _get('/leads$qs') as List;
    return list.map((j) => Lead.fromJson(j)).toList();
  }

  Future<Lead> createLead({
    required String query,
    String? raisedBy,
    String? contactNumber,
    String? comments,
  }) async {
    final j = await _post('/leads', {
      'query': query,
      if (raisedBy != null) 'lead_raised_by': raisedBy,
      if (contactNumber != null) 'lead_raised_by_contact_number': contactNumber,
      if (comments != null) 'comments': comments,
    });
    return Lead.fromJson(j as Map<String, dynamic>);
  }

  Future<Lead> updateLead({
    required String id,
    String? status,
    bool? isResolved,
    String? comments,
  }) async {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status;
    if (isResolved != null) body['is_resolved'] = isResolved;
    if (comments != null) body['comments'] = comments;
    final j = await _patch('/leads/$id', body);
    return Lead.fromJson(j as Map<String, dynamic>);
  }

  Future<void> _delete(String path) async {
    final res =
        await http.delete(Uri.parse('$_apiBase$path'), headers: _headers);
    if (res.statusCode == 401) {
      await logout();
      throw ApiException(401, 'session expired');
    }
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
  }

  Future<List<Student>> students({String? divisionId}) async {
    final qs = divisionId != null ? '?division_id=$divisionId' : '';
    final list = await _get('/students$qs') as List;
    return list.map((j) => Student.fromJson(j)).toList();
  }

  Future<Student> createStudent({
    required String name,
    required String divisionId,
    String? address,
    String? mobile1,
    String? mobile2,
    String? mobile3,
    String? photoBase64,
    String? schoolName,
    String? aadhar,
    String? reference,
    DateTime? dob,
    String? gender,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'division_id': divisionId,
    };
    void put(String k, Object? v) {
      if (v != null) body[k] = v;
    }

    put('address', address);
    put('mobile_1', mobile1);
    put('mobile_2', mobile2);
    put('mobile_3', mobile3);
    put('photo', photoBase64);
    put('school_name', schoolName);
    put('aadhar', aadhar);
    put('reference', reference);
    if (dob != null) body['dob'] = _iso(dob);
    put('gender', gender);

    final j = await _post('/students', body);
    return Student.fromJson(j as Map<String, dynamic>);
  }

  Future<Student> updateStudent({
    required String id,
    String? name,
    String? divisionId,
    String? address,
    String? mobile1,
    String? mobile2,
    String? mobile3,
    String? photoBase64,
    String? schoolName,
    String? aadhar,
    String? reference,
    DateTime? dob,
    String? gender,
  }) async {
    final body = <String, dynamic>{};
    void put(String k, Object? v) {
      if (v != null) body[k] = v;
    }

    put('name', name);
    put('division_id', divisionId);
    put('address', address);
    put('mobile_1', mobile1);
    put('mobile_2', mobile2);
    put('mobile_3', mobile3);
    put('photo', photoBase64);
    put('school_name', schoolName);
    put('aadhar', aadhar);
    put('reference', reference);
    if (dob != null) body['dob'] = _iso(dob);
    put('gender', gender);

    final j = await _patch('/students/$id', body);
    return Student.fromJson(j as Map<String, dynamic>);
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<ExamResult>> results({String? studentId}) async {
    final qs = studentId != null ? '?student_id=$studentId' : '';
    final list = await _get('/results$qs') as List;
    return list.map((j) => ExamResult.fromJson(j)).toList();
  }

  Future<ExamResult> createResult({
    required String studentId,
    required int year,
    required int month,
    double? totalMarks,
    String? photoBase64,
    List<ResultSubject> subjects = const [],
  }) async {
    final j = await _post('/results', {
      'student_id': studentId,
      'year': year,
      'month': month,
      if (totalMarks != null) 'total_marks': totalMarks,
      if (photoBase64 != null) 'photo': photoBase64,
      'subjects': subjects.map((s) => s.toJson()).toList(),
    });
    return ExamResult.fromJson(j as Map<String, dynamic>);
  }

  Future<void> deleteResult(String id) async {
    final res =
        await http.delete(Uri.parse('$_apiBase/results/$id'), headers: _headers);
    if (res.statusCode == 401) {
      await logout();
      throw ApiException(401, 'session expired');
    }
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
  }

  Future<ResetCounts> resetDivision(String divisionId) async {
    final j = await _post('/divisions/$divisionId/reset', {'confirm': true});
    return ResetCounts.fromJson(j as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$_apiBase/me/password'),
      headers: _headers,
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    if (res.statusCode == 401) {
      throw ApiException(401, _errorMessage(res));
    }
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
  }

  Future<List<AuthUser>> listAuthUsers() async {
    final list = await _get('/admin/users') as List;
    return list
        .map((j) => AuthUser.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> adminResetPassword({
    required String userId,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$_apiBase/admin/users/$userId/reset-password'),
      headers: _headers,
      body: jsonEncode({'new_password': newPassword}),
    );
    if (res.statusCode == 401) {
      await logout();
      throw ApiException(401, 'session expired');
    }
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
  }

  Future<void> deleteStudent(String id) async {
    final res = await http.delete(
      Uri.parse('$_apiBase/students/$id'),
      headers: _headers,
    );
    if (res.statusCode == 401) {
      await logout();
      throw ApiException(401, 'session expired');
    }
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
  }

  Future<List<Attendance>> attendance({String? studentId, String? date}) async {
    final params = <String, String>{};
    if (studentId != null) params['student_id'] = studentId;
    if (date != null) params['date'] = date;
    final qs = params.isEmpty
        ? ''
        : '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    final list = await _get('/attendance$qs') as List;
    return list.map((j) => Attendance.fromJson(j)).toList();
  }

  Future<Attendance> markAttendance({
    required String studentId,
    required DateTime date,
    required bool isPresent,
    String? absentReason,
  }) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final j = await _post('/attendance', {
      'student_id': studentId,
      'date': dateStr,
      'is_present': isPresent,
      'is_absent': !isPresent,
      if (!isPresent && absentReason != null) 'absent_reason': absentReason,
    });
    return Attendance.fromJson(j as Map<String, dynamic>);
  }
}
