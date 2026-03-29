import 'package:flutter/foundation.dart';
import '../models/micro_community_model.dart';
import '../services/api_service.dart';

class CommunityProvider with ChangeNotifier {
  final ApiService? _apiService;

  List<MicroCommunity> _allCommunities = [];
  final List<MicroCommunity> _joinedCommunities = [];
  String? _autoJoinBanner;
  MicroCommunity? _lastAutoJoined;
  bool _isLoading = false;
  String? _anonymousId;

  CommunityProvider({ApiService? apiService}) : _apiService = apiService {
    _loadCommunities();
  }

  List<MicroCommunity> get allCommunities => _allCommunities;
  List<MicroCommunity> get joinedCommunities => _joinedCommunities;
  String? get autoJoinBanner => _autoJoinBanner;
  MicroCommunity? get lastAutoJoined => _lastAutoJoined;
  bool get isLoading => _isLoading;

  List<MicroCommunity> get trending => MockCommunities.getTrending();
  List<MicroCommunity> get suggested => MockCommunities.getSuggested();
  List<MicroCommunity> get recentlyActive =>
      MockCommunities.getRecentlyActive();

  /// Set the anonymous user ID for API calls
  void setAnonymousId(String id) {
    _anonymousId = id;
  }

  void _loadCommunities() {
    // Start with mock data immediately
    _allCommunities = MockCommunities.getAllCommunities();
    notifyListeners();

    // Try to fetch from API in background
    _fetchFromApi();
  }

  /// Fetch communities from backend
  Future<void> _fetchFromApi() async {
    final api = _apiService;
    if (api == null) return;

    try {
      final remote = await api.discoverCommunities();
      if (remote.isNotEmpty) {
        // Merge remote data with local mock data
        for (final data in remote) {
          final id = data['id'] as String?;
          if (id != null) {
            final index = _allCommunities.indexWhere((c) => c.id == id);
            if (index == -1) {
              // New community from server — add it
              _allCommunities.add(MicroCommunity(
                id: id,
                name: data['name'] as String? ?? 'Unknown',
                topic: data['topic'] as String? ?? '',
                description: data['description'] as String? ?? '',
                emoji: data['emoji'] as String? ?? '💬',
                memberCount: data['memberCount'] as int? ?? 0,
                lastMessagePreview: data['lastMessage'] as String?,
                tags: (data['tags'] as List?)
                        ?.map((t) => t.toString())
                        .toList() ??
                    [],
              ));
            } else {
              // Update existing with server data
              _allCommunities[index] = _allCommunities[index].copyWith(
                memberCount: data['memberCount'] as int? ??
                    _allCommunities[index].memberCount,
                lastMessagePreview: data['lastMessage'] as String? ??
                    _allCommunities[index].lastMessagePreview,
              );
            }
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching communities from API: $e');
      // Mock data is already loaded, so this is fine
    }
  }

  /// Refresh communities from server
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await _fetchFromApi();
    _isLoading = false;
    notifyListeners();
  }

  /// Join a community
  void joinCommunity(String communityId) {
    final index = _allCommunities.indexWhere((c) => c.id == communityId);
    if (index != -1) {
      final community = _allCommunities[index];
      if (!_joinedCommunities.any((c) => c.id == communityId)) {
        final joined = community.copyWith(
          isJoined: true,
          memberCount: community.memberCount + 1,
        );
        _allCommunities[index] = joined;
        _joinedCommunities.add(joined);
        notifyListeners();

        // Fire-and-forget API call
        final api = _apiService;
        final userId = _anonymousId;
        if (api != null && userId != null) {
          api.joinCommunity(
            communityId: communityId,
            anonymousId: userId,
          );
        }
      }
    }
  }

  /// Leave a community
  void leaveCommunity(String communityId) {
    final index = _allCommunities.indexWhere((c) => c.id == communityId);
    if (index != -1) {
      final community = _allCommunities[index];
      _allCommunities[index] = community.copyWith(
        isJoined: false,
        memberCount: community.memberCount - 1,
      );
      _joinedCommunities.removeWhere((c) => c.id == communityId);
      notifyListeners();
    }
  }

  /// Check if user has joined a community
  bool isJoined(String communityId) {
    return _joinedCommunities.any((c) => c.id == communityId);
  }

  /// Auto-join based on post content (extract topic mock)
  void autoJoinFromPost(String postContent) {
    final topic = _extractTopic(postContent);
    final community = MockCommunities.findCommunityForTopic(topic);

    if (community != null && !isJoined(community.id)) {
      joinCommunity(community.id);
      _lastAutoJoined = community;
      _autoJoinBanner =
          'We added you to ${community.name} — people here feel the same way. ${community.emoji}';
      notifyListeners();

      // Auto-dismiss banner after 8 seconds
      Future.delayed(const Duration(seconds: 8), () {
        dismissAutoJoinBanner();
      });
    }
  }

  /// Dismiss the auto-join banner
  void dismissAutoJoinBanner() {
    _autoJoinBanner = null;
    _lastAutoJoined = null;
    notifyListeners();
  }

  /// Mock topic extraction from post content
  String _extractTopic(String content) {
    final lower = content.toLowerCase();
    if (lower.contains('anxious') ||
        lower.contains('anxiety') ||
        lower.contains('panic')) {
      return 'anxiety';
    } else if (lower.contains('study') ||
        lower.contains('exam') ||
        lower.contains('academic') ||
        lower.contains('school') ||
        lower.contains('college')) {
      return 'academic';
    } else if (lower.contains('sleep') ||
        lower.contains('night') ||
        lower.contains('insomnia')) {
      return 'insomnia';
    } else if (lower.contains('family') ||
        lower.contains('parent') ||
        lower.contains('home')) {
      return 'family';
    } else if (lower.contains('social') || lower.contains('people')) {
      return 'social anxiety';
    } else if (lower.contains('sad') ||
        lower.contains('depressed') ||
        lower.contains('depression')) {
      return 'depression';
    } else if (lower.contains('grief') ||
        lower.contains('loss') ||
        lower.contains('died')) {
      return 'grief';
    } else if (lower.contains('meditat') || lower.contains('mindful')) {
      return 'mindfulness';
    }
    return 'support';
  }

  /// Get community by id
  MicroCommunity? getCommunityById(String id) {
    try {
      return _allCommunities.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Search communities
  List<MicroCommunity> searchCommunities(String query) {
    if (query.isEmpty) return _allCommunities;
    final lower = query.toLowerCase();
    return _allCommunities.where((c) {
      return c.name.toLowerCase().contains(lower) ||
          c.topic.toLowerCase().contains(lower) ||
          c.tags.any((t) => t.contains(lower));
    }).toList();
  }
}
