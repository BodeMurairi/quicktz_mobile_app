import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/conversation_repository.dart';

final conversationRepositoryProvider =
    Provider((_) => ConversationRepository());

final conversationsProvider =
    FutureProvider<List<ConversationModel>>((ref) {
  return ref.read(conversationRepositoryProvider).getMyConversations();
});

final conversationMessagesProvider =
    FutureProvider.family<List<ChatMessageModel>, String>((ref, conversationId) {
  return ref.read(conversationRepositoryProvider).getMessages(conversationId);
});

// The conversation currently open on screen, if any — MessageWatcher uses this to
// skip popping a "new message" notification for a thread the rider is already reading.
final activeConversationIdProvider = StateProvider<String?>((_) => null);
