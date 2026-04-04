import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/profile_repository.dart';
import '../../auth/providers/auth_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

final userProfileProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final repo = ref.read(profileRepositoryProvider);
  return repo.getProfile(userId);
});

final myProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final repo = ref.read(profileRepositoryProvider);
  return repo.getProfile(user.id);
});

final playerSportsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final repo = ref.read(profileRepositoryProvider);
  return repo.getPlayerSports(userId);
});

final matchHistoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final repo = ref.read(profileRepositoryProvider);
  return repo.getMatchHistory(userId);
});

final playerStatsProvider =
    FutureProvider.family<Map<String, dynamic>, ({String userId, int sportId})>(
        (ref, params) async {
  final repo = ref.read(profileRepositoryProvider);
  return repo.getPlayerStats(params.userId, params.sportId);
});

final isFollowingProvider =
    FutureProvider.family<bool, ({String currentUserId, String targetUserId})>(
        (ref, params) async {
  final repo = ref.read(profileRepositoryProvider);
  return repo.isFollowing(params.currentUserId, params.targetUserId);
});
