import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<Map<String, dynamic>> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select('*, player_sports:player_sports(*, sport:sports(*))')
        .eq('id', userId)
        .single();
    return response;
  }

  Future<List<Map<String, dynamic>>> getPlayerSports(String userId) async {
    final response = await _client
        .from('player_sports')
        .select('*, sport:sports(*)')
        .eq('player_id', userId)
        .order('elo_rating', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? city,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (city != null) updates['city'] = city;
    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', userId);
    }
  }

  Future<List<Map<String, dynamic>>> getMatchHistory(String userId) async {
    final response = await _client
        .from('match_participants')
        .select('match:matches(*, sport:sports(*))')
        .eq('player_id', userId)
        .order('joined_at', ascending: false)
        .limit(20);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> getPlayerStats(String userId, int sportId) async {
    final playerSport = await _client
        .from('player_sports')
        .select()
        .eq('player_id', userId)
        .eq('sport_id', sportId)
        .single();

    final reviews = await _client
        .from('match_reviews')
        .select('rating, fair_play, showed_up')
        .eq('reviewed_id', userId);

    return {
      'player_sport': playerSport,
      'reviews': reviews,
      'total_reviews': reviews.length,
      'avg_rating': reviews.isEmpty
          ? 0.0
          : reviews.fold<double>(0, (sum, r) => sum + (r['rating'] as int)) / reviews.length,
    };
  }

  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    final response = await _client
        .from('follows')
        .select('follower:profiles!follower_id(*)')
        .eq('following_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    final response = await _client
        .from('follows')
        .select('following:profiles!following_id(*)')
        .eq('follower_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> followUser(String currentUserId, String targetUserId) async {
    await _client.from('follows').insert({
      'follower_id': currentUserId,
      'following_id': targetUserId,
    });
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    await _client
        .from('follows')
        .delete()
        .eq('follower_id', currentUserId)
        .eq('following_id', targetUserId);
  }

  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    final response = await _client
        .from('follows')
        .select('follower_id')
        .eq('follower_id', currentUserId)
        .eq('following_id', targetUserId);
    return response.isNotEmpty;
  }
}
