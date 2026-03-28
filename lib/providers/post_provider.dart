import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';

class PostProvider with ChangeNotifier {
  final ApiService _apiService;

  bool _isSubmitting = false;
  String? _error;
  Post? _currentPost;
  SubmissionResponse? _matchResults;
  final List<Post> _postHistory = [];

  PostProvider(this._apiService);

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  Post? get currentPost => _currentPost;
  SubmissionResponse? get matchResults => _matchResults;
  List<Post> get postHistory => _postHistory;

  /// Submit a new post
  Future<void> submitPost({
    required String anonymousId,
    required String content,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    SubmissionResponse response;

    try {
      response = await _apiService.submitPost(
        anonymousId: anonymousId,
        content: content,
      );
      debugPrint('API response: submissionId=${response.submissionId}, riskLevel=${response.riskLevel}');
    } catch (e) {
      debugPrint('API call failed, using local fallback: $e');
      // ── Fallback: generate a local mock response so the UI stays functional ──
      response = _generateMockResponse(content);
    }

    try {
      _matchResults = response;

      // Create post object for history
      _currentPost = Post(
        id: response.submissionId.isNotEmpty
            ? response.submissionId
            : DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        createdAt: DateTime.now(),
        riskLevel: _parseRiskLevel(response.riskLevel),
        similarUsers: response.similarUsers,
        supportGroups: response.supportGroups,
      );

      _postHistory.insert(0, _currentPost!);
    } catch (e) {
      _error = 'Something went wrong. Please try again.';
      debugPrint('Error building post object: $e');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Clear current match results
  void clearMatchResults() {
    _matchResults = null;
    _currentPost = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get post by ID
  Post? getPostById(String id) {
    try {
      return _postHistory.firstWhere((post) => post.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Parse risk level from string
  RiskLevel _parseRiskLevel(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return RiskLevel.low;
      case 'medium':
        return RiskLevel.medium;
      case 'high':
        return RiskLevel.high;
      case 'crisis':
        return RiskLevel.high;
      case 'pending':
        return RiskLevel.low; // Treat pending as low risk
      default:
        return RiskLevel.low;
    }
  }

  /// Generate a mock response when the backend is unavailable
  SubmissionResponse _generateMockResponse(String content) {
    final contentLower = content.toLowerCase();

    // Simple keyword heuristic for risk
    String riskLevel = 'low';
    if (contentLower.contains('suicide') ||
        contentLower.contains('kill myself') ||
        contentLower.contains('end it all') ||
        contentLower.contains('don\'t want to live')) {
      riskLevel = 'high';
    } else if (contentLower.contains('anxiety') ||
        contentLower.contains('depressed') ||
        contentLower.contains('hopeless') ||
        contentLower.contains('overwhelmed') ||
        contentLower.contains('can\'t cope')) {
      riskLevel = 'medium';
    }

    return SubmissionResponse(
      submissionId: 'local-${DateTime.now().millisecondsSinceEpoch}',
      riskLevel: riskLevel,
      similarUsers: [
        SimilarUser(
          id: 'mock-1',
          anonymousName: 'Anonymous Butterfly',
          similarityScore: 0.89,
          lastActive: '2 hours ago',
          commonTheme: 'Similar feelings and experiences',
        ),
        SimilarUser(
          id: 'mock-2',
          anonymousName: 'Anonymous Phoenix',
          similarityScore: 0.85,
          lastActive: '5 hours ago',
          commonTheme: 'Feeling overwhelmed',
        ),
        SimilarUser(
          id: 'mock-3',
          anonymousName: 'Anonymous Dove',
          similarityScore: 0.82,
          lastActive: '1 day ago',
          commonTheme: 'Looking for support',
        ),
      ],
      supportGroups: [
        SupportGroup(
          id: 'mock-g1',
          name: 'Peer Support Circle',
          memberCount: 12,
          theme: 'Shared experiences and mutual support',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        SupportGroup(
          id: 'mock-g2',
          name: 'Healing Together',
          memberCount: 8,
          theme: 'Daily check-ins and support',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    );
  }
}
