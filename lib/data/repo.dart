import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api.dart';
import '../core/config.dart';
import 'models.dart';

/// Semua akses data Sinau lewat Supabase REST API.
class Repo {
  static Api get _api => Api.i;

  static Future<List<Language>> languages() async =>
      (await _api.select('languages', {'select': '*', 'order': 'position'})).map(Language.fromJson).toList();

  /// Tugas (units) beserta pembahasannya. Pengguna biasa hanya menerima pembahasan terbit (RLS).
  static Future<List<Unit>> units(String languageId) async => (await _api.select('units', {
        'select': '*,lessons(*)',
        'language_id': 'eq.$languageId',
        'order': 'position',
      }))
          .map(Unit.fromJson)
          .toList();

  static Future<Map<int, LessonProgress>> myProgress() async {
    final rows = await _api.select('lesson_progress', {'user_id': 'eq.${_api.userId}', 'select': '*'});
    return {for (final r in rows) r['lesson_id'] as int: LessonProgress.fromJson(r)};
  }

  static Future<List<Question>> questions(int lessonId) async =>
      (await _api.select('questions', {'lesson_id': 'eq.$lessonId', 'select': '*', 'order': 'position'})).map(Question.fromJson).toList();

  /// Simpan hasil tugas. XP dihitung server (trigger), jadi aplikasi tidak bisa mengirim XP palsu.
  static Future<void> saveProgress(int lessonId, {required bool passed, required int correct, required int total, LessonProgress? prev}) async {
    await _api.insert(
      'lesson_progress',
      {
        'user_id': _api.userId,
        'lesson_id': lessonId,
        'passed': passed || (prev?.passed ?? false),
        'correct': passed || prev == null || !prev.passed ? correct : prev.correct,
        'total': total,
        'attempts': (prev?.attempts ?? 0) + 1,
        'failed_before': !passed || (prev?.failedBefore ?? false),
      },
      onConflict: 'user_id,lesson_id',
    );
  }

  static Future<List<Map<String, dynamic>>> leaderboard(String languageId) =>
      _api.select('leaderboard', {'language_id': 'eq.$languageId', 'select': '*', 'order': 'xp.desc,lessons_done.desc'});

  // ---------- Admin ----------
  static Future<List<Profile>> members() async =>
      (await _api.select('profiles', {'select': '*', 'role': 'eq.user', 'order': 'name'})).map(Profile.fromJson).toList();

  static Future<void> setActive(String userId, bool active) => _api.update('profiles', {'id': 'eq.$userId'}, {'active': active});

  static Future<void> setPublished(int lessonId, bool published) => _api.update('lessons', {'id': 'eq.$lessonId'}, {'published': published});

  // ---------- Admin: kelola materi ----------
  static Future<void> addUnit(String languageId, String title, int position) =>
      _api.insert('units', {'language_id': languageId, 'title': title, 'position': position});

  static Future<void> renameUnit(int id, String title) => _api.update('units', {'id': 'eq.$id'}, {'title': title});

  /// Menghapus tugas ikut menghapus pembahasan, soal, dan progres di dalamnya (on delete cascade).
  static Future<void> deleteUnit(int id) => _api.delete('units', {'id': 'eq.$id'});

  static Future<void> deleteLesson(int id) => _api.delete('lessons', {'id': 'eq.$id'});

  /// Simpan pembahasan + seluruh soalnya. Soal lama diganti dengan daftar baru.
  static Future<int> saveLesson({int? id, required Map<String, dynamic> lesson, required List<Map<String, dynamic>> questions}) async {
    final int lessonId;
    if (id == null) {
      lessonId = (await _api.insert('lessons', lesson)).first['id'] as int;
    } else {
      await _api.update('lessons', {'id': 'eq.$id'}, lesson);
      lessonId = id;
      await _api.delete('questions', {'lesson_id': 'eq.$id'});
    }
    if (questions.isNotEmpty) {
      await _api.insert('questions', [
        for (var i = 0; i < questions.length; i++) {...questions[i], 'lesson_id': lessonId, 'position': i},
      ]);
    }
    return lessonId;
  }

  static Future<List<Map<String, dynamic>>> allProgress() =>
      _api.select('lesson_progress', {'select': 'user_id,passed,failed_before,xp_earned,lessons(unit_id)'});

  /// Riwayat lulus milik sendiri (untuk target harian & titik streak 7 hari).
  static Future<List<Map<String, dynamic>>> myCompletions() => _api.select('lesson_progress', {
        'user_id': 'eq.${_api.userId}',
        'passed': 'eq.true',
        'select': 'lesson_id,xp_earned,completed_at',
        'order': 'completed_at.desc',
      });

  // ---------- Informasi ----------
  static Future<List<Post>> posts() async =>
      (await _api.select('posts', {'select': '*', 'order': 'pinned.desc,created_at.desc'})).map(Post.fromJson).toList();

  static Future<void> addPost(String category, String title, String body, bool pinned) =>
      _api.insert('posts', {...Post(category: category, title: title, body: body, pinned: pinned).toJson(), 'created_by': _api.userId});

  static Future<void> deletePost(int id) => _api.delete('posts', {'id': 'eq.$id'});

  // ---------- Masukan ----------
  static Future<void> sendFeedback(String type, String text, Map<String, dynamic> ctx) =>
      _api.insert('feedback', {...FeedbackItem(type: type, text: text, context: ctx).toJson(), 'user_id': _api.userId});

  static Future<List<FeedbackItem>> feedback() async =>
      (await _api.select('feedback', {'select': '*,profiles(name)', 'order': 'created_at.desc'})).map(FeedbackItem.fromJson).toList();

  static Future<void> setFeedbackStatus(int id, String status) => _api.update('feedback', {'id': 'eq.$id'}, {'status': status});

  // ---------- Berita TI ----------
  /// GET /functions/v1/tech-news — berita teknologi terbaru (publik).
  static Future<List<NewsItem>> techNews() async {
    final r = await http.get(Uri.parse('${AppConfig.supabaseUrl}/functions/v1/tech-news')).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) throw 'Berita gagal dimuat (${r.statusCode})';
    final items = (jsonDecode(utf8.decode(r.bodyBytes))['items'] as List).cast<Map<String, dynamic>>();
    return items.map(NewsItem.fromJson).where((n) => n.title.isNotEmpty).toList();
  }
}
