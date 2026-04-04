import 'package:supabase_flutter/supabase_flutter.dart';

class GamificationRepository {
  final SupabaseClient _client;
  GamificationRepository(this._client);

  Future<List<Map<String, dynamic>>> getAllBadges() async {
    final response = await _client.from('badges').select().order('id');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getUserBadges(String userId) async {
    final response = await _client
        .from('user_badges')
        .select('*, badge:badges(*)')
        .eq('user_id', userId)
        .order('earned_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getActiveChallenges() async {
    final response = await _client
        .from('challenges')
        .select()
        .eq('is_active', true)
        .order('ends_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getUserChallenges(String userId) async {
    final response = await _client
        .from('user_challenges')
        .select('*, challenge:challenges(*)')
        .eq('user_id', userId)
        .order('completed', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> joinChallenge(String userId, int challengeId) async {
    await _client.from('user_challenges').insert({
      'user_id': userId,
      'challenge_id': challengeId,
    });
  }

  Future<void> updateChallengeProgress(String userId, int challengeId, int progress) async {
    await _client.from('user_challenges').update({
      'progress': progress,
    }).eq('user_id', userId).eq('challenge_id', challengeId);
  }
}
