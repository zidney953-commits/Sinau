import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

/// Klien Supabase REST API (Auth, PostgREST, Storage) memakai package http.
class Api {
  Api._();
  static final Api i = Api._();

  String? accessToken;
  String? refreshToken;
  String? userId;
  DateTime? expiresAt;

  // ---------------- Sesi ----------------
  Future<bool> restore() async {
    final p = await SharedPreferences.getInstance();
    accessToken = p.getString('at');
    refreshToken = p.getString('rt');
    userId = p.getString('uid');
    final exp = p.getInt('exp');
    expiresAt = exp == null ? null : DateTime.fromMillisecondsSinceEpoch(exp);
    if (refreshToken == null) return false;
    try {
      await _ensureFresh();
      return true;
    } catch (_) {
      await clear();
      return false;
    }
  }

  Future<void> _save(Map<String, dynamic> j) async {
    accessToken = j['access_token'];
    refreshToken = j['refresh_token'];
    userId = j['user']?['id'] ?? userId;
    expiresAt = DateTime.now().add(Duration(seconds: (j['expires_in'] ?? 3600) as int));
    final p = await SharedPreferences.getInstance();
    await p.setString('at', accessToken!);
    await p.setString('rt', refreshToken!);
    await p.setString('uid', userId!);
    await p.setInt('exp', expiresAt!.millisecondsSinceEpoch);
  }

  Future<void> clear() async {
    accessToken = refreshToken = userId = null;
    expiresAt = null;
    final p = await SharedPreferences.getInstance();
    for (final k in ['at', 'rt', 'uid', 'exp']) {
      await p.remove(k);
    }
  }

  Future<void> _ensureFresh() async {
    if (refreshToken == null) return;
    if (accessToken != null && expiresAt != null && expiresAt!.isAfter(DateTime.now().add(const Duration(minutes: 1)))) return;
    final r = await http.post(Uri.parse('${AppConfig.authUrl}/token?grant_type=refresh_token'),
        headers: _base(), body: jsonEncode({'refresh_token': refreshToken}));
    if (r.statusCode != 200) throw ApiException('Sesi berakhir, silakan masuk lagi.', r.statusCode);
    await _save(jsonDecode(r.body));
  }

  Map<String, String> _base() => {'apikey': AppConfig.publishableKey, 'Content-Type': 'application/json'};

  Future<Map<String, String>> _headers([Map<String, String>? extra]) async {
    await _ensureFresh();
    return {..._base(), if (accessToken != null) 'Authorization': 'Bearer $accessToken', ...?extra};
  }

  // ---------------- Auth ----------------
  Future<void> signIn(String email, String password) async {
    final r = await http.post(Uri.parse('${AppConfig.authUrl}/token?grant_type=password'),
        headers: _base(), body: jsonEncode({'email': email, 'password': password}));
    if (r.statusCode != 200) throw ApiException(_authError(r), r.statusCode);
    await _save(jsonDecode(r.body));
  }

  /// Mengembalikan true jika langsung masuk, false jika perlu konfirmasi email.
  Future<bool> signUp(String email, String password, Map<String, dynamic> meta) async {
    final r = await http.post(Uri.parse('${AppConfig.authUrl}/signup'),
        headers: _base(), body: jsonEncode({'email': email, 'password': password, 'data': meta}));
    if (r.statusCode != 200) throw ApiException(_authError(r), r.statusCode);
    final j = jsonDecode(r.body);
    if (j['access_token'] != null) {
      await _save(j);
      return true;
    }
    return false;
  }

  // ---------- Lupa kata sandi (OTP lewat email) ----------
  /// Kirim kode OTP ke email. Supabase selalu menjawab sukses walau email tidak terdaftar (mencegah tebak-tebakan akun).
  Future<void> sendRecoveryCode(String email) async {
    final r = await http.post(Uri.parse('${AppConfig.authUrl}/recover'), headers: _base(), body: jsonEncode({'email': email}));
    if (r.statusCode != 200) throw ApiException(_authError(r), r.statusCode);
  }

  /// Cocokkan kode OTP. Jika benar, pengguna langsung punya sesi untuk mengganti kata sandi.
  Future<void> verifyRecoveryCode(String email, String code) async {
    final r = await http.post(Uri.parse('${AppConfig.authUrl}/verify'),
        headers: _base(), body: jsonEncode({'type': 'recovery', 'email': email, 'token': code}));
    if (r.statusCode != 200) {
      final msg = _authError(r);
      throw ApiException(msg.contains('expired') || msg.contains('invalid') || r.statusCode == 403 ? 'Kode salah atau sudah kedaluwarsa.' : msg, r.statusCode);
    }
    await _save(jsonDecode(r.body));
  }

