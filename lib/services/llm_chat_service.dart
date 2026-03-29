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
