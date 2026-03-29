import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/check_in_model.dart';
import '../models/message_model.dart';
import 'emotional_analysis_service.dart';

class LlmChatRequest {
  final String communityId;
  final String communityName;
  final String latestUserMessage;
  final List<Message> recentMessages;

  const LlmChatRequest({
    required this.communityId,
    required this.communityName,
    required this.latestUserMessage,
    required this.recentMessages,
  });
}

class LlmChatReply {
  final String content;
  final String source;
  final bool usedFallback;

  const LlmChatReply({
    required this.content,
    required this.source,
    required this.usedFallback,
  });
}

abstract class LlmChatService {
  Future<LlmChatReply> generateReply(LlmChatRequest request);
}

abstract class LlmChatAdapter {
  Future<LlmChatReply> generateReply(LlmChatRequest request);
}

class ResilientLlmChatService implements LlmChatService {
  final LlmChatAdapter? remoteAdapter;
  final LlmChatService fallback;

  const ResilientLlmChatService({
    this.remoteAdapter,
    required this.fallback,
  });

  @override
  Future<LlmChatReply> generateReply(LlmChatRequest request) async {
    final adapter = remoteAdapter;
    if (adapter == null) {
      return fallback.generateReply(request);
    }

    try {
      return await adapter.generateReply(request);
    } catch (_) {
      return fallback.generateReply(request);
    }
  }
}

class LocalSupportLlmChatService implements LlmChatService {
  final EmotionalAnalysisService emotionalAnalysisService;

  const LocalSupportLlmChatService({
    required this.emotionalAnalysisService,
  });

  @override
  Future<LlmChatReply> generateReply(LlmChatRequest request) async {
    final analysis = await emotionalAnalysisService.analyze(
      EmotionalAnalysisRequest(
        submission: CheckInSubmission(
          anonymousId: 'chat-assistant',
          content: request.latestUserMessage,
          inputMode: CheckInInputMode.text,
          createdAt: DateTime.now(),
          captureSource: 'chat-message',
        ),
      ),
    );

    final reply = _buildReply(
      message: request.latestUserMessage,
      analysis: analysis,
      recentMessages: request.recentMessages,
      communityName: request.communityName,
    );

    return LlmChatReply(
      content: reply,
      source: 'local-support-llm',
      usedFallback: true,
    );
  }

  String _buildReply({
    required String message,
    required EmotionalAnalysisResult analysis,
    required List<Message> recentMessages,
    required String communityName,
  }) {
    final normalized = message.toLowerCase();
    final followUp = _followUpQuestion(analysis, normalized);
    final nextStep = _nextStepSuggestion(analysis, normalized);
    final priorAssistantCount =
        recentMessages.where((item) => item.type == MessageType.assistant).length;

    if (analysis.riskLevel == 'HIGH') {
      return 'What you shared sounds urgent and important. Please use crisis support or contact someone near you right now if you may act on these thoughts. If you want, tell me whether you are physically safe in this moment.';
    }

    final opening = switch (analysis.moodDirection) {
      MoodDirection.upward =>
        'I can hear some steadier ground in what you said, even if things are not fully easy yet.',
      MoodDirection.steady =>
        'There is a lot mixed together in that, and it makes sense that it feels hard to sort through.',
      MoodDirection.downward =>
        'That sounds genuinely heavy. I’m glad you said it here instead of holding it alone.',
    };

    final themeReflection = analysis.themes.isEmpty
        ? 'We can slow this down and stay with the part that feels most important.'
        : 'It sounds like ${analysis.themes.take(2).join(' and ')} may be sitting underneath this.';

    final communityNote = priorAssistantCount == 0
        ? ' ${communityName.isNotEmpty ? 'This room can help with that too, and people here usually answer well when you keep one concrete detail in the message.' : 'Others here may relate.'}'
        : ' We can keep unpacking this together.';

    final engagementNote = priorAssistantCount == 0
        ? ' $nextStep'
        : ' One next step could be this: $nextStep';

    return '$opening $themeReflection$communityNote$engagementNote $followUp'
        .trim();
  }

  String _followUpQuestion(
    EmotionalAnalysisResult analysis,
    String normalized,
  ) {
    if (normalized.contains('anxious') || normalized.contains('panic')) {
      return 'What feels most intense right now: your body, your thoughts, or what might happen next?';
    }
    if (normalized.contains('study') || normalized.contains('exam')) {
      return 'Is the harder part the workload itself, fear of failing, or not having enough energy left?';
    }
    if (normalized.contains('family') || normalized.contains('relationship')) {
      return 'What part of that situation hurt the most for you?';
    }
    if (normalized.contains('work') || normalized.contains('job')) {
      return 'Is the heavier part the workload, the people around you, or the pressure you are putting on yourself?';
    }
    if (normalized.contains('lonely') || normalized.contains('alone')) {
      return 'What feels hardest right now: being physically alone, not feeling understood, or missing one specific person?';
    }
    if (normalized.contains('sleep') || normalized.contains('night')) {
      return 'Is this keeping you awake because your mind is racing, your body feels tense, or both?';
    }
    if (analysis.intensity >= 4) {
      return 'Before we solve anything, what is the one feeling that is loudest right this second?';
    }
    return 'If you want, say a little more about what today has felt like in your body or your thoughts.';
  }

