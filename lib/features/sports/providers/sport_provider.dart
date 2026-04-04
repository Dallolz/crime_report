import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/sport_repository.dart';

final sportRepositoryProvider = Provider<SportRepository>((ref) {
  return SportRepository(Supabase.instance.client);
});

final allSportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(sportRepositoryProvider);
  return repo.getAllSports();
});

final sportDetailProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, sportId) async {
  final repo = ref.read(sportRepositoryProvider);
  return repo.getSport(sportId);
});

final sportPlayersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, sportId) async {
  final repo = ref.read(sportRepositoryProvider);
  return repo.getSportPlayers(sportId);
});

final sportMatchesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, sportId) async {
  final repo = ref.read(sportRepositoryProvider);
  return repo.getSportMatches(sportId);
});

final leaderboardProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, sportId) async {
  final repo = ref.read(sportRepositoryProvider);
  return repo.getLeaderboard(sportId);
});
