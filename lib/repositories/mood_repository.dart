import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/mood_entry_model.dart';
import '../services/api_service.dart';

class MoodRepository {
  MoodRepository(this._apiService);

  static const _legacyStorageKey = 'mood_entries_v1';
  static const _storageKeyPrefix = 'mood_entries_v2_';

  final ApiService _apiService;

  Future<List<MoodEntry>> loadCachedEntries(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = _storageKey(userId);
    final cachedRaw = prefs.getString(userKey);
    if (cachedRaw != null && cachedRaw.isNotEmpty) {
      return _sortEntries(_decodeEntries(cachedRaw));
    }

    final legacyRaw = prefs.getString(_legacyStorageKey);
    final legacyEntries = _sortEntries(_decodeEntries(legacyRaw));
    if (legacyEntries.isNotEmpty) {
      await saveEntries(userId, legacyEntries);
      await prefs.remove(_legacyStorageKey);
    }
    return legacyEntries;
  }

  Future<List<MoodEntry>> syncEntries({
    required String userId,
    required String displayName,
  }) async {
    await _apiService.ensureAnonymousUserExists(
      userId: userId,
      displayName: displayName,
    );
    final remoteEntries = await _apiService.listMoodEntries(userId: userId);
    await saveEntries(userId, remoteEntries);
    return _sortEntries(remoteEntries);
  }

  Future<MoodEntry> saveLocalEntry({
    required String userId,
    required int moodLevel,
    required String note,
    DateTime? createdAt,
  }) async {
    final cached = await loadCachedEntries(userId);
    final entry = MoodEntry(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      moodLevel: moodLevel,
      note: note.trim(),
      createdAt: createdAt ?? DateTime.now(),
    );
    final updated = _sortEntries([...cached, entry]);
    await saveEntries(userId, updated);
    return entry;
  }

  Future<MoodEntry> createRemoteEntry({
    required String userId,
    required String displayName,
    required int moodLevel,
    required String note,
  }) async {
    await _apiService.ensureAnonymousUserExists(
      userId: userId,
      displayName: displayName,
    );
    return _apiService.createMoodEntry(
      userId: userId,
      moodLevel: moodLevel,
      note: note,
    );
  }

  Future<void> replaceEntry({
    required String userId,
    required String localEntryId,
    required MoodEntry remoteEntry,
  }) async {
    final cached = await loadCachedEntries(userId);
    final replaced = cached
        .where((entry) => entry.id != localEntryId)
        .toList(growable: true)
      ..add(remoteEntry);
    await saveEntries(userId, replaced);
  }

  Future<void> saveEntries(String userId, List<MoodEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(
      _sortEntries(entries).map((entry) => entry.toJson()).toList(),
    );
    await prefs.setString(_storageKey(userId), payload);
  }

  List<MoodEntry> _decodeEntries(String? raw) {
    if (raw == null || raw.isEmpty) return const <MoodEntry>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <MoodEntry>[];
      return decoded
          .map((item) => MoodEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const <MoodEntry>[];
    }
  }

  List<MoodEntry> _sortEntries(List<MoodEntry> entries) {
    final sorted = List<MoodEntry>.from(entries);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  String _storageKey(String userId) => '$_storageKeyPrefix$userId';
}
