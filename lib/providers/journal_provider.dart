import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/journal_entry_model.dart';

class JournalProvider with ChangeNotifier {
  static const _storageKey = 'journal_entries_v1';

  final List<JournalEntry> _entries = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  List<JournalEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  int get totalEntries => _entries.length;

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
      debugPrint('Error loading journal entries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEntry({
    required String content,
    String? prompt,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    final entry = JournalEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _buildTitle(trimmed),
      content: trimmed,
      prompt: prompt,
      createdAt: DateTime.now(),
    );

    _entries.insert(0, entry);
    _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _persistEntries();
    notifyListeners();
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

  List<JournalEntry> _decodeEntries(String? raw) {
    if (raw == null || raw.isEmpty) return const <JournalEntry>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <JournalEntry>[];
      return decoded
          .map((item) => JournalEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error decoding journal entries: $e');
      return const <JournalEntry>[];
    }
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
}
