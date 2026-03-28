import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/anonymous_id_service.dart';

class AppStateProvider with ChangeNotifier {
  final AnonymousIdService _anonymousIdService;

  AnonymousUser? _currentUser;
  bool _isInitialized = false;
  bool _isLoading = false;

  AppStateProvider(this._anonymousIdService);

  AnonymousUser? get currentUser => _currentUser;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get anonymousId => _currentUser?.anonymousId;

  /// Initialize app state
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _anonymousIdService.getOrCreateAnonymousId();
      _currentUser = await _anonymousIdService.getCurrentUser();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing app state: $e');
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
    } catch (e) {
      print('Error importing profile: $e');
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
      print('Error clearing profile: $e');
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
}
