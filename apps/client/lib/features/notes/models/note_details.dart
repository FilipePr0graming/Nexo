import 'dart:convert';

class NoteDetails {
  const NoteDetails({
    required this.content,
    this.category,
    this.priority = 'normal',
    this.reminderAt,
    this.isDone = false,
    this.isPinned = false,
    this.isImportant = false,
    this.previousContent,
  });

  final String content;
  final String? category;
  final String priority;
  final DateTime? reminderAt;
  final bool isDone;
  final bool isPinned;
  final bool isImportant;
  final String? previousContent;

  NoteDetails copyWith({
    String? content,
    String? category,
    String? priority,
    DateTime? reminderAt,
    bool? isDone,
    bool? isPinned,
    bool? isImportant,
    String? previousContent,
  }) {
    return NoteDetails(
      content: content ?? this.content,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      reminderAt: reminderAt ?? this.reminderAt,
      isDone: isDone ?? this.isDone,
      isPinned: isPinned ?? this.isPinned,
      isImportant: isImportant ?? this.isImportant,
      previousContent: previousContent ?? this.previousContent,
    );
  }

  String encode() {
    return 'NEXO_NOTE:${jsonEncode({
          'content': content,
          'category': category,
          'priority': priority,
          'reminder_at': reminderAt?.toUtc().toIso8601String(),
          'is_done': isDone,
          'is_pinned': isPinned,
          'is_important': isImportant,
          'previous_content': previousContent,
        })}';
  }

  factory NoteDetails.fromBody(String body) {
    if (!body.trim().startsWith('NEXO_NOTE:')) {
      return NoteDetails(content: body);
    }
    try {
      final json = jsonDecode(body.trim().substring('NEXO_NOTE:'.length))
          as Map<String, dynamic>;
      return NoteDetails(
        content: (json['content'] as String?) ?? '',
        category: json['category'] as String?,
        priority: (json['priority'] as String?) ?? 'normal',
        reminderAt: _parseDate(json['reminder_at']),
        isDone: (json['is_done'] as bool?) ?? false,
        isPinned: (json['is_pinned'] as bool?) ?? false,
        isImportant: (json['is_important'] as bool?) ?? false,
        previousContent: json['previous_content'] as String?,
      );
    } catch (_) {
      return NoteDetails(content: body);
    }
  }

  static DateTime? _parseDate(Object? value) {
    final raw = value as String?;
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }
}
