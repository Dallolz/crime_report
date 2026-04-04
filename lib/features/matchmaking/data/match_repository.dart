import 'package:supabase_flutter/supabase_flutter.dart';

class MatchRepository {
  final SupabaseClient _client;

  MatchRepository(this._client);

  /// Fetch open matches for a sport, ordered by scheduled_at.
  Future<List<Map<String, dynamic>>> getOpenMatches({
    required int sportId,
    double? latitude,
    double? longitude,
    double radiusKm = 50,
    String? minSkill,
    String? maxSkill,
  }) async {
    var query = _client
        .from('matches')
        .select(
          '*, sport:sports(*), creator:profiles!creator_id(*), '
          'participants:match_participants(*, player:profiles!player_id(*))',
        )
        .eq('sport_id', sportId)
        .eq('status', 'open')
        .order('scheduled_at', ascending: true);

    if (minSkill != null) {
      query = query.eq('min_skill', minSkill);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get all matches with optional status filter.
  Future<List<Map<String, dynamic>>> getMatches({String? status}) async {
    var query = _client.from('matches').select(
      '*, sport:sports(*), creator:profiles!creator_id(*), '
      'participants:match_participants(*, player:profiles!player_id(*))',
    );

    if (status != null) {
      query = query.eq('status', status);
    }

    final response =
        await query.order('created_at', ascending: false).limit(50);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get matches for the current user.
  Future<List<Map<String, dynamic>>> getMyMatches(String userId) async {
    final response = await _client
        .from('match_participants')
        .select(
          'match:matches(*, sport:sports(*), creator:profiles!creator_id(*), '
          'participants:match_participants(*, player:profiles!player_id(*)))',
        )
        .eq('player_id', userId)
        .order('joined_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get a single match with full details.
  Future<Map<String, dynamic>> getMatch(String matchId) async {
    final response = await _client
        .from('matches')
        .select(
          '*, sport:sports(*), creator:profiles!creator_id(*), '
          'participants:match_participants(*, player:profiles!player_id(*)), '
          'results:match_results(*)',
        )
        .eq('id', matchId)
        .single();
    return response;
  }

  /// Create a new match.
  Future<Map<String, dynamic>> createMatch({
    required int sportId,
    required String creatorId,
    required String matchType,
    String? venueName,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? scheduledAt,
    int? durationMin,
    int? maxPlayers,
    String? minSkill,
    String? maxSkill,
    String? description,
  }) async {
    final data = <String, dynamic>{
      'sport_id': sportId,
      'creator_id': creatorId,
      'match_type': matchType,
      'venue_name': venueName,
      'address': address,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'duration_min': durationMin,
      'max_players': maxPlayers,
      'min_skill': minSkill,
      'max_skill': maxSkill,
      'description': description,
    };

    if (latitude != null && longitude != null) {
      data['location'] = 'POINT($longitude $latitude)';
    }

    final response =
        await _client.from('matches').insert(data).select().single();

    // Auto-join the creator as team A.
    await _client.from('match_participants').insert({
      'match_id': response['id'],
      'player_id': creatorId,
      'team': 'A',
    });

    return response;
  }

  /// Join an existing match.
  Future<void> joinMatch({
    required String matchId,
    required String playerId,
    String? team,
  }) async {
    await _client.from('match_participants').insert({
      'match_id': matchId,
      'player_id': playerId,
      'team': team,
    });

    // Check if the match is now full.
    final match = await _client
        .from('matches')
        .select('max_players')
        .eq('id', matchId)
        .single();
    final participants = await _client
        .from('match_participants')
        .select('id')
        .eq('match_id', matchId);

    if (match['max_players'] != null &&
        participants.length >= match['max_players']) {
      await _client
          .from('matches')
          .update({'status': 'full'})
          .eq('id', matchId);
    }
  }

  /// Leave a match.
  Future<void> leaveMatch({
    required String matchId,
    required String playerId,
  }) async {
    await _client
        .from('match_participants')
        .delete()
        .eq('match_id', matchId)
        .eq('player_id', playerId);

    // Reopen the match if it was full.
    await _client
        .from('matches')
        .update({'status': 'open'})
        .eq('id', matchId)
        .eq('status', 'full');
  }

  /// Submit a match result.
  Future<void> submitResult({
    required String matchId,
    required String reportedBy,
    required int teamAScore,
    required int teamBScore,
    required String winnerTeam,
  }) async {
    await _client.from('match_results').insert({
      'match_id': matchId,
      'team_a_score': teamAScore,
      'team_b_score': teamBScore,
      'winner_team': winnerTeam,
      'reported_by': reportedBy,
    });

    await _client.from('matches').update({
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', matchId);
  }

  /// Submit a review for another player.
  Future<void> submitReview({
    required String matchId,
    required String reviewerId,
    required String reviewedId,
    required int rating,
    bool fairPlay = true,
    bool showedUp = true,
    String? comment,
  }) async {
    await _client.from('match_reviews').insert({
      'match_id': matchId,
      'reviewer_id': reviewerId,
      'reviewed_id': reviewedId,
      'rating': rating,
      'fair_play': fairPlay,
      'showed_up': showedUp,
      'comment': comment,
    });
  }

  /// Update match status.
  Future<void> updateMatchStatus({
    required String matchId,
    required String status,
  }) async {
    await _client
        .from('matches')
        .update({'status': status})
        .eq('id', matchId);
  }

  /// Subscribe to realtime match participant changes.
  RealtimeChannel subscribeToMatch(
    String matchId,
    void Function(dynamic) onUpdate,
  ) {
    return _client
        .channel('match-$matchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'match_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'match_id',
            value: matchId,
          ),
          callback: (payload) => onUpdate(payload),
        )
        .subscribe();
  }
}
