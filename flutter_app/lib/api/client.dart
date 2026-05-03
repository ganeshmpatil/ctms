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

  Future<List<Subject>> subjects() async {
    final list = await _get('/subjects') as List;
    return list.map((j) => Subject.fromJson(j)).toList();
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
    String? guardianPhone,
  }) async {
    final j = await _post('/students', {
      'name': name,
      'division_id': divisionId,
      if (address != null) 'address': address,
      if (guardianPhone != null) 'guardian_phone': guardianPhone,
    });
    return Student.fromJson(j as Map<String, dynamic>);
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
