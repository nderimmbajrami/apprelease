import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/id.dart';
import '../../auth/data/auth_repository.dart';
import '../data/credentials_repository.dart';
import '../domain/credential.dart';

part 'credentials_controller.g.dart';

@riverpod
class CredentialsController extends _$CredentialsController {
  @override
  Future<void> build() async {}

  Future<bool> addCredential({
    required CredentialKind kind,
    required String name,
    required Map<String, String> meta,
    required CredentialSecret secret,
    String? appId,
  }) {
    final user = ref.read(currentUserProvider);
    if (user == null) return Future.value(false);
    final credential = Credential(
      id: newId(),
      teamId: user.teamId ?? user.id,
      kind: kind,
      name: _reference(name),
      createdAt: DateTime.now(),
      meta: meta,
      appId: appId,
    );
    return _run(
      () => ref
          .read(credentialsRepositoryProvider)
          .addCredential(credential, secret),
    );
  }

  /// Runs the store check; null when the call itself failed.
  Future<List<CredentialCheck>?> check(String id) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => ref.read(credentialsRepositoryProvider).check(id),
    );
    if (ref.mounted) {
      state = result.hasError
          ? AsyncError(result.error!, result.stackTrace!)
          : const AsyncData(null);
    }
    return result.value;
  }

  Future<bool> linkToApp(String id, String? appId) =>
      _run(() => ref.read(credentialsRepositoryProvider).linkToApp(id, appId));

  Future<bool> deleteCredential(String id) =>
      _run(() => ref.read(credentialsRepositoryProvider).deleteCredential(id));

  /// `Upload Keystore` → `upload_keystore`: the name has to be a yaml key.
  static String _reference(String name) => name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(action);
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}
