import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((state) => state.session?.user).valueOrNull;
});

final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final repo = ref.read(authRepositoryProvider);
  return repo.getProfile();
});

enum AuthStatus { unknown, authenticated, unauthenticated, onboarding }

final authStatusProvider = Provider<AuthStatus>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) {
      if (state.session != null) {
        return AuthStatus.authenticated;
      }
      return AuthStatus.unauthenticated;
    },
    loading: () => AuthStatus.unknown,
    error: (_, __) => AuthStatus.unauthenticated,
  );
});
