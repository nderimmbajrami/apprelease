/// A signed-in account.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.teamId,
  });

  final String id;
  final String name;
  final String email;

  /// The team the user's apps belong to. Null until the backend assigns one;
  /// the local backend uses the user id.
  final String? teamId;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return email[0].toUpperCase();
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  AppUser copyWith({String? name, String? teamId}) => AppUser(
    id: id,
    name: name ?? this.name,
    email: email,
    teamId: teamId ?? this.teamId,
  );
}
