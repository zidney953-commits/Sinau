import 'package:get/get.dart';

import '../core/api.dart';
import '../data/models.dart';

class AuthController extends GetxController {
  final profile = Rxn<Profile>();
  final loading = false.obs;

  Api get api => Api.i;

  /// Dipanggil saat splash: pulihkan sesi lalu arahkan ke halaman sesuai role.
  Future<void> boot() async {
    final ok = await api.restore();
    if (ok && await loadProfile()) {
      goHome();
    } else {
      Get.offAllNamed('/login');
    }
  }

  Future<bool> loadProfile() async {
    try {
      final rows = await api.select('profiles', {'id': 'eq.${api.userId}', 'select': '*'});
      if (rows.isEmpty) return false;
      final p = Profile.fromJson(rows.first);
      if (!p.active) {
        await api.signOut();
        throw ApiException('Akun kamu dinonaktifkan admin.');
      }
      profile.value = p;
      return true;
    } on ApiException {
      rethrow;
    } catch (_) {
      return false;
    }
  }

  void goHome() => Get.offAllNamed(profile.value!.isAdmin ? '/admin' : '/user');

  Future<String?> signIn(String email, String password) async {
    loading.value = true;
    try {
      await api.signIn(email.trim().toLowerCase(), password);
      if (!await loadProfile()) return 'Profil tidak ditemukan.';
      goHome();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      loading.value = false;
    }
  }

  /// Angkatan tidak diisi pengguna: server mengisinya otomatis dengan tahun saat mendaftar.
  Future<String?> signUp(String name, String email, String password) async {
    loading.value = true;
    try {
      final direct = await api.signUp(email.trim().toLowerCase(), password, {'name': name.trim()});
      if (!direct) return 'CONFIRM';
      if (!await loadProfile()) return 'Profil tidak ditemukan.';
      goHome();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> signOut() async {
    await api.signOut();
    profile.value = null;
    Get.offAllNamed('/login');
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final rows = await api.update('profiles', {'id': 'eq.${api.userId}'}, data);
    if (rows.isNotEmpty) profile.value = Profile.fromJson(rows.first);
  }
}
