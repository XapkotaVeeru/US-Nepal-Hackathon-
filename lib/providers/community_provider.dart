import 'package:flutter/foundation.dart';
import '../models/micro_community_model.dart';

class CommunityProvider with ChangeNotifier {
  List<MicroCommunity> _allCommunities = [];
  final List<MicroCommunity> _joinedCommunities = [];
  String? _autoJoinBanner;
  MicroCommunity? _lastAutoJoined;
  bool _isLoading = false;

  CommunityProvider() {
    _loadCommunities();
  }

  List<MicroCommunity> get allCommunities => _allCommunities;
  List<MicroCommunity> get joinedCommunities => _joinedCommunities;
  String? get autoJoinBanner => _autoJoinBanner;
  MicroCommunity? get lastAutoJoined => _lastAutoJoined;
  bool get isLoading => _isLoading;

  List<MicroCommunity> get trending => MockCommunities.getTrending();
  List<MicroCommunity> get suggested => MockCommunities.getSuggested();
  List<MicroCommunity> get recentlyActive => MockCommunities.getRecentlyActive();

  void _loadCommunities() {
    _allCommunities = MockCommunities.getAllCommunities();
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
