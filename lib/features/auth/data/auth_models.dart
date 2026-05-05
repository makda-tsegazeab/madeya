class AuthUserProfile {
  const AuthUserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.stationId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.phoneNumber,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? stationId;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? phoneNumber;
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.user});

  final String accessToken;
  final AuthUserProfile user;
}
