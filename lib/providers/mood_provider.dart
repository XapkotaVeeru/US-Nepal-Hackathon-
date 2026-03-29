import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mood_entry_model.dart';

class MoodProvider with ChangeNotifier {
  static const _storageKey = 'mood_entries_v1';

  final List<MoodEntry> _entries = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  List<MoodEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  MoodEntry? get todayEntry {
    final today = _startOfDay(DateTime.now());
    for (final entry in _entries) {
      if (_startOfDay(entry.createdAt) == today) return entry;
    }
    return null;
  }

  bool get canCheckInToday => todayEntry == null;

  List<MoodEntry> get last7DaysEntries {
    final threshold = _startOfDay(DateTime.now().subtract(const Duration(days: 6)));
    final result = _entries.where((entry) {
      return !_startOfDay(entry.createdAt).isBefore(threshold);
    }).toList();
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  Map<int, int> get moodDistribution {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final entry in _entries) {
      distribution[entry.moodLevel] = (distribution[entry.moodLevel] ?? 0) + 1;
    }
    return distribution;
  }

  int get currentStreak {
    if (_entries.isEmpty) return 0;

    final uniqueDays = _entries
        .map((entry) => _startOfDay(entry.createdAt))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final today = _startOfDay(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    if (uniqueDays.first != today && uniqueDays.first != yesterday) return 0;

    var streak = 1;
    for (var i = 1; i < uniqueDays.length; i++) {
      final previous = uniqueDays[i - 1];
      final current = uniqueDays[i];
      if (previous.difference(current).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> loadEntries() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      _entries
        ..clear()
        ..addAll(_decodeEntries(raw));
      _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading mood entries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addEntry({
    required int moodLevel,
    required String note,
    DateTime? createdAt,
  }) async {
    if (!canCheckInToday) return false;

    final entry = MoodEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      moodLevel: moodLevel,
      note: note.trim(),
      createdAt: createdAt ?? DateTime.now(),
    );

    _entries.insert(0, entry);
    _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _persistEntries();
    notifyListeners();
    return true;
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((entry) => entry.id == id);
    await _persistEntries();
    notifyListeners();
  }

  Future<void> _persistEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(
      _entries.map((entry) => entry.toJson()).toList(),
    );
    await prefs.setString(_storageKey, payload);
  }

  List<MoodEntry> _decodeEntries(String? raw) {
    if (raw == null || raw.isEmpty) return const <MoodEntry>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <MoodEntry>[];
      return decoded
          .map((item) => MoodEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error decoding mood entries: $e');
      return const <MoodEntry>[];
    }
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
