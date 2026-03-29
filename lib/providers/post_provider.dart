import 'package:flutter/foundation.dart';
import '../models/check_in_model.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/emotional_analysis_service.dart';
import '../services/support_matching_service.dart';

class PostProvider with ChangeNotifier {
  final ApiService _apiService;
  final EmotionalAnalysisService _emotionalAnalysisService;
  final SupportMatchingService _supportMatchingService;

  bool _isSubmitting = false;
  String? _error;
  Post? _currentPost;
  CheckInResult? _currentCheckInResult;
  final List<Post> _postHistory = [];

  PostProvider({
    required ApiService apiService,
    required EmotionalAnalysisService emotionalAnalysisService,
    required SupportMatchingService supportMatchingService,
  })  : _apiService = apiService,
        _emotionalAnalysisService = emotionalAnalysisService,
        _supportMatchingService = supportMatchingService;

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  Post? get currentPost => _currentPost;
  CheckInResult? get currentCheckInResult => _currentCheckInResult;
  List<Post> get postHistory => _postHistory;

  Future<void> submitPost({
    required String anonymousId,
    required String content,
    CheckInInputMode inputMode = CheckInInputMode.text,
    String captureSource = 'typed',
    String? transcript,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    final submission = CheckInSubmission(
      anonymousId: anonymousId,
      content: content.trim(),
      inputMode: inputMode,
      createdAt: DateTime.now(),
      captureSource: captureSource,
      transcript: transcript,
    );

    SubmissionResponse? backendResponse;

    try {
      backendResponse = await _apiService.submitPost(
        anonymousId: anonymousId,
        content: submission.content,
      );
    } catch (e) {
      debugPrint('Submission endpoint unavailable, continuing locally: $e');
    }

    try {
      final analysis = await _emotionalAnalysisService.analyze(
        EmotionalAnalysisRequest(submission: submission),
      );
      final localMatches = await _supportMatchingService.buildMatches(
        submission: submission,
        analysis: analysis,
      );
      final mergedMatches = _mergeBackendMatches(
        localMatches: localMatches,
        backendResponse: backendResponse,
      );

      _currentCheckInResult = CheckInResult(
        submissionId: backendResponse?.submissionId.isNotEmpty == true
            ? backendResponse!.submissionId
            : 'local-${DateTime.now().millisecondsSinceEpoch}',
        submission: submission,
        analysis: analysis,
        matching: mergedMatches,
        status: backendResponse?.status ?? 'ready',
        backendMessage: backendResponse?.message,
      );

      _currentPost = Post(
        id: _currentCheckInResult!.submissionId,
        content: submission.content,
        createdAt: submission.createdAt,
        riskLevel: _parseRiskLevel(
          analysis.riskLevel.isNotEmpty
              ? analysis.riskLevel
              : (backendResponse?.riskLevel ?? 'low'),
        ),
        similarUsers: mergedMatches.members
            .map(
              (member) => SimilarUser(
                id: member.id,
                anonymousName: member.anonymousName,
                similarityScore: member.similarityScore,
                lastActive: member.lastActive,
                commonTheme: member.sharedThemes,
              ),
            )
            .toList(),
        supportGroups: mergedMatches.communities
            .map(
              (community) => SupportGroup(
                id: community.id,
                name: community.name,
                memberCount: community.memberCount,
                theme: community.reason,
                createdAt: submission.createdAt,
              ),
            )
            .toList(),
      );

      _postHistory.insert(0, _currentPost!);
    } catch (e) {
      _error = 'Something went wrong while understanding your check-in.';
      debugPrint('Error building check-in result: $e');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  SupportMatchResult _mergeBackendMatches({
    required SupportMatchResult localMatches,
    required SubmissionResponse? backendResponse,
  }) {
    if (backendResponse == null) return localMatches;

    final backendMembers = backendResponse.similarUsers
            ?.map(
              (user) => SupportMemberRecommendation(
                id: user.id,
                anonymousName: user.anonymousName,
                similarityScore: user.similarityScore,
                lastActive: user.lastActive ?? 'Recently active',
                reason: user.commonTheme ?? 'Similar lived experience',
                sharedThemes: user.commonTheme ?? 'Shared feelings',
              ),
            )
            .toList() ??
        const <SupportMemberRecommendation>[];

    final backendCommunities = backendResponse.supportGroups
            ?.map(
              (group) => SupportCommunityRecommendation(
                id: group.id,
                name: group.name,
                emoji: '💬',
                description: group.theme,
                memberCount: group.memberCount,
                reason: group.theme,
                matchedThemes: [group.theme],
              ),
            )
            .toList() ??
        const <SupportCommunityRecommendation>[];

    return SupportMatchResult(
      members: backendMembers.isNotEmpty ? backendMembers : localMatches.members,
      communities: backendCommunities.isNotEmpty
          ? backendCommunities
          : localMatches.communities,
      recommendations: localMatches.recommendations,
      crisisResources: backendResponse.crisisResources?.isNotEmpty == true
          ? backendResponse.crisisResources!
          : localMatches.crisisResources,
      retrievalPlan: localMatches.retrievalPlan,
      source: backendMembers.isNotEmpty || backendCommunities.isNotEmpty
          ? 'hybrid-backend-matching'
          : localMatches.source,
    );
  }

  /// Clear current match results
  void clearMatchResults() {
    _currentCheckInResult = null;
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
      case 'crisis':
        return RiskLevel.high;
      case 'pending':
        return RiskLevel.low;
      default:
        return RiskLevel.low;
    }
  }
}
