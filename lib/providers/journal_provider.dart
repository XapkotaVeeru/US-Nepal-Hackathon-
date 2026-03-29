import 'package:flutter/foundation.dart';

import '../models/journal_entry_model.dart';
import '../repositories/journal_repository.dart';

class JournalProvider with ChangeNotifier {
  JournalProvider(this._repository);

  final JournalRepository _repository;
  final List<JournalEntry> _entries = [];

  String? _userId;
  String? _displayName;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isSyncing = false;
  String? _syncError;
  int _bindVersion = 0;

  List<JournalEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;
  int get totalEntries => _entries.length;

  Future<void> bindUser({
    required String? userId,
    required String? displayName,
  }) async {
    final isSameUser =
        _userId == userId && _displayName == displayName && _isInitialized;
    if (isSameUser) return;

    final version = ++_bindVersion;
    _userId = userId;
    _displayName = displayName;
    _entries.clear();
    _syncError = null;
    _isLoading = userId != null;
    _isInitialized = userId == null;
    notifyListeners();

    if (userId == null) {
      return;
    }

    final cached = await _repository.loadCachedEntries(userId);
    if (version != _bindVersion) return;

    _setEntries(cached);
    _isLoading = false;
    _isInitialized = true;
    notifyListeners();

    sync();
  }

  Future<void> loadEntries() async {
    await bindUser(userId: _userId, displayName: _displayName);
  }

  Future<void> sync() async {
    final userId = _userId;
    final displayName = _displayName;
    if (userId == null || displayName == null || _isSyncing) return;

    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      final remoteEntries = await _repository.syncEntries(
        userId: userId,
        displayName: displayName,
      );
      if (userId == _userId) {
        _setEntries(remoteEntries);
      }
    } catch (_) {
      if (userId == _userId) {
        _syncError = 'Entries are available locally. Backend sync is offline.';
      }
    } finally {
      if (userId == _userId) {
        _isSyncing = false;
        notifyListeners();
      }
    }
  }

  Future<void> addEntry({
    required String content,
    String? prompt,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    final localEntry = await _repository.saveLocalEntry(
      userId: userId,
      content: trimmed,
      prompt: prompt,
    );
    _entries.insert(0, localEntry);
    _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();

    final displayName = _displayName;
    if (displayName == null) return;

    try {
      final remoteEntry = await _repository.createRemoteEntry(
        userId: userId,
        displayName: displayName,
        content: trimmed,
        prompt: prompt,
      );
      await _repository.replaceEntry(
        userId: userId,
        localEntryId: localEntry.id,
        remoteEntry: remoteEntry,
      );
      _replaceEntry(localEntry.id, remoteEntry);
      _syncError = null;
      notifyListeners();
    } catch (_) {
      _syncError = 'Journal saved locally. Sync will retry later.';
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String id) async {
    final userId = _userId;
    if (userId == null) return;

    _entries.removeWhere((entry) => entry.id == id);
    await _repository.deleteLocalEntry(userId: userId, entryId: id);
    notifyListeners();

    try {
      await _repository.deleteRemoteEntry(id);
    } catch (_) {
      _syncError = 'Entry removed locally. Backend cleanup will retry later.';
      notifyListeners();
    }
  }

  void _setEntries(List<JournalEntry> entries) {
    _entries
      ..clear()
      ..addAll(entries);
    _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _replaceEntry(String localId, JournalEntry remoteEntry) {
    final index = _entries.indexWhere((entry) => entry.id == localId);
    if (index == -1) {
      _entries.insert(0, remoteEntry);
    } else {
      _entries[index] = remoteEntry;
    }
    _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
