import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/ai_assistant/data/datasources/ai_chat_remote_datasource.dart';
import 'package:medilink/features/ai_assistant/data/repositories/ai_chat_repository_impl.dart';
import 'package:medilink/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:medilink/features/ai_assistant/domain/entities/chat_session.dart';
import 'package:medilink/features/ai_assistant/domain/repositories/ai_chat_repository.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';

final aiChatRemoteDataSourceProvider = Provider<AiChatRemoteDataSource>(
  (ref) => AiChatRemoteDataSource(),
);

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  return AiChatRepositoryImpl(remote: ref.watch(aiChatRemoteDataSourceProvider));
});

final chatSessionsProvider = StreamProvider.autoDispose<List<ChatSession>>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  return ref
      .watch(aiChatRepositoryProvider)
      .watchChatSessions(uid)
      .map((e) => e.match((f) => throw f, (r) => r));
});

final chatMessagesProvider =
    StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, chatId) {
  return ref
      .watch(aiChatRepositoryProvider)
      .watchMessages(chatId)
      .map((e) => e.match((f) => throw f, (r) => r));
});
