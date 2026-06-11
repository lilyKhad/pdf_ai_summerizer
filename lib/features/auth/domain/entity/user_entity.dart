class UserEntity {
  final String id;
  final String email;
  final DateTime? emailConfirmedAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.emailConfirmedAt,
  });
}
