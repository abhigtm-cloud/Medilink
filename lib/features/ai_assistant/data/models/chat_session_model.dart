import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medilink/features/ai_assistant/domain/entities/chat_session.dart';

class ChatSessionModel extends ChatSession {
  const ChatSessionModel({
    required super.id,
    required super.patientUid,
    super.title,
    super.lastMessagePreview,
    super.createdAt,
    super.updatedAt,
  });

  factory ChatSessionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ChatSessionModel(
      id: doc.id,
      patientUid: data['patientUid'] as String? ?? '',
      title: data['title'] as String?,
      lastMessagePreview: data['lastMessagePreview'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientUid': patientUid,
      if (title != null) 'title': title,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
