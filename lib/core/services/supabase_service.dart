import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;
  static String? get currentUserId => currentUser?.id;

  static bool get isAuthenticated => currentUser != null;

  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  static GoTrueClient get auth => client.auth;
  static SupabaseQueryBuilder table(String name) => client.from(name);
  static RealtimeChannel channel(String name) => client.channel(name);
  static SupabaseStorageClient get storage => client.storage;
  static FunctionsClient get functions => client.functions;
}
