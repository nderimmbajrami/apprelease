import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/data/backend.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/credential.dart';
import 'local_credentials_repository.dart';
import 'supabase_credentials_repository.dart';

part 'credentials_repository.g.dart';

/// Signing keys and store access for a team.
abstract interface class CredentialsRepository {
  Stream<List<Credential>> watchCredentials();

  /// Stores the public facts and hands the secret to the backend, which
  /// encrypts it. The console never gets the secret back.
  Future<Credential> addCredential(
    Credential credential,
    CredentialSecret secret,
  );

  Future<void> deleteCredential(String id);
  void dispose();
}

@Riverpod(keepAlive: true)
CredentialsRepository credentialsRepository(Ref ref) {
  final repository = switch (ref.watch(backendProvider)) {
    Backend.local => LocalCredentialsRepository(),
    Backend.supabase => SupabaseCredentialsRepository(
      ref.watch(supabaseClientProvider),
    ),
  };
  ref.onDispose(repository.dispose);
  return repository;
}

@Riverpod(keepAlive: true)
Stream<List<Credential>> credentialsStream(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  final teamId = user.teamId ?? user.id;
  return ref
      .watch(credentialsRepositoryProvider)
      .watchCredentials()
      .map(
        (rows) => [
          for (final c in rows)
            if (c.teamId == teamId) c,
        ],
      );
}

/// The credentials of one kind, for the yaml generator and the forms.
@riverpod
List<Credential> credentialsOfKind(Ref ref, CredentialKind kind) => [
  for (final c in ref.watch(credentialsStreamProvider).value ?? const [])
    if (c.kind == kind) c,
];
