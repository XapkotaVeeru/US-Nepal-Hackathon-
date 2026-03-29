import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/session_model.dart';
import '../providers/app_state_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/conversation_starters.dart';
import 'chat_room_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  String? _loadedForUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final anonymousId = context.read<AppStateProvider>().anonymousId;
    if (anonymousId != null && anonymousId != _loadedForUserId) {
      _loadedForUserId = anonymousId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ChatProvider>().loadSessions(anonymousId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final sessions = chatProvider.sessions;

        if (chatProvider.isLoading && sessions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          body: sessions.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () async {
                    final anonymousId = context.read<AppStateProvider>().anonymousId;
                    if (anonymousId != null) {
                      await context.read<ChatProvider>().loadSessions(anonymousId);
                    }
                  },
                  child: ListView.builder(
                    itemCount: sessions.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _buildHeader(context, sessions.length);
                      return _buildSessionTile(context, sessions[index - 1]);
                    },
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int sessionCount) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, size: 8, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  '$sessionCount active conversation${sessionCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'Chats update here after requests are accepted',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No chats yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a chat request or create a group from your match results. Once it is accepted, it will appear here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(BuildContext context, ChatSession session) {
    final colorScheme = Theme.of(context).colorScheme;
    final isGroup = session.type == 'group';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ChatRoomScreen(
              communityId: session.id,
              communityName: session.name,
              communityEmoji: isGroup ? '👥' : '💬',
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isGroup
                      ? [
                          colorScheme.secondaryContainer,
                          colorScheme.tertiaryContainer,
                        ]
                      : [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer,
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  isGroup ? '👥' : '💬',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.name,
                          style: TextStyle(
                            fontWeight: session.unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        _formatTimestamp(session.lastMessageTime ?? session.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: session.unreadCount > 0
                              ? colorScheme.primary
                              : colorScheme.outline,
                          fontWeight: session.unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isGroup)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${session.participantIds.length}',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          session.lastMessage ?? 'Open the chat to start talking.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: session.unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                            color: session.unreadCount > 0
                                ? colorScheme.onSurface
                                : colorScheme.outline,
                          ),
                        ),
                      ),
                      if (session.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${session.unreadCount}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}';
  }
}

class ChatItem {
  final String id;
  final String name;
  final String lastMessage;
  final String timestamp;
  final int unreadCount;
  final bool isGroup;
  final int? memberCount;
  final String? emoji;

  ChatItem({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.isGroup,
    this.memberCount,
    this.emoji,
  });
}

class ChatDetailScreen extends StatefulWidget {
  final ChatItem chat;

  const ChatDetailScreen({super.key, required this.chat});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _showStarters = true;
  final List<Map<String, dynamic>> _messages = [];
  Timer? _replyTimer;

  @override
  void initState() {
    super.initState();
    _messages.addAll([
      {
        'text': 'Hey, I read your post and wanted to reach out.',
        'isMe': false,
        'time': '2:30 PM',
      },
      {
        'text': 'Thank you. That means a lot.',
        'isMe': true,
        'time': '2:45 PM',
      },
    ]);
  }

  @override
  void dispose() {
    _replyTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'text': text,
        'isMe': true,
        'time': 'Now',
      });
      _messageController.clear();
      _showStarters = false;
    });
    _scheduleReply(text);
  }

  void _scheduleReply(String text) {
    _replyTimer?.cancel();
    _replyTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final reply = _buildReply(text);
      setState(() {
        _messages.add(reply);
      });
    });
  }

  Map<String, dynamic> _buildReply(String text) {
    final normalized = text.toLowerCase();
    final replyText = widget.chat.isGroup
        ? _groupReply(normalized)
        : _peerReply(normalized);
    return {
      'text': replyText,
      'isMe': false,
      'time': 'Now',
      'author': widget.chat.isGroup ? _groupResponderName() : widget.chat.name,
    };
  }

  String _peerReply(String normalized) {
    if (normalized.contains('stress') || normalized.contains('overwhelmed')) {
      return 'I hear that. What part is hitting you hardest right now so we can slow it down together?';
    }
    if (normalized.contains('lonely') || normalized.contains('alone')) {
      return 'I’m really glad you answered back. You don’t have to carry that alone in this chat.';
    }
    if (normalized.contains('work') || normalized.contains('job')) {
      return 'That sounds draining. Was it the workload, people, or pressure that got to you most today?';
    }
    if (normalized.contains('study') || normalized.contains('exam')) {
      return 'That makes sense. If you want, tell me which class or deadline feels biggest.';
    }
    return 'Thanks for sharing that. I’m here with you, and I’d like to understand a little more.';
  }

  String _groupReply(String normalized) {
    if (normalized.contains('stress') || normalized.contains('burnout')) {
      return 'A few of us relate to that. You can name the part that feels heaviest and this room will usually meet you there.';
    }
    if (normalized.contains('lonely') || normalized.contains('alone')) {
      return 'You’re in good company here tonight. A lot of people join this room when they need someone to answer back.';
    }
    if (normalized.contains('sleep') || normalized.contains('night')) {
      return 'Late hours can make everything louder. You can stay specific here about what is keeping your mind awake.';
    }
    return 'Thank you for dropping that in here. Someone in this room will probably relate more than you expect.';
  }

  String _groupResponderName() {
    final names = [
      'Anonymous Finch',
      'Anonymous Willow',
      'Anonymous Ember',
      'Anonymous Lark',
    ];
    return names[_messages.length % names.length];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  widget.chat.emoji ?? '😊',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  widget.chat.isGroup
                      ? '${widget.chat.memberCount ?? 0} members'
                      : 'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['isMe'] as bool;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment:
                        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['text'] as String,
                                style: TextStyle(
                                  color:
                                      isMe ? Colors.white : colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message['time'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_showStarters)
            ConversationStarters(
              onSuggestionTap: (text) {
                _messageController.text = text;
              },
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                        maxLines: 3,
                        minLines: 1,
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      onPressed: () => _sendMessage(_messageController.text),
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
