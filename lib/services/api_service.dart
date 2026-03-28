import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import '../models/session_model.dart';
import '../models/message_model.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  // Submission endpoints
  Future<SubmissionResponse> submitPost({
    required String anonymousId,
    required String content,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/submissions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'anonymousId': anonymousId,
          'content': content,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return SubmissionResponse.fromJson(data);
      } else {
        throw ApiException(
          'Failed to submit post: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Network error: $e', 0);
    }
  }

  // Session endpoints
  Future<List<ChatSession>> getUserSessions(String anonymousId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/users/$anonymousId/sessions'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final sessions = data['sessions'] as List;
        return sessions.map((s) => ChatSession.fromJson(s)).toList();
      } else {
        throw ApiException(
          'Failed to fetch sessions: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<List<Message>> getSessionMessages(String sessionId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/sessions/$sessionId/messages'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final messages = data['messages'] as List;
        return messages.map((m) => Message.fromJson(m)).toList();
      } else {
        throw ApiException(
          'Failed to fetch messages: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<void> resumeSession(String sessionId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/sessions/$sessionId/resume'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to resume session: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Network error: $e', 0);
    }
  }

  // Chat request endpoints
  Future<void> sendChatRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/chat-requests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fromUserId': fromUserId,
          'toUserId': toUserId,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          'Failed to send chat request: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<void> acceptChatRequest(String requestId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/chat-requests/$requestId/accept'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to accept chat request: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<void> declineChatRequest(String requestId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/chat-requests/$requestId/decline'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to decline chat request: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Network error: $e', 0);
    }
  }

  void dispose() {
    _client.close();
  }
}

class SubmissionResponse {
  final String submissionId;
  final String riskLevel;
  final List<SimilarUser>? similarUsers;
  final List<SupportGroup>? supportGroups;
  final List<CrisisResource>? crisisResources;

  SubmissionResponse({
    required this.submissionId,
    required this.riskLevel,
    this.similarUsers,
    this.supportGroups,
    this.crisisResources,
  });

  factory SubmissionResponse.fromJson(Map<String, dynamic> json) {
    return SubmissionResponse(
      submissionId: json['submissionId'] as String,
      riskLevel: json['riskLevel'] as String,
      similarUsers: json['similarUsers'] != null
          ? (json['similarUsers'] as List)
              .map((u) => SimilarUser.fromJson(u))
              .toList()
          : null,
      supportGroups: json['supportGroups'] != null
          ? (json['supportGroups'] as List)
              .map((g) => SupportGroup.fromJson(g))
              .toList()
          : null,
      crisisResources: json['crisisResources'] != null
          ? (json['crisisResources'] as List)
              .map((r) => CrisisResource.fromJson(r))
              .toList()
          : null,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
