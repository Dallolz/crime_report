import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/chat_repository.dart';
import '../../auth/providers/auth_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(Supabase.instance.client);
});

final chatRoomsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final repo = ref.read(chatRepositoryProvider);
  return repo.getUserRooms(user.id);
});

final chatMessagesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, roomId) async {
  final repo = ref.read(chatRepositoryProvider);
  return repo.getMessages(roomId);
});
