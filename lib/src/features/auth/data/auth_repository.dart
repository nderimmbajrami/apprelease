import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/data/backend.dart';
import '../domain/app_user.dart';
import 'local_auth_repository.dart';
import 'supabase_auth_repository.dart';

part 'auth_repository.g.dart';

/// Sessions.
abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> updateName(String name);

  Future<void> signOut();

  /// The signed-in person removing themselves and everything they own.
  Future<void> deleteOwnAccount();

  void dispose();
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final repository = switch (ref.watch(backendProvider)) {
    Backend.local => LocalAuthRepository(signedIn: AppConfig.demoAutoSignIn),
    Backend.supabase => SupabaseAuthRepository(
      ref.watch(supabaseClientProvider),
    ),
  };
  ref.onDispose(repository.dispose);
  return repository;
}

@Riverpod(keepAlive: true)
Stream<AppUser?> authStateChanges(Ref ref) =>
    ref.watch(authRepositoryProvider).authStateChanges();

/// The signed-in user, or null.
@Riverpod(keepAlive: true)
AppUser? currentUser(Ref ref) => ref.watch(authStateChangesProvider).value;
