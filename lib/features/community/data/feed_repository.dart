import 'package:supabase_flutter/supabase_flutter.dart';

class FeedRepository {
  final SupabaseClient _client;
  FeedRepository(this._client);

  Future<List<Map<String, dynamic>>> getFeed({int limit = 30}) async {
    final response = await _client
        .from('activity_feed')
        .select('*, actor:profiles!actor_id(*)')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getFollowingFeed(String userId, {int limit = 30}) async {
    final following = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);
    final ids = following.map((f) => f['following_id'] as String).toList();
    if (ids.isEmpty) return [];

    final response = await _client
        .from('activity_feed')
        .select('*, actor:profiles!actor_id(*)')
        .inFilter('actor_id', ids)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> postActivity({
    required String actorId,
    required String actionType,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? metadata,
  }) async {
    await _client.from('activity_feed').insert({
      'actor_id': actorId,
      'action_type': actionType,
      'target_type': targetType,
      'target_id': targetId,
      'metadata': metadata ?? {},
    });
  }

  Future<List<Map<String, dynamic>>> getNearbyPlayers({
    String? city,
    int limit = 50,
  }) async {
    var query = _client
        .from('profiles')
        .select('*, player_sports:player_sports(*, sport:sports(*))');
    if (city != null && city.isNotEmpty) {
      query = query.ilike('city', '%$city%');
    }
    final response = await query
        .order('last_active_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }
}
