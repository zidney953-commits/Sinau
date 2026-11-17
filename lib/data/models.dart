class Profile {
  final String id, name, email, role;
  final int? angkatan;
  final String? avatarUrl;
  final bool active;
  final int streak;
  final String? lastActive;
  final DateTime? createdAt;
  Profile.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        name = j['name'],
        email = j['email'],
        role = j['role'],
        angkatan = j['angkatan'],
        avatarUrl = j['avatar_url'],
        active = j['active'] ?? true,
        streak = j['streak'] ?? 0,
        lastActive = j['last_active'],
        createdAt = j['created_at'] == null ? null : DateTime.parse(j['created_at']).toLocal();
  bool get isAdmin => role == 'admin';

  /// Model → JSON (kolom yang boleh diubah pemilik akun lewat PATCH /rest/v1/profiles).
  Map<String, dynamic> toJson() => {'name': name, 'angkatan': angkatan, 'avatar_url': avatarUrl, 'streak': streak, 'last_active': lastActive};
}

class Post {
  final int id;
  final String category, title, body;
  final bool pinned;
  final DateTime createdAt;
  Post({this.id = 0, required this.category, required this.title, required this.body, this.pinned = false, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();
  Post.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        category = j['category'],
        title = j['title'],
        body = j['body'],
        pinned = j['pinned'] ?? false,
        createdAt = DateTime.parse(j['created_at']).toLocal();

  /// Model → JSON untuk POST /rest/v1/posts (id & tanggal dibuat oleh database).
  Map<String, dynamic> toJson() => {'category': category, 'title': title, 'body': body, 'pinned': pinned};
}

class FeedbackItem {
  final int id;
  final String type, text, status;
  final Map<String, dynamic> context;
  final DateTime createdAt;
  final String? userName;
  FeedbackItem({this.id = 0, required this.type, required this.text, this.status = 'baru', this.context = const {}, this.userName, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();
  FeedbackItem.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        type = j['type'],
        text = j['text'],
        status = j['status'],
        context = (j['context'] ?? {}) as Map<String, dynamic>,
        createdAt = DateTime.parse(j['created_at']).toLocal(),
        userName = j['profiles']?['name'];

  /// Model → JSON untuk POST /rest/v1/feedback.
  Map<String, dynamic> toJson() => {'type': type, 'text': text, 'context': context, 'status': status};
}

class Language {
  final String id, name, mono, description;
  final int color;
  Language.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        name = j['name'],
        mono = j['mono'],
        description = j['description'] ?? '',
        color = int.parse('FF${(j['color'] as String).substring(1)}', radix: 16);
}

class Unit {
  final int id, position;
  final String languageId, title;
  final List<Lesson> lessons;
  Unit.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        position = j['position'],
        languageId = j['language_id'],
        title = j['title'],
        lessons = ((j['lessons'] ?? []) as List).map((e) => Lesson.fromJson(e)).toList()..sort((a, b) => a.position.compareTo(b.position));
}

class Lesson {
  final int id, unitId, durationMin, xp, position;
  final String title, type;
  bool published;
  final Map<String, dynamic> material;
  Lesson.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        unitId = j['unit_id'],
        title = j['title'],
        type = j['type'],
        durationMin = j['duration_min'],
        xp = j['xp'],
        published = j['published'],
        position = j['position'],
        material = (j['material'] ?? {}) as Map<String, dynamic>;

  Map<String, dynamic> toJson() => {
        'unit_id': unitId, 'title': title, 'type': type, 'duration_min': durationMin,
        'xp': xp, 'published': published, 'position': position, 'material': material,
      };
}

class Question {
  final int position;
  final String type, prompt;
  final String? explanation;
  final Map<String, dynamic> options;
  final dynamic answer;
  Question.fromJson(Map<String, dynamic> j)
      : position = j['position'],
        type = j['type'],
        prompt = j['prompt'],
        explanation = j['explanation'],
        options = (j['options'] ?? {}) as Map<String, dynamic>,
        answer = j['answer'];
  List<String> get opts => ((options['opts'] ?? []) as List).cast<String>();
  List<String> get blocks => ((options['blocks'] ?? []) as List).cast<String>();
  List<int> get pool => ((options['pool'] ?? []) as List).cast<int>();
  String? get code => options['code'];
  Map<String, dynamic>? get table => options['table'];

  Map<String, dynamic> toJson() => {'position': position, 'type': type, 'prompt': prompt, 'options': options, 'answer': answer, 'explanation': explanation};
}

class LessonProgress {
  final int lessonId;
  final bool passed, failedBefore;
  final int attempts, correct, total, xpEarned;
  LessonProgress.fromJson(Map<String, dynamic> j)
      : lessonId = j['lesson_id'],
        passed = j['passed'],
        failedBefore = j['failed_before'] ?? false,
        attempts = j['attempts'] ?? 0,
        correct = j['correct'] ?? 0,
        total = j['total'] ?? 0,
        xpEarned = j['xp_earned'] ?? 0;

  Map<String, dynamic> toJson() => {
        'lesson_id': lessonId, 'passed': passed, 'failed_before': failedBefore,
        'attempts': attempts, 'correct': correct, 'total': total,
      };
}
