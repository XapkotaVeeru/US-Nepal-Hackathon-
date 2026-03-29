class ChatRequestResult {
  final String id;
  final String sessionId;
  final String status;

  const ChatRequestResult({
    required this.id,
    required this.sessionId,
    required this.status,
  });

  factory ChatRequestResult.fromJson(Map<String, dynamic> json) {
    return ChatRequestResult(
      id: json['id'] as String? ?? '',
      sessionId: (json['sessionId'] ?? json['session_id']) as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }
}
