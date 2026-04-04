import 'package:supabase_flutter/supabase_flutter.dart';

class SportRepository {
  final SupabaseClient _client;

  SportRepository(this._client);

  Future<List<Map<String, dynamic>>> getAllSports() async {
    final response = await _client
        .from('sports')
        .select()
        .order('display_name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> getSport(int sportId) async {
    final response = await _client
        .from('sports')
        .select()
        .eq('id', sportId)
        .single();
    return response;
  }

  Future<List<Map<String, dynamic>>> getSportPlayers(int sportId, {String? city}) async {
    var query = _client
        .from('player_sports')
        .select('*, player:profiles!player_id(*)')
        .eq('sport_id', sportId)
        .order('elo_rating', ascending: false);

    final response = await query.limit(50);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getSportMatches(int sportId) async {
    final response = await _client
        .from('matches')
        .select('*, creator:profiles!creator_id(*), participants:match_participants(count)')
        .eq('sport_id', sportId)
        .eq('status', 'open')
        .order('scheduled_at', ascending: true)
        .limit(20);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getLeaderboard(int sportId, {String? city, int limit = 20}) async {
    var query = _client
        .from('player_sports')
        .select('*, player:profiles!player_id(*)')
        .eq('sport_id', sportId)
        .order('elo_rating', ascending: false)
        .limit(limit);

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }
}
