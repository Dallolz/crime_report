import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  final SupabaseClient _client;
  ChatRepository(this._client);

  Future<List<Map<String, dynamic>>> getUserRooms(String userId) async {
    final response = await _client
        .from('chat_members')
        .select('room:chat_rooms(*, members:chat_members(user:profiles!user_id(*)))')
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMessages(String roomId, {int limit = 50}) async {
    final response = await _client
        .from('chat_messages')
        .select('*, sender:profiles!sender_id(*)')
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response.reversed);
  }

  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
  }) async {
    await _client.from('chat_messages').insert({
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
    });
  }

  RealtimeChannel subscribeToMessages(
      String roomId, void Function(Map<String, dynamic>) onMessage) {
    return _client.channel('room-$roomId').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (payload) => onMessage(payload.newRecord),
    ).subscribe();
  }

  Future<Map<String, dynamic>> createRoom({
    required String name,
    required String type,
    int? sportId,
    String? matchId,
    required List<String> memberIds,
  }) async {
    final room = await _client.from('chat_rooms').insert({
      'name': name,
      'type': type,
      'sport_id': sportId,
      'match_id': matchId,
    }).select().single();

    for (final memberId in memberIds) {
      await _client.from('chat_members').insert({
        'room_id': room['id'],
        'user_id': memberId,
      });
    }
    return room;
  }
}
