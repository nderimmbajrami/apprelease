import 'dart:async';

import '../../../core/utils/id.dart';
import '../domain/app_user.dart';
import '../domain/auth_failure.dart';
import 'auth_repository.dart';

/// In-memory accounts for the demo and the tests.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({
    List<({AppUser user, String password})>? seed,
    bool signedIn = false,
  }) : _accounts = [
         ...?seed,
         if (seed == null)
           (
             user: const AppUser(
               id: 'user-demo',
               name: 'Demo Developer',
               email: 'demo@apprelease.store',
               teamId: 'user-demo',
             ),
             password: 'demo1234',
           ),
       ] {
    if (signedIn) _current = _accounts.first.user;
  }

  static const demoEmail = 'demo@apprelease.store';
  static const demoPassword = 'demo1234';

  final List<({AppUser user, String password})> _accounts;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final match = _accounts.where(
      (a) => a.user.email == email.trim().toLowerCase(),
    );
    if (match.isEmpty || match.first.password != password) {
      throw const AuthException(AuthFailure.invalidCredentials);
    }
    _set(match.first.user);
    return match.first.user;
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalised = email.trim().toLowerCase();
    if (_accounts.any((a) => a.user.email == normalised)) {
      throw const AuthException(AuthFailure.emailAlreadyUsed);
    }
    final id = newId();
    final user = AppUser(
      id: id,
      name: name.trim(),
      email: normalised,
      teamId: id,
    );
    _accounts.add((user: user, password: password));
    _set(user);
    return user;
  }

  @override
  Future<void> updateName(String name) async {
    final current = _current;
    if (current == null) return;
    final updated = current.copyWith(name: name.trim());
    final index = _accounts.indexWhere((a) => a.user.id == current.id);
    _accounts[index] = (user: updated, password: _accounts[index].password);
    _set(updated);
  }

  @override
  Future<void> signOut() async => _set(null);

  @override
  Future<void> deleteOwnAccount() async {
    _accounts.removeWhere((a) => a.user.id == _current?.id);
    _set(null);
  }

  @override
  void dispose() => _controller.close();

  void _set(AppUser? user) {
    _current = user;
    if (!_controller.isClosed) _controller.add(user);
  }
}
