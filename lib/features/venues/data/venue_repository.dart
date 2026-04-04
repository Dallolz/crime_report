import 'package:supabase_flutter/supabase_flutter.dart';

class VenueRepository {
  final SupabaseClient _client;
  VenueRepository(this._client);

  Future<List<Map<String, dynamic>>> getVenues({int? sportId}) async {
    var query = _client.from('venues').select();
    if (sportId != null) {
      query = query.contains('sport_ids', [sportId]);
    }
    final response = await query.order('rating', ascending: false).limit(50);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> getVenue(int venueId) async {
    return await _client.from('venues').select().eq('id', venueId).single();
  }

  Future<void> addVenue({
    required String name,
    required String createdBy,
    String? address,
    double? latitude,
    double? longitude,
    List<int>? sportIds,
  }) async {
    final data = {
      'name': name,
      'created_by': createdBy,
      'address': address,
      'sport_ids': sportIds ?? [],
    };
    if (latitude != null && longitude != null) {
      data['location'] = 'POINT($longitude $latitude)';
    }
    await _client.from('venues').insert(data);
  }
}
