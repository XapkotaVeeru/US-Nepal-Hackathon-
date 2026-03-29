import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/journal_entry_model.dart';
import '../services/api_service.dart';

class JournalRepository {
  JournalRepository(this._apiService);

  static const _legacyStorageKey = 'journal_entries_v1';
  static const _storageKeyPrefix = 'journal_entries_v2_';

  final ApiService _apiService;

  Future<List<JournalEntry>> loadCachedEntries(String userId) async {
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

  Future<List<JournalEntry>> syncEntries({
    required String userId,
    required String displayName,
  }) async {
    await _apiService.ensureAnonymousUserExists(
      userId: userId,
      displayName: displayName,
    );
    final remoteEntries = await _apiService.listJournalEntries(userId: userId);
    await saveEntries(userId, remoteEntries);
    return _sortEntries(remoteEntries);
  }

  Future<JournalEntry> saveLocalEntry({
    required String userId,
    required String content,
    String? prompt,
    DateTime? createdAt,
  }) async {
    final trimmed = content.trim();
    final cached = await loadCachedEntries(userId);
    final entry = JournalEntry(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      title: _buildTitle(trimmed),
      content: trimmed,
      prompt: prompt,
      createdAt: createdAt ?? DateTime.now(),
    );
    final updated = _sortEntries([...cached, entry]);
    await saveEntries(userId, updated);
    return entry;
  }

  Future<JournalEntry> createRemoteEntry({
    required String userId,
    required String displayName,
    required String content,
    String? prompt,
  }) async {
    await _apiService.ensureAnonymousUserExists(
      userId: userId,
      displayName: displayName,
    );
    return _apiService.createJournalEntry(
      userId: userId,
      title: _buildTitle(content.trim()),
      content: content.trim(),
      prompt: prompt,
    );
  }

  Future<void> deleteLocalEntry({
    required String userId,
    required String entryId,
  }) async {
    final cached = await loadCachedEntries(userId);
    final updated = cached.where((entry) => entry.id != entryId).toList();
    await saveEntries(userId, updated);
  }

  Future<void> deleteRemoteEntry(String journalId) {
    return _apiService.deleteJournalEntry(journalId: journalId);
  }

  Future<void> replaceEntry({
    required String userId,
    required String localEntryId,
    required JournalEntry remoteEntry,
  }) async {
    final cached = await loadCachedEntries(userId);
    final replaced = cached
        .where((entry) => entry.id != localEntryId)
        .toList(growable: true)
      ..add(remoteEntry);
    await saveEntries(userId, replaced);
  }

  Future<void> saveEntries(String userId, List<JournalEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(
      _sortEntries(entries).map((entry) => entry.toJson()).toList(),
    );
    await prefs.setString(_storageKey(userId), payload);
  }

  List<JournalEntry> _decodeEntries(String? raw) {
    if (raw == null || raw.isEmpty) return const <JournalEntry>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <JournalEntry>[];
      return decoded
          .map((item) => JournalEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const <JournalEntry>[];
    }
  }

  List<JournalEntry> _sortEntries(List<JournalEntry> entries) {
    final sorted = List<JournalEntry>.from(entries);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  String _buildTitle(String content) {
    final lines = content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final firstLine = lines.isNotEmpty ? lines.first : content;
    return firstLine.length > 40 ? '${firstLine.substring(0, 40)}...' : firstLine;
  }

  String _storageKey(String userId) => '$_storageKeyPrefix$userId';
}