  Future<void> updatePassword(String password) async {
    final r = await http.put(Uri.parse('${AppConfig.authUrl}/user'), headers: await _headers(), body: jsonEncode({'password': password}));
    if (r.statusCode != 200) {
      final msg = _authError(r);
      throw ApiException(msg.contains('different') || msg.contains('same') ? 'Kata sandi baru harus berbeda dari yang lama.' : msg, r.statusCode);
    }
  }

  Future<void> signOut() async {
    try {
      await http.post(Uri.parse('${AppConfig.authUrl}/logout'), headers: await _headers());
    } catch (_) {}
    await clear();
  }

  String _authError(http.Response r) {
    try {
      final j = jsonDecode(r.body);
      final code = (j['error_code'] ?? j['code'] ?? '').toString();
      final msg = (j['msg'] ?? j['error_description'] ?? j['message'] ?? '').toString();
      if (code == 'invalid_credentials' || msg.contains('Invalid login')) return 'Email atau kata sandi salah.';
      if (code == 'email_not_confirmed') return 'Email belum dikonfirmasi. Cek kotak masuk email kamu.';
      if (code == 'user_already_exists' || msg.contains('already registered')) return 'Email ini sudah terdaftar.';
      if (code == 'weak_password') return 'Kata sandi terlalu lemah.';
      if (r.statusCode == 429 || code == 'over_email_send_rate_limit') return 'Terlalu banyak permintaan. Tunggu sebentar lalu coba lagi.';
      if (code == 'otp_expired') return 'Kode salah atau sudah kedaluwarsa.';
      if (code == 'same_password') return 'Kata sandi baru harus berbeda dari yang lama.';
      return msg.isNotEmpty ? msg : 'Terjadi kesalahan (${r.statusCode}).';
    } catch (_) {
      return 'Terjadi kesalahan (${r.statusCode}).';
    }
  }

  // ---------------- REST (PostgREST) ----------------
  Future<List<Map<String, dynamic>>> select(String table, [Map<String, String>? query]) async {
    final r = await http.get(Uri.parse('${AppConfig.restUrl}/$table').replace(queryParameters: query), headers: await _headers());
    _check(r);
    return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> insert(String table, Object body, {String? onConflict}) async {
    final r = await http.post(
      Uri.parse('${AppConfig.restUrl}/$table').replace(queryParameters: onConflict == null ? null : {'on_conflict': onConflict}),
      headers: await _headers({'Prefer': 'return=representation${onConflict != null ? ',resolution=merge-duplicates' : ''}'}),
      body: jsonEncode(body),
    );
    _check(r);
    return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> update(String table, Map<String, String> filter, Map<String, dynamic> body) async {
    final r = await http.patch(Uri.parse('${AppConfig.restUrl}/$table').replace(queryParameters: filter),
        headers: await _headers({'Prefer': 'return=representation'}), body: jsonEncode(body));
    _check(r);
    return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
  }

  Future<void> delete(String table, Map<String, String> filter) async {
    final r = await http.delete(Uri.parse('${AppConfig.restUrl}/$table').replace(queryParameters: filter), headers: await _headers());
    _check(r);
  }

  void _check(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    String msg = 'Gagal memuat data (${r.statusCode}).';
    try {
      final j = jsonDecode(r.body);
      if (j is Map && j['message'] != null) msg = j['message'];
    } catch (_) {}
    if (r.statusCode == 401) msg = 'Sesi berakhir, silakan masuk lagi.';
    throw ApiException(msg, r.statusCode);
  }

  // ---------------- Storage ----------------
  /// Unggah foto profil ke bucket avatars/{userId}/avatar.jpg dan kembalikan URL publiknya.
  Future<String> uploadAvatar(Uint8List bytes, String contentType) async {
    final path = '$userId/avatar.jpg';
    final r = await http.post(Uri.parse('${AppConfig.storageUrl}/object/avatars/$path'),
        headers: await _headers({'Content-Type': contentType, 'x-upsert': 'true'}), body: bytes);
    _check(r);
    return '${AppConfig.storageUrl}/object/public/avatars/$path?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> deleteAvatar() async {
    final r = await http.delete(Uri.parse('${AppConfig.storageUrl}/object/avatars'),
        headers: await _headers(), body: jsonEncode({'prefixes': ['$userId/avatar.jpg']}));
    _check(r);
  }
}
