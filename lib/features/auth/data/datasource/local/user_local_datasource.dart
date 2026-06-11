import 'package:pdf_summerizer/features/auth/data/model/user_model.dart';
import 'dart:convert';
import 'package:hive/hive.dart';

abstract class UserLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearUser();
}


class UserLocalDataSourceImpl implements UserLocalDataSource {
  static const _boxName = 'user_box';
  static const _userKey = 'cached_user';

  @override
  Future<void> cacheUser(UserModel user) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_userKey, jsonEncode(user.toJson()));
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get(_userKey) as String?;
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> clearUser() async {
    final box = await Hive.openBox(_boxName);
    await box.delete(_userKey);
  }
}