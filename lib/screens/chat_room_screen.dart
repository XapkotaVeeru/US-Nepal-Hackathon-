import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/message_model.dart';
import '../models/micro_community_model.dart';
import '../providers/app_state_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/community_provider.dart';
import '../services/emotion_service.dart';
import '../services/speech_service.dart';
import '../services/websocket_service.dart' as ws;

/// Full-featured chat room screen with real-time WebSocket messaging
class ChatRoomScreen extends StatefulWidget {
  final String communityId;
  final String communityName;
  final String communityEmoji;
  /// Voice transcript to post once after joining (when routing to a recommended group).
  final String? pendingVoiceMessage;

  const ChatRoomScreen({
    super.key,
    required this.communityId,
    required this.communityName,
    this.communityEmoji = '💬',
    this.pendingVoiceMessage,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _sendButtonController;
  bool _showScrollToBottom = false;

  final SpeechService _speechService = SpeechService();
  bool _isVoiceListening = false;
  bool _isAnalyzingEmotion = false;

  @override
  void initState() {
    super.initState();

    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onTextChanged);

    // Join the community channel and load history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.openCommunity(widget.communityId);
      chatProvider.clearUnread(widget.communityId);
      _speechService.initialize();

      final pending = widget.pendingVoiceMessage;
      if (pending != null && pending.trim().isNotEmpty) {
        _sendMessageWithText(pending);
      }
    });
  }

  Future<void> _onMicLongPressStart() async {
    if (_isAnalyzingEmotion) return;
    
    final initialized = await _speechService.initialize();
    if (!initialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition is not available.'),
          ),
        );
      }
      return;
    }

    setState(() => _isVoiceListening = true);
    
    await _speechService.startListening(
      onResult: (_) {},
    );
  }

  Future<void> _onMicLongPressEnd() async {
    if (!_isVoiceListening) return;
    
    setState(() => _isVoiceListening = false);
    final transcript = await _speechService.stopListening();
    
    if (transcript.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture speech. Try again.')),
        );
      }
      return;
    }
    
    await _runEmotionPipeline(transcript);
  }

  Future<void> _runEmotionPipeline(String text) async {
    EmotionAnalysis? analysis;

    while (true) {
      if (!mounted) return;
      setState(() => _isAnalyzingEmotion = true);
      
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Understanding how you feel...',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      try {
        analysis = await EmotionService.analyzeEmotion(text);
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isAnalyzingEmotion = false);
        break;
      } catch (_) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isAnalyzingEmotion = false);
        
        final retry = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Could not reach the service'),
            content: const Text(
              'Check your connection and try again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
        
        if (retry != true) return;
        if (!mounted) return;
      }
    }

    if (!mounted) return;

    final recommendedGroup = analysis.recommendedGroup;
    final riskLevel = analysis.riskLevel;

    final communities = context.read<CommunityProvider>().allCommunities;
    final community = EmotionService.matchCommunityForRecommendation(
      recommendedGroup,
      communities,
    );
    
    if (community == null) {
      if (!mounted) return;
      _sendMessageWithText(text);
      return;
    }

    final risk = riskLevel.toUpperCase();
    if (risk == 'MEDIUM' || risk == 'HIGH') {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Before we continue'),
          content: Text(
            risk == 'HIGH'
                ? 'What you shared may reflect strong distress. You will be taken to a peer group that may help. If you are in immediate danger, use Crisis Resources from the menu.'
                : 'You may be going through a difficult time. We will take you to a supportive group. You can use Crisis Resources from the menu anytime.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    }

    if (!mounted) return;
    routeToGroup(community, text);
  }

  void routeToGroup(MicroCommunity community, String transcript) {
    context.read<CommunityProvider>().joinCommunity(community.id);
    
    if (community.id == widget.communityId) {
      _sendMessageWithText(transcript);
      return;
    }
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ChatRoomScreen(
          communityId: community.id,
          communityName: community.name,
          communityEmoji: community.emoji,
          pendingVoiceMessage: transcript,
        ),
      ),
    );
  }

  void _onScroll() {
    final showBtn =
        _scrollController.offset > 200;
    if (showBtn != _showScrollToBottom) {
      setState(() => _showScrollToBottom = showBtn);
    }
  }

  void _onTextChanged() {
    if (_messageController.text.isNotEmpty) {
      _sendButtonController.forward();
      // Send typing indicator
      context.read<ChatProvider>().sendTyping(widget.communityId);
    } else {
      _sendButtonController.reverse();
    }
  }

  void _sendMessageWithText(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;

    final appState = context.read<AppStateProvider>();
    final chatProvider = context.read<ChatProvider>();

    chatProvider.sendMessage(
      communityId: widget.communityId,
      content: text,
      senderId: appState.anonymousId ?? 'unknown',
      senderName: appState.currentUser?.displayName ?? 'Anonymous',
    );

    _messageController.clear();
    _scrollToBottom();
  }

  void _sendMessage() {
    _sendMessageWithText(_messageController.text);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _speechService.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final userId = context.read<AppStateProvider>().anonymousId ?? '';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.cream,
      // ── App Bar ───────────────────────────────
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(widget.communityEmoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.communityName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Consumer<ChatProvider>(
                    builder: (context, chat, _) {
                      if (chat.typingUsers.isNotEmpty) {
                        return Text(
                          '${chat.typingUsers.length} typing...',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                      return Text(
                        chat.isConnected
                            ? 'Live community'
                            : chat.connectionState == ws.ConnectionState.reconnecting
                                ? 'Reconnecting...'
                                : 'Assistant mode',
                        style: TextStyle(
                          fontSize: 11,
                          color: chat.isConnected
                              ? AppColors.sage
                              : chat.connectionState ==
                                      ws.ConnectionState.reconnecting
                                  ? colorScheme.error
                                  : colorScheme.outline,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            onPressed: () => _showCommunityInfo(context),
          ),
        ],
      ),

      // ── Body ─────────────────────────────────
      body: Column(
        children: [
          // Connection status banner
          Consumer<ChatProvider>(
            builder: (context, chat, _) {
              if (chat.connectionState == ws.ConnectionState.reconnecting) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  color: AppColors.amber.withValues(alpha: 0.15),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.amber,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Reconnecting...',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.amber,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (chat.isAssistantFallbackMode) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.45),
                  child: const Text(
                    'Realtime peer chat is unavailable right now. You can still keep going with the assistant and any saved message history.',
                    style: TextStyle(fontSize: 12),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chat, _) {
                final messages = chat.messagesForCommunity(widget.communityId);

                if (chat.isLoading && messages.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(color: colorScheme.primary),
                  );
                }

                if (messages.isEmpty) {
                  return _EmptyChat(communityName: widget.communityName);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == userId;
                    final showAvatar = index == 0 ||
                        messages[index - 1].senderId != message.senderId;

                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      showAvatar: showAvatar,
                      isDark: isDark,
                    );
                  },
                );
              },
            ),
          ),

          // ── Input Bar ──────────────────────────
          _MessageInput(
            controller: _messageController,
            focusNode: _focusNode,
            sendButtonController: _sendButtonController,
            onSend: _sendMessage,
            isDark: isDark,
            isVoiceListening: _isVoiceListening,
            isAnalyzingEmotion: _isAnalyzingEmotion,
            onMicLongPressStart: _onMicLongPressStart,
            onMicLongPressEnd: _onMicLongPressEnd,
          ),
        ],
      ),

      // Scroll-to-bottom FAB
      floatingActionButton: _showScrollToBottom
          ? FloatingActionButton.small(
              onPressed: _scrollToBottom,
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            )
          : null,
    );
  }

  void _showCommunityInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkCard
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.communityEmoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              widget.communityName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This is a safe space for peer support.\nBe kind, be honest, be anonymous.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _InfoStat(
                    icon: Icons.people, label: 'Members', value: '~200'),
                _InfoStat(
                    icon: Icons.chat_bubble, label: 'Messages', value: '1.2k'),
                _InfoStat(
                    icon: Icons.access_time, label: 'Active', value: 'Now'),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Message Bubble
