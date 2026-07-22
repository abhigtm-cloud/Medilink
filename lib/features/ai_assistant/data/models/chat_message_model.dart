import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medilink/features/ai_assistant/domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.role,
    required super.content,
    super.createdAt,
    super.urgencyFlag,
    super.capability,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final metadata = (data['metadata'] as Map?)?.cast<String, dynamic>() ?? const {};
    return ChatMessageModel(
      id: doc.id,
      role: ChatRole.fromValue(data['role'] as String?),
      content: data['content'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      urgencyFlag: metadata['urgencyFlag'] as bool? ?? false,
      capability: metadata['capability'] != null
          ? AiCapability.fromValue(metadata['capability'] as String?)
          : null,
    );
  }

  static Map<String, dynamic> userMessageToFirestore(String content, AiCapability capability) {
    return {
      'role': 'user',
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'metadata': {'capability': capability.value},
    };
  }
}
