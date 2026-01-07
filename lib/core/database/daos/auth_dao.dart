import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'auth_dao.g.dart';

@DriftAccessor(tables: [Users])
class AuthDao extends DatabaseAccessor<AppDatabase> with _$AuthDaoMixin {
  AuthDao(AppDatabase db) : super(db);

  Future<User?> getUserByPin(String pinHash) {
    return (select(users)
      ..where((t) => t.pinCode.equals(pinHash) & t.isActive.equals(true)))
      .getSingleOrNull();
  }

  Future<User?> getUserByCredentials(String name, String pinHash) {
    return (select(users)
      ..where((t) => t.name.equals(name) & t.pinCode.equals(pinHash) & t.isActive.equals(true)))
      .getSingleOrNull();
  }

  Future<List<User>> getAllUsers() => select(users).get();

  Future<int> createUser(UsersCompanion entry) => into(users).insert(entry);
  
  Future<void> updateLastLogin(int userId) {
    return (update(users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(lastLogin: Value(DateTime.now()))
    );
  }
}