// ═══════════════════════════════════════════════
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // System message
    if (message.type == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            message.content,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.inkMuted : AppColors.inkLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // Match notification
    if (message.type == MessageType.matchNotification) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.sage.withValues(alpha: 0.15),
              AppColors.amber.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Peer Match Found!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.sage,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    message.content,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.ink),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Regular message
    return Padding(
      padding: EdgeInsets.only(
        top: showAvatar ? 12 : 2,
        bottom: 2,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showAvatar && !isMe)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Text(
                message.senderName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sage,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? AppColors.sage
                  : (isDark ? AppColors.darkCard : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border: isMe
                  ? null
                  : Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.creamDark,
                    ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: isMe
                        ? Colors.white
                        : (isDark ? Colors.white : AppColors.ink),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppColors.inkMuted,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        _statusIcon(message.status),
                        size: 13,
                        color: message.status == MessageStatus.failed
                            ? Colors.red.shade300
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour:$m $period';
  }

  IconData _statusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }
}

// ═══════════════════════════════════════════════
//  Empty Chat State
// ═══════════════════════════════════════════════
class _EmptyChat extends StatelessWidget {
  final String communityName;
  const _EmptyChat({required this.communityName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.sage.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 36,
                color: AppColors.sage,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to $communityName',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation — you\'re anonymous and safe here.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Message Input
// ═══════════════════════════════════════════════
class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final AnimationController sendButtonController;
  final VoidCallback onSend;
  final bool isDark;
  final bool isVoiceListening;
  final bool isAnalyzingEmotion;
  final Future<void> Function() onMicLongPressStart;
  final Future<void> Function() onMicLongPressEnd;

  const _MessageInput({
    required this.controller,
    required this.focusNode,
    required this.sendButtonController,
    required this.onSend,
    required this.isDark,
    required this.isVoiceListening,
    required this.isAnalyzingEmotion,
    required this.onMicLongPressStart,
    required this.onMicLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.creamDark,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.creamDark,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.ink,
                ),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Share what\'s on your mind...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.35)
                        : AppColors.inkMuted,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onLongPressStart: (_) {
              if (!isAnalyzingEmotion) onMicLongPressStart();
            },
            onLongPressEnd: (_) => onMicLongPressEnd(),
            child: Material(
              color: isVoiceListening
                  ? AppColors.sage.withValues(alpha: 0.35)
                  : (isDark ? AppColors.darkSurface : AppColors.creamDark),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {},
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    isVoiceListening ? Icons.mic : Icons.mic_none_rounded,
                    color: isVoiceListening ? AppColors.sage : AppColors.inkMuted,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          ScaleTransition(
            scale: CurvedAnimation(
              parent: sendButtonController,
              curve: Curves.easeOutBack,
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.sage,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sage.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward_rounded,
                    color: Colors.white, size: 22),
                onPressed: onSend,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Community Info Stat
// ═══════════════════════════════════════════════
class _InfoStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.sage, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.inkMuted)),
      ],
    );
  }
}
