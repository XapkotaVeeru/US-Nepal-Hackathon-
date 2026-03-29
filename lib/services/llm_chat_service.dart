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

    return const LlmChatReply(
      content: '',
      source: '',
      usedFallback: true,
    ).copyWith(
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
        ? ' ${communityName.isNotEmpty ? 'This room can help with that too.' : 'Others here may relate.'}'
        : '';

    return '$opening $themeReflection$communityNote $followUp'.trim();
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
    if (analysis.intensity >= 4) {
      return 'Before we solve anything, what is the one feeling that is loudest right this second?';
    }
    return 'If you want, say a little more about what today has felt like in your body or your thoughts.';
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

extension on LlmChatReply {
  LlmChatReply copyWith({
    String? content,
    String? source,
    bool? usedFallback,
  }) {
    return LlmChatReply(
      content: content ?? this.content,
      source: source ?? this.source,
      usedFallback: usedFallback ?? this.usedFallback,
    );
  }
}
