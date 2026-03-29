class MoodEntry {
  final String id;
  final int moodLevel;
  final String note;
  final DateTime createdAt;

  const MoodEntry({
    required this.id,
    required this.moodLevel,
    required this.note,
    required this.createdAt,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    final moodLevelValue = json['moodLevel'] ?? json['mood_level'];
    final createdAtValue = json['createdAt'] ?? json['created_at'];

    return MoodEntry(
      id: json['id'] as String? ?? '',
      moodLevel: moodLevelValue is int
          ? moodLevelValue
          : int.tryParse(moodLevelValue?.toString() ?? '') ?? 3,
      note: json['note'] as String? ?? '',
      createdAt: createdAtValue != null
          ? DateTime.tryParse(createdAtValue.toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moodLevel': moodLevel,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MoodEntry copyWith({
    String? id,
    int? moodLevel,
    String? note,
    DateTime? createdAt,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      moodLevel: moodLevel ?? this.moodLevel,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
