import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/journal_entry_model.dart';
import '../models/mood_entry_model.dart';
import '../models/chat_request_model.dart';
import '../models/notification_model.dart';
import '../models/post_model.dart';
import '../models/session_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ApiService {
  final String baseUrl;
  final String chatBaseUrl;
  final http.Client _client;

  ApiService({
    required this.baseUrl,
    String? chatBaseUrl,
    http.Client? client,
  })  : chatBaseUrl = chatBaseUrl ?? baseUrl,
        _client = client ?? http.Client();

  Uri _chatUri(String path) => Uri.parse('$chatBaseUrl$path');

  // ═══════════════════════════════════════════════
  //  Posts (POST /posts)
  // ═══════════════════════════════════════════════

  Future<SubmissionResponse> submitPost({
    required String anonymousId,
    required String content,
    String region = 'US',
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/submissions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'anonymousId': anonymousId,
          'content': content,
          'consent': true,
          'region': region,
        }),
      );

      debugPrint('submitPost status: ${response.statusCode}');
      debugPrint('submitPost body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return SubmissionResponse.fromJson(data);
        } catch (parseError) {
          debugPrint('Failed to parse response: $parseError');
          // Return a basic response so the flow continues
          return SubmissionResponse(
            submissionId: 'api-${DateTime.now().millisecondsSinceEpoch}',
            riskLevel: 'pending',
          );
        }
      } else {
        throw ApiException(
          'Failed to submit post: ${response.statusCode} ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  // ═══════════════════════════════════════════════
  //  Anonymous User Bootstrap
  // ═══════════════════════════════════════════════

  Future<AnonymousUser> ensureAnonymousUserExists({
    required String userId,
    required String displayName,
  }) async {
    return upsertUserProfile(
      userId: userId,
      displayName: displayName,
    );
  }

  Future<AnonymousUser> getUserProfile({
    required String userId,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return AnonymousUser.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      throw ApiException(
        'Failed to fetch user profile: ${response.statusCode}',
        response.statusCode,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<AnonymousUser> upsertUserProfile({
    required String userId,
    String? displayName,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? chatRequestsEnabled,
    bool? groupInvitesEnabled,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (displayName != null) {
        payload['display_name'] = displayName.trim();
      }
      if (notificationsEnabled != null) {
        payload['notifications_enabled'] = notificationsEnabled;
      }
      if (soundEnabled != null) {
        payload['sound_enabled'] = soundEnabled;
      }
      if (chatRequestsEnabled != null) {
        payload['chat_requests_enabled'] = chatRequestsEnabled;
      }
      if (groupInvitesEnabled != null) {
        payload['group_invites_enabled'] = groupInvitesEnabled;
      }

      final response = await _client.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AnonymousUser.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      throw ApiException(
        'Failed to save user profile: ${response.statusCode}',
        response.statusCode,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<AnonymousUser> resetUserProfile({
    required String userId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/users/$userId/reset'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AnonymousUser.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      throw ApiException(
        'Failed to reset user profile: ${response.statusCode}',
        response.statusCode,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  // ═══════════════════════════════════════════════
  //  Communities
  // ═══════════════════════════════════════════════

  /// Discover communities (GET /communities/discover)
  Future<List<Map<String, dynamic>>> discoverCommunities() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/communities/discover'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['communities'] != null) {
          return (data['communities'] as List).cast<Map<String, dynamic>>();
        }
        return [];
      } else {
        throw ApiException(
          'Failed to discover communities: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('Error discovering communities: $e');
      return []; // Return empty list on failure; mock data handles the rest
    }
  }

  /// Join a community (POST /communities/{communityId}/join)
  Future<void> joinCommunity({
    required String communityId,
    required String anonymousId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/communities/$communityId/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'anonymousId': anonymousId,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          'Failed to join community: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('Error joining community: $e');
      // Silently fail — local state already updated
    }
  }

  // ═══════════════════════════════════════════════
  //  Messages
  // ═══════════════════════════════════════════════

  /// Send a message via HTTP (POST /messages)
  Future<void> sendMessage({
    required String communityId,
    required String anonymousId,
    required String content,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'communityId': communityId,
          'anonymousId': anonymousId,
          'content': content,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          'Failed to send message: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  /// Get messages for a community (GET /communities/{communityId}/messages)
  Future<List<Message>> getCommunityMessages(String communityId) async {
    final candidates = [
      Uri.parse('$baseUrl/communities/$communityId/messages'),
      _chatUri('/sessions/$communityId/messages'),
    ];

    for (final uri in candidates) {
      try {
        final response = await _client.get(
          uri,
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          List messagesList;
          if (data is List) {
            messagesList = data;
          } else if (data is Map && data['messages'] != null) {
            messagesList = data['messages'] as List;
          } else {
            return [];
          }
          return messagesList
              .map((m) => Message.fromJson(m as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        debugPrint('Error fetching messages from $uri: $e');
      }
    }

    return [];
  }

  // ═══════════════════════════════════════════════
  //  Mood Tracking
  // ═══════════════════════════════════════════════

  Future<List<MoodEntry>> listMoodEntries({
    required String userId,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/$userId/moods'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! List) return const <MoodEntry>[];
        return data
            .map((item) => MoodEntry.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      throw ApiException(
        'Failed to fetch mood entries: ${response.statusCode}',
        response.statusCode,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<MoodEntry> createMoodEntry({
    required String userId,
    required int moodLevel,
    required String note,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/users/$userId/moods'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mood_level': moodLevel,
          'note': note.trim(),
        }),
      );

      if (response.statusCode == 201) {
        return MoodEntry.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      throw ApiException(
        'Failed to create mood entry: ${response.statusCode}',
        response.statusCode,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  // ═══════════════════════════════════════════════
  //  Journaling
  // ═══════════════════════════════════════════════

  Future<List<JournalEntry>> listJournalEntries({
    required String userId,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/$userId/journals'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! List) return const <JournalEntry>[];
        return data
            .map((item) => JournalEntry.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      throw ApiException(
        'Failed to fetch journal entries: ${response.statusCode}',
        response.statusCode,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<JournalEntry> createJournalEntry({
    required String userId,
    required String title,
    required String content,
    String? prompt,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/users/$userId/journals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'content': content.trim(),
          'prompt': prompt,
        }),
      );

      if (response.statusCode == 201) {
        return JournalEntry.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      throw ApiException(
        'Failed to create journal entry: ${response.statusCode}',
        response.statusCode,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<void> deleteJournalEntry({
    required String journalId,
  }) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/journals/$journalId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 204 && response.statusCode != 404) {
        throw ApiException(
          'Failed to delete journal entry: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  // ═══════════════════════════════════════════════
  //  Insights (GET /insights)
  // ═══════════════════════════════════════════════

  Future<Map<String, dynamic>> getInsights() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/insights'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
          'Failed to fetch insights: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('Error fetching insights: $e');
      return {};
    }
  }

  // ═══════════════════════════════════════════════
  //  Matches (GET /matches)
  // ═══════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getMatches() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/matches'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['matches'] != null) {
          return (data['matches'] as List).cast<Map<String, dynamic>>();
        }
        return [];
      } else {
        throw ApiException(
          'Failed to fetch matches: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('Error fetching matches: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════
  //  Notifications
  // ═══════════════════════════════════════════════

  /// Register push notification token (POST /notifications/register)
  Future<void> registerPushToken({
    required String anonymousId,
    required String token,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/notifications/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'anonymousId': anonymousId,
          'token': token,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          'Failed to register token: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('Error registering push token: $e');
    }
  }

  /// Send push notification (POST /notifications/send)
  Future<void> sendPushNotification({
    required String targetUserId,
    required String title,
    required String body,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/notifications/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'targetUserId': targetUserId,
          'title': title,
          'body': body,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          'Failed to send notification: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('Error sending notification: $e');
    }
  }

  Future<List<NotificationItem>> listNotifications({
    required String userId,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/$userId/notifications'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data is List
            ? data
            : (data is Map && data['notifications'] is List)
                ? data['notifications'] as List
                : const [];
        return items
            .map((item) => NotificationItem.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
    return const [];
  }

  Future<NotificationItem?> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? actionData,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/users/$userId/notifications'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': notificationTypeToApi(type),
          'title': title,
          'message': message,
          'action_data': actionData,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return NotificationItem.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
    return null;
  }

  Future<NotificationItem?> markNotificationRead({
    required String notificationId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return NotificationItem.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
    return null;
  }

  // ═══════════════════════════════════════════════
  //  Media (POST /media/upload-url)
  // ═══════════════════════════════════════════════

  /// Get a pre-signed S3 upload URL
  Future<String?> getUploadUrl({
    required String fileName,
    required String contentType,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/media/upload-url'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fileName': fileName,
          'contentType': contentType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['uploadUrl'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting upload URL: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════
  //  Legacy session-based endpoints (kept for compat)
  // ═══════════════════════════════════════════════

  Future<List<ChatSession>> getUserSessions(String anonymousId) async {
    try {
      final response = await _client.get(
        _chatUri('/users/$anonymousId/sessions'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessions = data is List
            ? data
            : (data is Map && data['sessions'] is List)
                ? data['sessions'] as List
                : const [];
        return sessions.map((s) => ChatSession.fromJson(s)).toList();
      } else {
        return []; // Gracefully return empty on error
      }
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      return [];
    }
  }

  Future<List<Message>> getSessionMessages(String sessionId) async {
    try {
      final response = await _client.get(
        _chatUri('/sessions/$sessionId/messages'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = data is List
            ? data
            : (data is Map && data['messages'] is List)
                ? data['messages'] as List
                : const [];
        return messages.map((m) => Message.fromJson(m)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }

  Future<Message?> createSessionMessage({
    required String sessionId,
    required String senderId,
    required String senderName,
    required String content,
    MessageType type = MessageType.user,
  }) async {
    try {
      final response = await _client.post(
        _chatUri('/sessions/$sessionId/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_id': senderId,
          'sender_name': senderName,
          'content': content,
          'type': type.name,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Message.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('Error creating session message: $e');
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> getChatRequests(String anonymousId) async {
    try {
      final response = await _client.get(
        _chatUri('/users/$anonymousId/chat-requests'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['requests'] is List) {
          return (data['requests'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching chat requests: $e');
    }

    return [];
  }

  Future<ChatRequestResult> sendChatRequest({
    required String fromUserId,
    required String toUserId,
    String? contextSummary,
    List<String> matchedThemes = const [],
    String? supportCategory,
    String? userCategory,
  }) async {
    try {
      final response = await _client.post(
        _chatUri('/chat-requests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'from_user_id': fromUserId,
          'to_user_id': toUserId,
          'context_summary': contextSummary,
          'matched_themes': matchedThemes,
          'support_category': supportCategory,
          'user_category': userCategory,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          'Failed to send chat request: ${response.statusCode}',
          response.statusCode,
        );
      }

      return ChatRequestResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<void> acceptChatRequest(String requestId) async {
    try {
      final response = await _client.post(
        _chatUri('/chat-requests/$requestId/accept'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to accept chat request: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<void> declineChatRequest(String requestId) async {
    try {
      final response = await _client.post(
        _chatUri('/chat-requests/$requestId/decline'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to decline chat request: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
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
  final String? status;
  final String? message;
  final List<SimilarUser>? similarUsers;
  final List<SupportGroup>? supportGroups;
  final List<CrisisResource>? crisisResources;

  SubmissionResponse({
    required this.submissionId,
    required this.riskLevel,
    this.status,
    this.message,
    this.similarUsers,
    this.supportGroups,
    this.crisisResources,
  });

  factory SubmissionResponse.fromJson(Map<String, dynamic> json) {
    return SubmissionResponse(
      submissionId: json['submissionId'] as String,
      riskLevel: json['riskLevel'] as String,
      status: json['status'] as String?,
      message: json['message'] as String?,
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
