import 'package:pdf_summerizer/features/auth/domain/entity/user_entity.dart';

abstract class UserRepository {
  Future<UserEntity> signUp(String email, String password);
  Future<UserEntity> signIn(String email, String password);
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();
  Stream<UserEntity?> authStateChanges();
}