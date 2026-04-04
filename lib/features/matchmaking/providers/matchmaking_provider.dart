import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/match_repository.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository(Supabase.instance.client);
});

final openMatchesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>(
  (ref, sportId) async {
    final repo = ref.read(matchRepositoryProvider);
    return repo.getOpenMatches(sportId: sportId);
  },
);

final myMatchesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  final repo = ref.read(matchRepositoryProvider);
  return repo.getMyMatches(userId);
});

final matchDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
  (ref, matchId) async {
    final repo = ref.read(matchRepositoryProvider);
    return repo.getMatch(matchId);
  },
);

final allOpenMatchesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(matchRepositoryProvider);
  return repo.getMatches(status: 'open');
});

/// Provider for loading all available sports.
final sportsListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await Supabase.instance.client
      .from('sports')
      .select()
      .order('display_name', ascending: true);
  return List<Map<String, dynamic>>.from(response);
});
