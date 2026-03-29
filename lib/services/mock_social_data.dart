import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../models/session_model.dart';

class MockSocialData {
  MockSocialData._();

  static const String supportLoungeId = 'c14';
  static const String studyCircleId = 'c2';
  static const String burnoutCircleId = 'c11';
  static const String lonelyRoomId = 'c17';
  static const String nightResetId = 'c21';
  static const String directMayaId = 'mock-direct-peer';
  static const String directNoorId = 'mock-direct-noor';
  static const String directAaravId = 'mock-direct-aarav';

  static const Set<String> _mockGroupIds = {
    supportLoungeId,
    studyCircleId,
    burnoutCircleId,
    lonelyRoomId,
    nightResetId,
  };

  static const Set<String> _mockDirectIds = {
    directMayaId,
    directNoorId,
    directAaravId,
  };

  static bool isMockBackedConversation(String sessionId) {
    return _mockGroupIds.contains(sessionId) || _mockDirectIds.contains(sessionId);
  }

  static bool isMockDirectConversation(String sessionId) {
    return _mockDirectIds.contains(sessionId);
  }

  static String sessionTypeFor(String sessionId) {
    return isMockDirectConversation(sessionId) ? 'individual' : 'group';
  }

  static String sessionNameFor(String sessionId) {
    switch (sessionId) {
      case supportLoungeId:
        return 'Support Lounge';
      case studyCircleId:
        return 'Study Stress Circle';
      case burnoutCircleId:
        return 'Working Through Burnout';
      case lonelyRoomId:
        return 'Lonely but Trying';
      case nightResetId:
        return 'Night Reset Room';
      case directMayaId:
        return 'Maya | Support Listener';
      case directNoorId:
        return 'Noor | Check-in Buddy';
      case directAaravId:
        return 'Aarav | Support Listener';
      default:
        return 'Support Chat';
    }
  }

