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

    try {
      final response = await _apiService.submitPost(
        anonymousId: anonymousId,
        content: content,
      );
      debugPrint(
          'API response: submissionId=${response.submissionId}, riskLevel=${response.riskLevel}');
      debugPrint('Similar users count: ${response.similarUsers?.length ?? 0}');
      debugPrint(
          'Support groups count: ${response.supportGroups?.length ?? 0}');

      if (response.similarUsers != null) {
        for (var user in response.similarUsers!) {
          debugPrint(
              'Similar user: ${user.anonymousName}, score: ${user.similarityScore}');
        }
      }

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

      debugPrint(
          'Post created with ${_currentPost!.similarUsers?.length ?? 0} similar users');
      debugPrint('Match results set: ${_matchResults != null}');
      debugPrint('Current post set: ${_currentPost != null}');
    } catch (e) {
      _error =
          'Failed to submit post. Please check your connection and try again.';
      debugPrint('Error submitting post: $e');
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
}
