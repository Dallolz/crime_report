import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/feed_repository.dart';
import '../../auth/providers/auth_provider.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(Supabase.instance.client);
});

final globalFeedProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(feedRepositoryProvider);
  return repo.getFeed();
});

final followingFeedProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final repo = ref.read(feedRepositoryProvider);
  return repo.getFollowingFeed(user.id);
});

final nearbyPlayersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, city) async {
  final repo = ref.read(feedRepositoryProvider);
  return repo.getNearbyPlayers(city: city);
});
