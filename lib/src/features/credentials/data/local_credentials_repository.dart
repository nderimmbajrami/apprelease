import '../../../core/data/in_memory_table.dart';
import '../domain/credential.dart';
import 'credentials_repository.dart';

/// In-memory credentials. The secret is dropped on the floor: the demo has
/// no runner that could use it.
class LocalCredentialsRepository implements CredentialsRepository {
  LocalCredentialsRepository({List<Credential>? seed})
    : _table = InMemoryTable(seed ?? demoCredentials);

  static final demoCredentials = [
    Credential(
      id: 'cred-keystore',
      teamId: 'user-demo',
      kind: CredentialKind.androidKeystore,
      name: 'upload_keystore',
      createdAt: DateTime.now().subtract(const Duration(days: 11)),
      meta: const {'fileName': 'upload.jks', 'alias': 'upload'},
    ),
    Credential(
      id: 'cred-play',
      teamId: 'user-demo',
      kind: CredentialKind.googlePlayServiceAccount,
      name: 'google_play',
      createdAt: DateTime.now().subtract(const Duration(days: 11)),
      meta: const {
        'email': 'apprelease-publisher@acme-shop.iam.gserviceaccount.com',
      },
    ),
  ];

  final InMemoryTable<Credential> _table;

  @override
  Stream<List<Credential>> watchCredentials() => _table.watch().map(
    (rows) => [...rows]..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
  );

  @override
  Future<Credential> addCredential(
    Credential credential,
    CredentialSecret secret,
  ) async {
    _table.insert(credential);
    return credential;
  }

  @override
  Future<void> deleteCredential(String id) async =>
      _table.delete((row) => row.id == id);

  @override
  Future<List<CredentialCheck>> check(String id) async => const [
    CredentialCheck(
      package: 'com.acme.shop',
      status: 'ok',
      message: 'Google Play accepts uploads from this account.',
    ),
  ];

  @override
  void dispose() => _table.dispose();
}
