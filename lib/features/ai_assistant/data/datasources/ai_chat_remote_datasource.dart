import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:medilink/core/error/exceptions.dart';
import 'package:medilink/features/ai_assistant/data/models/chat_message_model.dart';
import 'package:medilink/features/ai_assistant/data/models/chat_session_model.dart';
import 'package:medilink/features/ai_assistant/domain/entities/chat_message.dart';

class AiChatRemoteDataSource {
  AiChatRemoteDataSource({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<ChatSessionModel>> watchChatSessions(String patientUid) {
    return _firestore
        .collection('ai_chats')
        .where('patientUid', isEqualTo: patientUid)
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(ChatSessionModel.fromFirestore).toList());
  }

  Stream<List<ChatMessageModel>> watchMessages(String chatId) {
    return _firestore
        .collection('ai_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessageModel.fromFirestore).toList());
  }

  Future<String> startChat({required String patientUid, String? title}) async {
    try {
      final ref = await _firestore
          .collection('ai_chats')
          .add(ChatSessionModel(id: '', patientUid: patientUid, title: title).toFirestore());
      return ref.id;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw const PermissionException();
      throw ServerException(e.message ?? 'Failed to start chat');
    }
  }

  /// Writes the user's message directly (allowed by rules), then calls the
  /// sendAiMessage Callable Function, which writes the assistant's reply
  /// and returns whether it was an urgency short-circuit.
  Future<bool> sendMessage({
    required String chatId,
    required String message,
    required AiCapability capability,
  }) async {
    try {
      await _firestore
          .collection('ai_chats')
          .doc(chatId)
          .collection('messages')
          .add(ChatMessageModel.userMessageToFirestore(message, capability));

      final result = await _functions.httpsCallable('sendAiMessage').call<Map<String, dynamic>>({
        'chatId': chatId,
        'message': message,
        'capability': capability.value,
      });
      return result.data['urgencyFlag'] as bool? ?? false;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        throw const PermissionException();
      }
      throw ServerException(e.message ?? 'Failed to send message');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw const PermissionException();
      throw ServerException(e.message ?? 'Failed to send message');
    }
  }
}
