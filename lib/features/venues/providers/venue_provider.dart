import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/venue_repository.dart';

final venueRepositoryProvider = Provider<VenueRepository>((ref) {
  return VenueRepository(Supabase.instance.client);
});

final venuesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int?>(
        (ref, sportId) async {
  final repo = ref.read(venueRepositoryProvider);
  return repo.getVenues(sportId: sportId);
});

final allVenuesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(venueRepositoryProvider);
  return repo.getVenues();
});

final venueDetailProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, venueId) async {
  final repo = ref.read(venueRepositoryProvider);
  return repo.getVenue(venueId);
});
