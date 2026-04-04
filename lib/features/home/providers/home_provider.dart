import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';

final upcomingMatchesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final client = Supabase.instance.client;
  final response = await client
      .from('match_participants')
      .select('match:matches(*, sport:sports(*))')
      .eq('player_id', user.id)
      .order('joined_at', ascending: false)
      .limit(5);

  final matches = <Map<String, dynamic>>[];
  for (final row in response) {
    final match = row['match'] as Map<String, dynamic>?;
    if (match != null && (match['status'] == 'open' || match['status'] == 'full')) {
      matches.add(match);
    }
  }
  return matches;
});

final nearbyMatchesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = Supabase.instance.client;
  final response = await client
      .from('matches')
      .select('*, sport:sports(*), creator:profiles!creator_id(*), participants:match_participants(count)')
      .eq('status', 'open')
      .order('created_at', ascending: false)
      .limit(10);
  return List<Map<String, dynamic>>.from(response);
});

final recentActivityProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = Supabase.instance.client;
  final response = await client
      .from('activity_feed')
      .select('*, actor:profiles!actor_id(*)')
      .order('created_at', ascending: false)
      .limit(20);
  return List<Map<String, dynamic>>.from(response);
});