  String _nextStepSuggestion(
    EmotionalAnalysisResult analysis,
    String normalized,
  ) {
    if (analysis.supportCategory == SupportCategory.academicStress) {
      return 'Try naming the exact assignment, exam, or deadline that feels biggest.';
    }
    if (analysis.supportCategory == SupportCategory.burnoutSupport) {
      return 'You could tell the room what part of work is draining you most today.';
    }
    if (analysis.supportCategory == SupportCategory.youthSupport) {
      return 'A simple check-in like "today felt heavier than I expected" is enough to start.';
    }
    if (normalized.contains('lonely') || normalized.contains('alone')) {
      return 'You might start with one sentence about what kind of connection you wish you had tonight.';
    }
    if (analysis.intensity >= 4) {
      return 'Keep it small: one feeling, one situation, and what you need most right now.';
    }
    return 'You can keep this chat moving by sharing one concrete moment from today.';
  }
}

class BedrockLlmChatAdapter implements LlmChatAdapter {
  const BedrockLlmChatAdapter();

  @override
  Future<LlmChatReply> generateReply(LlmChatRequest request) {
    // TODO: Plug teammate Bedrock chat orchestration here.
    throw UnimplementedError('Bedrock chat adapter is not wired yet.');
  }
}

class HuggingFaceSmallLlmChatAdapter implements LlmChatAdapter {
  static const String _defaultEndpoint = String.fromEnvironment(
    'HF_CHAT_ENDPOINT',
    defaultValue:
        'https://api-inference.huggingface.co/models/HuggingFaceTB/SmolLM2-1.7B-Instruct',
  );
  static const String _defaultApiToken = String.fromEnvironment(
    'HF_API_TOKEN',
    defaultValue: '',
  );

  final String endpoint;
  final String apiToken;
  final http.Client? client;

  const HuggingFaceSmallLlmChatAdapter({
    this.endpoint = _defaultEndpoint,
    this.apiToken = _defaultApiToken,
    this.client,
  });

  @override
  Future<LlmChatReply> generateReply(LlmChatRequest request) async {
    final httpClient = client ?? http.Client();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (apiToken.isNotEmpty) 'Authorization': 'Bearer $apiToken',
    };

    try {
      final response = await httpClient.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode({
          'inputs': _buildPrompt(request),
          'parameters': {
            'max_new_tokens': 120,
            'temperature': 0.7,
            'return_full_text': false,
          },
          'options': {'wait_for_model': true},
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Hugging Face chat request failed: ${response.statusCode} ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      final content = _extractGeneratedText(decoded).trim();
      if (content.isEmpty) {
        throw StateError('Hugging Face chat response was empty.');
      }

      return LlmChatReply(
        content: _sanitizeReply(content),
        source: 'huggingface-smollm-chat',
        usedFallback: false,
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  String _buildPrompt(LlmChatRequest request) {
    final recentContext = request.recentMessages
        .take(4)
        .map((message) => '${message.senderName}: ${message.content}')
        .join('\n');

    return '''
You are Serenity Guide, a warm peer-support chat assistant inside an anonymous mental-health support app.
Keep the reply supportive, specific, and calm.
Do not diagnose. Do not mention policies. Keep it under 3 short sentences.
If the user sounds unsafe, encourage immediate real-world crisis help.

Room: ${request.communityName}
Recent chat:
$recentContext

User:
${request.latestUserMessage}

Assistant:
''';
  }

  String _extractGeneratedText(dynamic decoded) {
    if (decoded is List && decoded.isNotEmpty) {
      final first = decoded.first;
      if (first is Map<String, dynamic>) {
        final generated = first['generated_text'] ?? first['summary_text'];
        if (generated is String) return generated;
      }
    }

    if (decoded is Map<String, dynamic>) {
      final generated = decoded['generated_text'] ?? decoded['summary_text'];
      if (generated is String) return generated;
    }

    throw StateError('Unsupported Hugging Face chat response shape.');
  }

  String _sanitizeReply(String raw) {
    final normalized = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return normalized;

    final sentences = normalized.split(RegExp(r'(?<=[.!?])\s+'));
    return sentences.take(3).join(' ').trim();
  }
}