  static List<ChatSession> chatSessionsFor({
    required String currentUserId,
  }) {
    final now = DateTime.now();
    return [
      ChatSession(
        id: supportLoungeId,
        type: 'group',
        name: 'Support Lounge',
        participantIds: [currentUserId, 'peer-lina', 'peer-jay'],
        lastMessage: 'You do not have to fix everything tonight. Small steps count.',
        lastMessageTime: now.subtract(const Duration(minutes: 8)),
        unreadCount: 2,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      ChatSession(
        id: studyCircleId,
        type: 'group',
        name: 'Study Stress Circle',
        participantIds: [currentUserId, 'peer-owl', 'peer-kite', 'peer-rio'],
        lastMessage: 'Let us break tomorrow into one chapter, one meal, one rest break.',
        lastMessageTime: now.subtract(const Duration(minutes: 28)),
        unreadCount: 1,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      ChatSession(
        id: burnoutCircleId,
        type: 'group',
        name: 'Working Through Burnout',
        participantIds: [currentUserId, 'peer-maya', 'peer-sam'],
        lastMessage: 'Logging off on time is a win too.',
        lastMessageTime: now.subtract(const Duration(hours: 2)),
        unreadCount: 0,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      ChatSession(
        id: lonelyRoomId,
        type: 'group',
        name: 'Lonely but Trying',
        participantIds: [currentUserId, 'peer-noor', 'peer-ember', 'peer-avi'],
        lastMessage: 'Showing up counts, even if all you can say is that today felt lonely.',
        lastMessageTime: now.subtract(const Duration(hours: 3, minutes: 10)),
        unreadCount: 3,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      ChatSession(
        id: nightResetId,
        type: 'group',
        name: 'Night Reset Room',
        participantIds: [currentUserId, 'peer-asha', 'peer-zoe'],
        lastMessage: 'Before sleep, try one sentence about what you are carrying and one sentence about what can wait.',
        lastMessageTime: now.subtract(const Duration(hours: 4, minutes: 24)),
        unreadCount: 0,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      ChatSession(
        id: directMayaId,
        type: 'individual',
        name: 'Maya | Support Listener',
        participantIds: [currentUserId, 'peer-maya'],
        lastMessage: 'I am around if you want to vent for five minutes without pressure.',
        lastMessageTime: now.subtract(const Duration(hours: 5)),
        unreadCount: 0,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ChatSession(
        id: directNoorId,
        type: 'individual',
        name: 'Noor | Check-in Buddy',
        participantIds: [currentUserId, 'peer-noor'],
        lastMessage: 'You can send me the messy version. It does not need to sound polished.',
        lastMessageTime: now.subtract(const Duration(hours: 6, minutes: 40)),
        unreadCount: 1,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ChatSession(
        id: directAaravId,
        type: 'individual',
        name: 'Aarav | Support Listener',
        participantIds: [currentUserId, 'peer-aarav'],
        lastMessage: 'If today felt rough, start with the part that still feels loud in your head.',
        lastMessageTime: now.subtract(const Duration(hours: 8, minutes: 5)),
        unreadCount: 0,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<Message> messagesForSession({
    required String sessionId,
    required String currentUserId,
    String currentUserName = 'You',
  }) {
    final now = DateTime.now();
    switch (sessionId) {
      case supportLoungeId:
        return [
          Message(
            id: 'mock-msg-support-1',
            sessionId: sessionId,
            senderId: 'peer-lina',
            senderName: 'Lina',
            content: 'Checking in on everyone tonight. What feels heaviest right now?',
            timestamp: now.subtract(const Duration(minutes: 32)),
          ),
          Message(
            id: 'mock-msg-support-2',
            sessionId: sessionId,
            senderId: currentUserId,
            senderName: currentUserName,
            content: 'Mostly feeling tired and a little stuck.',
            timestamp: now.subtract(const Duration(minutes: 21)),
            status: MessageStatus.delivered,
          ),
          Message(
            id: 'mock-msg-support-3',
            sessionId: sessionId,
            senderId: 'peer-jay',
            senderName: 'Jay',
            content: 'That counts. You do not need a perfect explanation to deserve support.',
            timestamp: now.subtract(const Duration(minutes: 8)),
            type: MessageType.assistant,
            status: MessageStatus.delivered,
          ),
        ];
      case studyCircleId:
        return [
          Message(
            id: 'mock-msg-study-1',
            sessionId: sessionId,
            senderId: 'peer-owl',
            senderName: 'Owl',
            content: 'Exam pressure check-in: what subject is draining the most energy today?',
            timestamp: now.subtract(const Duration(hours: 1, minutes: 10)),
          ),
          Message(
            id: 'mock-msg-study-2',
            sessionId: sessionId,
            senderId: 'peer-rio',
            senderName: 'Rio',
            content: 'I used a 25 minute timer and finally started my revision notes.',
            timestamp: now.subtract(const Duration(minutes: 54)),
          ),
          Message(
            id: 'mock-msg-study-3',
            sessionId: sessionId,
            senderId: 'peer-kite',
            senderName: 'Kite',
            content: 'If you are overwhelmed, choose the smallest topic and call that a win.',
            timestamp: now.subtract(const Duration(minutes: 28)),
            type: MessageType.assistant,
            status: MessageStatus.delivered,
          ),
        ];
      case burnoutCircleId:
        return [
          Message(
            id: 'mock-msg-burnout-1',
            sessionId: sessionId,
            senderId: 'peer-maya',
            senderName: 'Maya',
            content: 'Reminder for the room: resting before you crash is still productive.',
            timestamp: now.subtract(const Duration(hours: 4)),
          ),
          Message(
            id: 'mock-msg-burnout-2',
            sessionId: sessionId,
            senderId: 'peer-sam',
            senderName: 'Sam',
            content: 'I blocked 15 minutes with no notifications and it helped more than I expected.',
            timestamp: now.subtract(const Duration(hours: 2, minutes: 40)),
          ),
          Message(
            id: 'mock-msg-burnout-3',
            sessionId: sessionId,
            senderId: 'peer-maya',
            senderName: 'Maya',
            content: 'Logging off on time is a win too.',
            timestamp: now.subtract(const Duration(hours: 2)),
            type: MessageType.assistant,
            status: MessageStatus.delivered,
          ),
        ];
      case lonelyRoomId:
        return [
          Message(
            id: 'mock-msg-lonely-1',
            sessionId: sessionId,
            senderId: 'peer-noor',
            senderName: 'Noor',
            content: 'This room is for the nights when you need someone to answer back.',
            timestamp: now.subtract(const Duration(hours: 3, minutes: 48)),
          ),
          Message(
            id: 'mock-msg-lonely-2',
            sessionId: sessionId,
            senderId: 'peer-ember',
            senderName: 'Ember',
            content: 'I joined because being around people quietly feels easier than pretending I am fine alone.',
            timestamp: now.subtract(const Duration(hours: 3, minutes: 30)),
          ),
          Message(
            id: 'mock-msg-lonely-3',
            sessionId: sessionId,
            senderId: 'peer-avi',
            senderName: 'Avi',
            content: 'Showing up counts, even if all you can say is that today felt lonely.',
            timestamp: now.subtract(const Duration(hours: 3, minutes: 10)),
            type: MessageType.assistant,
            status: MessageStatus.delivered,
          ),
        ];
      case nightResetId:
        return [
          Message(
            id: 'mock-msg-night-1',
            sessionId: sessionId,
            senderId: 'peer-asha',
            senderName: 'Asha',
            content: 'Night check-in question: what can wait until tomorrow?',
            timestamp: now.subtract(const Duration(hours: 5)),
          ),
          Message(
            id: 'mock-msg-night-2',
            sessionId: sessionId,
            senderId: currentUserId,
            senderName: currentUserName,
            content: 'The pressure to answer everyone right now can wait.',
            timestamp: now.subtract(const Duration(hours: 4, minutes: 44)),
            status: MessageStatus.delivered,
          ),
          Message(
            id: 'mock-msg-night-3',
            sessionId: sessionId,
            senderId: 'peer-zoe',
            senderName: 'Zoe',
            content: 'Before sleep, try one sentence about what you are carrying and one sentence about what can wait.',
            timestamp: now.subtract(const Duration(hours: 4, minutes: 24)),
            type: MessageType.assistant,
            status: MessageStatus.delivered,
          ),
        ];
      case directMayaId:
        return [
          Message(
            id: 'mock-msg-direct-1',
            sessionId: sessionId,
            senderId: 'peer-maya',
            senderName: 'Maya',
            content: 'Hey, I saw your support request. I can listen without trying to fix everything.',
            timestamp: now.subtract(const Duration(hours: 5, minutes: 20)),
          ),
          Message(
            id: 'mock-msg-direct-2',
            sessionId: sessionId,
            senderId: currentUserId,
            senderName: currentUserName,
            content: 'Thank you. I mostly need somewhere to start.',
            timestamp: now.subtract(const Duration(hours: 5, minutes: 2)),
            status: MessageStatus.delivered,
          ),
          Message(
            id: 'mock-msg-direct-3',
            sessionId: sessionId,
            senderId: 'peer-maya',
            senderName: 'Maya',
            content: 'Start small then. What has felt hardest today: the stress itself, or feeling alone with it?',
            timestamp: now.subtract(const Duration(hours: 4, minutes: 58)),
            type: MessageType.assistant,
            status: MessageStatus.delivered,
          ),
        ];
      case directNoorId:
        return [
          Message(
            id: 'mock-msg-direct-noor-1',
            sessionId: sessionId,
            senderId: 'peer-noor',
            senderName: 'Noor',
            content: 'Hi. I saw your check-in route and wanted to make this feel easy.',
            timestamp: now.subtract(const Duration(hours: 6, minutes: 55)),
          ),
          Message(
            id: 'mock-msg-direct-noor-2',
            sessionId: sessionId,
            senderId: 'peer-noor',
            senderName: 'Noor',
            content: 'You can send me the messy version. It does not need to sound polished.',
            timestamp: now.subtract(const Duration(hours: 6, minutes: 40)),
            type: MessageType.assistant,
            status: MessageStatus.delivered,
          ),
        ];
      case directAaravId:
        return [
          Message(
            id: 'mock-msg-direct-aarav-1',
            sessionId: sessionId,
            senderId: 'peer-aarav',
            senderName: 'Aarav',
            content: 'Hey. I am here for a low-pressure chat if today has been a lot.',
            timestamp: now.subtract(const Duration(hours: 8, minutes: 22)),
          ),
          Message(
            id: 'mock-msg-direct-aarav-2',
            sessionId: sessionId,
            senderId: 'peer-aarav',
            senderName: 'Aarav',
            content: 'If today felt rough, start with the part that still feels loud in your head.',
            timestamp: now.subtract(const Duration(hours: 8, minutes: 5)),
            type: MessageType.assistant,
            status: MessageStatus.delivered,
          ),
        ];
      default:
        return [
          Message(
            id: 'mock-msg-generic-1-$sessionId',
            sessionId: sessionId,
            senderId: 'peer-guide',
            senderName: 'Serenity Guide',
            content: 'You can talk normally here. Start with whatever feels most important right now.',
            timestamp: now.subtract(const Duration(minutes: 12)),
            type: MessageType.system,
            status: MessageStatus.delivered,
          ),
          Message(
            id: 'mock-msg-generic-2-$sessionId',
            sessionId: sessionId,
            senderId: 'peer-guide',
            senderName: 'Serenity Guide',
            content: 'Share what is on your mind and the app will keep the conversation moving locally.',
            timestamp: now.subtract(const Duration(minutes: 6)),
            type: MessageType.assistant,
            status: MessageStatus.delivered,
          ),
        ];
    }
  }

  static List<NotificationItem> notificationsFor({
    required String currentUserId,
  }) {
    final now = DateTime.now();
    return [
      NotificationItem(
        id: 'mock-notification-message-1',
        type: NotificationType.message,
        title: 'Support Lounge replied',
        message: 'Two people answered in Support Lounge. You can jump back in any time.',
        timestamp: now.subtract(const Duration(minutes: 9)),
        isRead: false,
        actionData: {
          'sessionId': supportLoungeId,
          'communityName': 'Support Lounge',
          'communityEmoji': '🤝',
        },
      ),
      NotificationItem(
        id: 'mock-notification-request-1',
        type: NotificationType.matchRequest,
        title: 'Aarav wants to talk to you',
        message: 'Aarav reached out for a gentle one-on-one support chat.',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 14)),
        isRead: false,
        actionData: {
          'requestId': 'mock-request-direct-1',
          'sessionId': directAaravId,
          'fromUserId': 'peer-aarav',
          'fromUserName': 'Aarav',
          'communityName': 'Aarav | Support Listener',
          'communityEmoji': '💬',
          'targetUserId': currentUserId,
        },
      ),
      NotificationItem(
        id: 'mock-notification-group-1',
        type: NotificationType.groupInvite,
        title: 'Join Study Stress Circle',
        message: 'A small exam-support room is ready if you want practical check-ins tonight.',
        timestamp: now.subtract(const Duration(hours: 3)),
        isRead: false,
        actionData: {
          'requestId': 'mock-request-group-1',
          'sessionId': studyCircleId,
          'communityId': studyCircleId,
          'communityName': 'Study Stress Circle',
          'communityEmoji': '📚',
          'groupName': 'Study Stress Circle',
        },
      ),
      NotificationItem(
        id: 'mock-notification-system-1',
        type: NotificationType.system,
        title: 'Daily support reminder',
        message: 'Your demo spaces stay active until live notifications are wired up.',
        timestamp: now.subtract(const Duration(hours: 7)),
        isRead: true,
      ),
    ];
  }
}
