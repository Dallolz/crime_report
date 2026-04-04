import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  SupabaseClient get client => _client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'display_name': displayName ?? username,
      },
    );
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  Future<bool> signInWithGoogle() async {
    final response = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.sportmatch.app://callback',
    );
    return response;
  }

  Future<bool> signInWithApple() async {
    final response = await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'com.sportmatch.app://callback',
    );
    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;
    final response =
        await _client.from('profiles').select().eq('id', userId).single();
    return response;
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? city,
    double? latitude,
    double? longitude,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (city != null) updates['city'] = city;
    if (latitude != null && longitude != null) {
      updates['location'] = 'POINT($longitude $latitude)';
    }

    await _client.from('profiles').update(updates).eq('id', userId);
  }

  Future<void> saveSelectedSports(List<Map<String, dynamic>> sports) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    final rows = sports.map((s) {
      return {
        'player_id': userId,
        'sport_id': s['sport_id'],
        'skill_level': s['skill_level'] ?? 'beginner',
      };
    }).toList();

    await _client.from('player_sports').upsert(rows);
  }
}
