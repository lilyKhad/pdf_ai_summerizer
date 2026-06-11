import 'package:pdf_summerizer/features/auth/domain/entity/user_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserModel {
  final String id;
  final String email;
  final DateTime? emailConfirmedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.emailConfirmedAt,
  });

  factory UserModel.fromSupabaseUser(User user) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      emailConfirmedAt: user.emailConfirmedAt != null
          ? DateTime.tryParse(user.emailConfirmedAt!)
          : null,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      emailConfirmedAt: json['email_confirmed_at'] != null
          ? DateTime.tryParse(json['email_confirmed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'email_confirmed_at': emailConfirmedAt?.toIso8601String(),
    };
  }

  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        emailConfirmedAt: emailConfirmedAt,
      );
}