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

      _matchResults = response;

      // Create post object for history
      _currentPost = Post(
        id: response.submissionId,
        content: content,
        createdAt: DateTime.now(),
        riskLevel: _parseRiskLevel(response.riskLevel),
        similarUsers: response.similarUsers,
        supportGroups: response.supportGroups,
      );

      _postHistory.insert(0, _currentPost!);
    } catch (e) {
      _error = e.toString();
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
      default:
        return RiskLevel.low;
    }
  }
}
