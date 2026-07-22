/// One `ai_chats/{chatId}` document — a conversation session. See
/// architecture doc §4.12.
class ChatSession {
  final String id;
  final String patientUid;
  final String? title;
  final String? lastMessagePreview;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatSession({
    required this.id,
    required this.patientUid,
    this.title,
    this.lastMessagePreview,
    this.createdAt,
    this.updatedAt,
  });
}
