import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/gamification_repository.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository(Supabase.instance.client);
});

final allBadgesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(gamificationRepositoryProvider);
  return repo.getAllBadges();
});

final userBadgesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, userId) async {
  final repo = ref.read(gamificationRepositoryProvider);
  return repo.getUserBadges(userId);
});

final activeChallengesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(gamificationRepositoryProvider);
  return repo.getActiveChallenges();
});

final userChallengesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, userId) async {
  final repo = ref.read(gamificationRepositoryProvider);
  return repo.getUserChallenges(userId);
});
