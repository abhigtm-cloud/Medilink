import 'package:fpdart/fpdart.dart';
import 'package:medilink/core/error/exceptions.dart';
import 'package:medilink/core/error/failures.dart';
import 'package:medilink/features/ai_assistant/data/datasources/ai_chat_remote_datasource.dart';
import 'package:medilink/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:medilink/features/ai_assistant/domain/entities/chat_session.dart';
import 'package:medilink/features/ai_assistant/domain/repositories/ai_chat_repository.dart';

class AiChatRepositoryImpl implements AiChatRepository {
  AiChatRepositoryImpl({required AiChatRemoteDataSource remote}) : _remote = remote;

  final AiChatRemoteDataSource _remote;

  Failure _mapException(Object e) {
    if (e is PermissionException) return PermissionFailure(e.message);
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ServerException) return UnknownFailure(e.message);
    return const UnknownFailure();
  }

  @override
  Stream<Either<Failure, List<ChatSession>>> watchChatSessions(String patientUid) async* {
    try {
      await for (final list in _remote.watchChatSessions(patientUid)) {
        yield Right(list);
      }
    } catch (e) {
      yield Left(_mapException(e));
    }
  }

  @override
  Stream<Either<Failure, List<ChatMessage>>> watchMessages(String chatId) async* {
    try {
      await for (final list in _remote.watchMessages(chatId)) {
        yield Right(list);
      }
    } catch (e) {
      yield Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, String>> startChat({required String patientUid, String? title}) async {
    try {
      final id = await _remote.startChat(patientUid: patientUid, title: title);
      return Right(id);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, bool>> sendMessage({
    required String chatId,
    required String message,
    required AiCapability capability,
  }) async {
    try {
      final urgencyFlag = await _remote.sendMessage(
        chatId: chatId,
        message: message,
        capability: capability,
      );
      return Right(urgencyFlag);
    } catch (e) {
      return Left(_mapException(e));
    }
  }
}
