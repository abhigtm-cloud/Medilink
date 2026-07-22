import 'package:fpdart/fpdart.dart';
import 'package:medilink/core/error/failures.dart';
import 'package:medilink/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:medilink/features/ai_assistant/domain/entities/chat_session.dart';

abstract class AiChatRepository {
  /// This patient's past conversations, most-recently-updated first — for
  /// a chat history list, if/when one is shown.
  Stream<Either<Failure, List<ChatSession>>> watchChatSessions(String patientUid);

  Stream<Either<Failure, List<ChatMessage>>> watchMessages(String chatId);

  /// Creates a new `ai_chats` doc (direct client write, allowed by rules
  /// since `patientUid` must equal the caller). Returns the new chatId.
  Future<Either<Failure, String>> startChat({required String patientUid, String? title});

  /// Writes the user's message directly to Firestore (allowed by rules —
  /// see functions/src/ai/sendAiMessage.ts's own comment on this), then
  /// calls the sendAiMessage Callable Function, which runs the emergency
  /// keyword pre-filter and writes the assistant's reply. Returns whether
  /// the reply was an urgency short-circuit, so the caller can react (e.g.
  /// prompt the SOS flow) without waiting on the message stream.
  Future<Either<Failure, bool>> sendMessage({
    required String chatId,
    required String message,
    required AiCapability capability,
  });
}
