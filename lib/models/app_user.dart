class AppUser {
  final String username;
  final String role;

  AppUser({
    required this.username,
    required this.role,
  });

  bool get isAdmin => role == 'Administrador';
}
