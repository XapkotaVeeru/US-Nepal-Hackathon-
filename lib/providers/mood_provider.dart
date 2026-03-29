import 'package:flutter/foundation.dart';

import '../repositories/mood_repository.dart';
import '../services/api_service.dart';
import '../models/mood_entry_model.dart';

class MoodProvider with ChangeNotifier {
  MoodProvider(this._repository);

  final MoodRepository _repository;
  final List<MoodEntry> _entries = [];

  String? _userId;
  String? _displayName;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isSyncing = false;
  String? _syncError;
  int _bindVersion = 0;

  List<MoodEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;

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
    } catch (e) {
      if (userId == _userId) {
        _syncError = 'Saved locally. Backend sync unavailable right now.';
      }
    } finally {
      if (userId == _userId) {
        _isSyncing = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addEntry({
    required int moodLevel,
    required String note,
    DateTime? createdAt,
  }) async {
    final userId = _userId;
    if (userId == null || !canCheckInToday) return false;

    final localEntry = await _repository.saveLocalEntry(
      userId: userId,
      moodLevel: moodLevel,
      note: note,
      createdAt: createdAt,
    );

    _entries.insert(0, localEntry);
    _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();

    final displayName = _displayName;
    if (displayName == null) return true;

    try {
      final remoteEntry = await _repository.createRemoteEntry(
        userId: userId,
        displayName: displayName,
        moodLevel: moodLevel,
        note: note,
      );
      await _repository.replaceEntry(
        userId: userId,
        localEntryId: localEntry.id,
        remoteEntry: remoteEntry,
      );
      _replaceEntry(localEntry.id, remoteEntry);
      _syncError = null;
      notifyListeners();
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        await sync();
      } else {
        _syncError = 'Mood saved locally. Sync will retry later.';
        notifyListeners();
      }
    }

    return true;
  }

  Future<void> deleteEntry(String id) async {
    final userId = _userId;
    if (userId == null) return;

    _entries.removeWhere((entry) => entry.id == id);
    await _repository.saveEntries(userId, _entries);
    notifyListeners();
  }

  void _setEntries(List<MoodEntry> entries) {
    _entries
      ..clear()
      ..addAll(entries);
    _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _replaceEntry(String localId, MoodEntry remoteEntry) {
    final index = _entries.indexWhere((entry) => entry.id == localId);
    if (index == -1) {
      _entries.insert(0, remoteEntry);
    } else {
      _entries[index] = remoteEntry;
    }
    _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
