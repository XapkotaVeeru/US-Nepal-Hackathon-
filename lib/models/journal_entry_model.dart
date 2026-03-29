class JournalEntry {
  final String id;
  final String title;
  final String content;
  final String? prompt;
  final DateTime createdAt;

  const JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.prompt,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      prompt: json['prompt'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'prompt': prompt,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  JournalEntry copyWith({
    String? id,
    String? title,
    String? content,
    String? prompt,
    DateTime? createdAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      prompt: prompt ?? this.prompt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
