import 'package:get/get.dart';

import '../data/models.dart';
import '../data/repo.dart';
import '../data/streak.dart';
import 'auth_controller.dart';

/// Dasar semua controller yang memuat data dari REST API.
/// State-nya reaktif (.obs): data, loading, error → dibaca layar lewat Obx (lihat ObxLoad).
abstract class LoadController<T> extends GetxController {
  final data = Rxn<T>();
  final loading = false.obs;
  final error = RxnString();

  /// Permintaan ke REST API (diisi oleh tiap controller turunan).
  Future<T> fetch();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      data.value = await fetch();
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }
}

/// Tab aktif di menu bawah / samping.
class NavController extends GetxController {
  final tab = 0.obs;
  void go(int i) => tab.value = i;
}

// ============================ USER ============================

class LearnData {
  final List<Language> langs;
  final Map<String, List<Unit>> units;
  final Map<int, LessonProgress> prog;
  final List<Map<String, dynamic>> done;
  LearnData(this.langs, this.units, this.prog, this.done) : streak = StreakInfo.from(done);

  /// Streak & XP per hari (tanggal lokal), dihitung dari riwayat lulus.
  final StreakInfo streak;
  int get xpToday => streak.xpToday;
  int get xpTotal => prog.values.fold(0, (a, p) => a + p.xpEarned);
}

/// Bahasa, tugas, pembahasan, dan progres user (dipakai Belajar, Beranda bahasa, Daftar pembahasan).
class LearnController extends LoadController<LearnData> {
  @override
  Future<LearnData> fetch() async {
    final langs = await Repo.languages();
    final units = {for (final l in langs) l.id: await Repo.units(l.id)};
    final d = LearnData(langs, units, await Repo.myProgress(), await Repo.myCompletions());
    _syncStreak(d.streak);
    return d;
  }

  /// Simpan streak hasil hitungan ke profil (dipakai papan peringkat & data admin).
  void _syncStreak(StreakInfo s) {
    final auth = Get.find<AuthController>();
    final p = auth.profile.value;
    final last = s.lastActive?.toIso8601String().substring(0, 10);
    if (p == null || (p.streak == s.current && p.lastActive == last)) return;
    auth.updateProfile({'streak': s.current, 'last_active': last}).catchError((_) {});
  }
}

/// Peringkat per bahasa.
class RankController extends LoadController<List<Map<String, dynamic>>> {
  final lang = 'python'.obs;
  String get langName => lang.value == 'python' ? 'Python' : 'Java';

  @override
  Future<List<Map<String, dynamic>>> fetch() => Repo.leaderboard(lang.value);

  void setLang(String l) {
    lang.value = l;
    load();
  }
}

/// Tab Informasi (user membaca, admin menambah & menghapus).
class InfoController extends LoadController<List<Post>> {
  @override
  Future<List<Post>> fetch() => Repo.posts();

  Future<void> add(String category, String title, String body, bool pinned) async {
    await Repo.addPost(category, title, body, pinned);
    await load();
  }

  Future<void> remove(int id) async {
    await Repo.deletePost(id);
    await load();
  }
}

// ============================ ADMIN ============================

class DashData {
  final List<Profile> members;
  final List<Language> langs;
  final Map<String, List<Unit>> units;
  final List<Map<String, dynamic>> prog;
  DashData(this.members, this.langs, this.units, this.prog);
}

class DashboardController extends LoadController<DashData> {
  final lang = 'python'.obs;
  final showSignupTable = false.obs;
  final showSkillTable = false.obs;

  @override
  Future<DashData> fetch() async {
    final langs = await Repo.languages();
    return DashData(await Repo.members(), langs, {for (final l in langs) l.id: await Repo.units(l.id)}, await Repo.allProgress());
  }
}

/// Kelola materi: CRUD tugas & pembahasan.
class ContentController extends LoadController<List<Unit>> {
  final lang = 'python'.obs;

  @override
  Future<List<Unit>> fetch() => Repo.units(lang.value);

  void setLang(String l) {
    lang.value = l;
    load();
  }

  Future<void> addUnit(String title) async {
    await Repo.addUnit(lang.value, title, data.value?.length ?? 0);
    await load();
  }

  Future<void> renameUnit(int id, String title) async {
    await Repo.renameUnit(id, title);
    await load();
  }

  Future<void> deleteUnit(int id) async {
    await Repo.deleteUnit(id);
    await load();
  }

  Future<void> deleteLesson(int id) async {
    await Repo.deleteLesson(id);
    await load();
  }

  /// Terbit / draf langsung berubah di layar, dikembalikan jika request gagal.
  Future<void> setPublished(Lesson l, bool v) async {
    l.published = v;
    data.refresh();
    try {
      await Repo.setPublished(l.id, v);
    } catch (_) {
      l.published = !v;
      data.refresh();
      rethrow;
    }
  }
}

class MembersController extends LoadController<List<Profile>> {
  final query = ''.obs;
  final year = RxnInt();

  @override
  Future<List<Profile>> fetch() => Repo.members();

  List<int> get years => (data.value ?? []).map((m) => m.angkatan).whereType<int>().toSet().toList()..sort();
  List<Profile> get filtered => (data.value ?? [])
      .where((m) => m.name.toLowerCase().contains(query.value.toLowerCase()) && (year.value == null || m.angkatan == year.value))
      .toList();

  Future<void> toggleActive(Profile m) async {
    await Repo.setActive(m.id, !m.active);
    await load();
  }
}

class FeedbackController extends LoadController<List<FeedbackItem>> {
  final filter = 'all'.obs;

  @override
  Future<List<FeedbackItem>> fetch() => Repo.feedback();

  /// Angka badge di menu Masukan.
  int get newCount => (data.value ?? []).where((f) => f.status == 'baru').length;
  List<FeedbackItem> get filtered => filter.value == 'all' ? (data.value ?? []) : (data.value ?? []).where((f) => f.status == filter.value).toList();

  Future<void> setStatus(int id, String status) async {
    await Repo.setFeedbackStatus(id, status);
    await load();
  }
}

// ============================ Binding per route ============================

class UserBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NavController());
    Get.put(LearnController());
    Get.put(RankController());
    Get.put(InfoController());
  }
}

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NavController());
    Get.put(DashboardController());
    Get.put(ContentController());
    Get.put(MembersController());
    Get.put(FeedbackController());
    Get.put(InfoController());
  }
}

/// Halaman detail streak: bulan & tahun kalender yang sedang dilihat.
class StreakController extends GetxController {
  final month = DateTime.utc(DateTime.now().year, DateTime.now().month).obs;
  DateTime get thisMonth => DateTime.utc(DateTime.now().year, DateTime.now().month);
  bool get canNext => month.value.isBefore(thisMonth);

  void shift(int n) {
    final m = DateTime.utc(month.value.year, month.value.month + n);
    if (!m.isAfter(thisMonth)) month.value = m;
  }

  void setMonth(int m) => _set(DateTime.utc(month.value.year, m));
  void setYear(int y) => _set(DateTime.utc(y, month.value.month));
  void _set(DateTime m) => month.value = m.isAfter(thisMonth) ? thisMonth : m;
}
