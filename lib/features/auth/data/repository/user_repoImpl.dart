import 'package:pdf_summerizer/features/auth/data/datasource/local/user_local_datasource.dart';
import 'package:pdf_summerizer/features/auth/data/datasource/remote/user_remote_datasource.dart';
import 'package:pdf_summerizer/features/auth/domain/entity/user_entity.dart';
import 'package:pdf_summerizer/features/auth/domain/repo/user_repo.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<UserEntity> signUp(String email, String password) async {
    final model = await remoteDataSource.signUp(email, password);
    await localDataSource.cacheUser(model);
    return model.toEntity();
  }

  @override
  Future<UserEntity> signIn(String email, String password) async {
    final model = await remoteDataSource.signIn(email, password);
    await localDataSource.cacheUser(model);
    return model.toEntity();
  }

  @override
  Future<void> signOut() async {
    await remoteDataSource.signOut();
    await localDataSource.clearUser(); // clear cache on logout
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      // try remote first (valid session)
      final model = await remoteDataSource.getCurrentUser();
      if (model != null) {
        await localDataSource.cacheUser(model);
        return model.toEntity();
      }
      return null;
    } catch (_) {
      // fallback to cache if offline
      final cached = await localDataSource.getCachedUser();
      return cached?.toEntity();
    }
  }

  @override
  Stream<UserEntity?> authStateChanges() {
    return remoteDataSource.authStateChanges().map(
      (model) => model?.toEntity(),
    );
  }
}