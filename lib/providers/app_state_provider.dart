import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/anonymous_id_service.dart';
import '../services/api_service.dart';

class AppStateProvider with ChangeNotifier {
  final AnonymousIdService _anonymousIdService;
  final ApiService _apiService;

  AnonymousUser? _currentUser;
  bool _isInitialized = false;
  bool _isLoading = false;

  AppStateProvider(this._anonymousIdService, this._apiService);

  AnonymousUser? get currentUser => _currentUser;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get anonymousId => _currentUser?.anonymousId;

  /// Initialize app state
  Future<void> initialize() async {
    if (_isInitialized || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _anonymousIdService.getOrCreateAnonymousId();
      _currentUser = await _anonymousIdService.getCurrentUser();
      _isInitialized = true;

      if (_currentUser != null) {
        try {
          await _syncCurrentUserWithBackend();
        } catch (e) {
          debugPrint('Error syncing user profile: $e');
        }
      }
    } catch (e) {
      debugPrint('Error initializing app state: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Export profile
  Future<Map<String, String>> exportProfile() async {
    return await _anonymousIdService.exportProfile();
  }

  /// Import profile
  Future<void> importProfile(Map<String, String> profileData) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _anonymousIdService.importProfile(profileData);
      _currentUser = await _anonymousIdService.getCurrentUser();
      _isInitialized = true;
      if (_currentUser != null) {
        await _syncCurrentUserWithBackend();
      }
    } catch (e) {
      debugPrint('Error importing profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear profile and start fresh
  Future<void> clearProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _anonymousIdService.clearProfile();
      _currentUser = null;
      _isInitialized = false;
      await initialize();
    } catch (e) {
      debugPrint('Error clearing profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user stats
  void updateUserStats({int? totalPosts, int? totalChats}) {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(
      totalPosts: totalPosts ?? _currentUser!.totalPosts,
      totalChats: totalChats ?? _currentUser!.totalChats,
    );
    notifyListeners();
  }

  Future<void> updateDisplayName(String displayName) async {
    final cleaned = displayName.trim();
    if (cleaned.isEmpty || _currentUser == null) return;

    await _saveUserProfile(
      _currentUser!.copyWith(displayName: cleaned),
    );
  }

  Future<void> updateSettings({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? chatRequestsEnabled,
    bool? groupInvitesEnabled,
  }) async {
    final user = _currentUser;
    if (user == null) return;

    await _saveUserProfile(
      user.copyWith(
        notificationsEnabled:
            notificationsEnabled ?? user.notificationsEnabled,
        soundEnabled: soundEnabled ?? user.soundEnabled,
        chatRequestsEnabled:
            chatRequestsEnabled ?? user.chatRequestsEnabled,
        groupInvitesEnabled:
            groupInvitesEnabled ?? user.groupInvitesEnabled,
      ),
    );
  }

  Future<void> resetProfileData() async {
    final previousUser = _currentUser;
    if (previousUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final remoteUser = await _apiService.resetUserProfile(
        userId: previousUser.anonymousId,
      );
      _currentUser = _mergeRemoteUser(
        remoteUser,
        previousUser.copyWith(totalPosts: 0, totalChats: 0),
      );
      await _anonymousIdService.saveCurrentUser(_currentUser!);
    } catch (e) {
      debugPrint('Error resetting profile data: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveUserProfile(AnonymousUser nextUser) async {
    final previousUser = _currentUser;
    _currentUser = nextUser;
    _isLoading = true;
    notifyListeners();

    try {
      await _syncCurrentUserWithBackend();
    } catch (e) {
      if (_shouldUseLocalProfileFallback(e)) {
        _currentUser = nextUser;
        await _anonymousIdService.saveCurrentUser(nextUser);
        return;
      }
      _currentUser = previousUser;
      debugPrint('Error saving user profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncCurrentUserWithBackend() async {
    final user = _currentUser;
    if (user == null) return;

    try {
      final remoteUser = await _apiService.upsertUserProfile(
        userId: user.anonymousId,
        displayName: user.displayName,
        notificationsEnabled: user.notificationsEnabled,
        soundEnabled: user.soundEnabled,
        chatRequestsEnabled: user.chatRequestsEnabled,
        groupInvitesEnabled: user.groupInvitesEnabled,
      );
      _currentUser = _mergeRemoteUser(remoteUser, user);
      await _anonymousIdService.saveCurrentUser(_currentUser!);
    } catch (e) {
      if (_shouldUseLocalProfileFallback(e)) {
        await _anonymousIdService.saveCurrentUser(user);
        _currentUser = user;
        return;
      }
      rethrow;
    }
  }

  AnonymousUser _mergeRemoteUser(
    AnonymousUser remoteUser,
    AnonymousUser localUser,
  ) {
    return remoteUser.copyWith(
      totalPosts: localUser.totalPosts,
      totalChats: localUser.totalChats,
    );
  }

  bool _shouldUseLocalProfileFallback(Object error) {
    if (error is ApiException && error.statusCode == 403) {
      debugPrint(
        'Profile sync is unavailable on the current backend. Using local profile state.',
      );
      return true;
    }
    return false;
  }
}
