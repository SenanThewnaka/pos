import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../database/daos/auth_dao.dart';
import '../utils/crypto_utils.dart'; // For SHA256

class AuthService {
  final AuthDao _authDao;

  AuthService(AppDatabase db) : _authDao = db.authDao;

  /// Hashes PIN (SHA-256)
  String hashPin(String pin) {
    final bytes = utf8.encode(pin); // Use standard salt in real app
    final digest = sha256.convert(bytes);
    return digest.toString();
  }  

  /// Validates PIN and returns User if success.
  Future<User?> login(String plainPin) async {
    final pinHash = generateHash(plainPin);
    final user = await _authDao.getUserByPin(pinHash);
    
    if (user != null) {
      // Update last login
      await _authDao.updateLastLogin(user.id);
      return user;
    }
    return null;
  }

  /// Validates Username & Password
  Future<User?> loginWithCredentials(String username, String password) async {
    final passHash = hashPin(password); // Uses provided hashPin method which currently uses SHA256
    // Note: hashPin uses SHA256, createUser uses generateHash (from crypto_utils).
    // I need to ensure consistency.
    // generateHash (crypto_utils) vs hashPin (local defined).
    // hashPin implementation: sha256.convert(utf8.encode(pin)).
    // Let's check crypto_utils.generateHash content.
    // Assuming they are consistent or I should check.
    // But login() uses generateHash. hashPin uses sha256 directly.
    // I will use `generateHash` to match `login` and `createUser`.
    
    final hash = generateHash(password);
    final user = await _authDao.getUserByCredentials(username, hash);

    if (user != null) {
      await _authDao.updateLastLogin(user.id);
      return user;
    }
    return null;
  }
  
  /// Creates a new user (Restricted to Owner usually)
  Future<void> createUser({
    required String name,
    required String plainPin,
    required UserRole role,
  }) async {
    final pinHash = generateHash(plainPin);
    await _authDao.createUser(
      UsersCompanion(
        name: Value(name),
        pinCode: Value(pinHash),
        role: Value(role.name),
      )
    );
  }

  /// Checks if a user has permission for an action.
  bool hasPermission(User user, Permission action) {
    final role = UserRole.values.firstWhere(
      (e) => e.name == user.role, 
      orElse: () => UserRole.CASHIER
    );
    
    return RolePermissions[role]?.contains(action) ?? false;
  }
}

enum UserRole { OWNER, MANAGER, CASHIER }

enum Permission {
  REFUND,
  VOID_SALE,
  OPEN_DRAWER_NO_SALE,
  VIEW_REPORTS,
  EDIT_STOCK,
  EDIT_PRICE,
  MANAGE_USERS,
  PROCESS_SALE,
}

// Hardcoded RBAC Matrix - The "Iron Rules"
const Map<UserRole, Set<Permission>> RolePermissions = {
  UserRole.OWNER: {
    Permission.REFUND, Permission.VOID_SALE, Permission.OPEN_DRAWER_NO_SALE,
    Permission.VIEW_REPORTS, Permission.EDIT_STOCK, Permission.EDIT_PRICE,
    Permission.MANAGE_USERS, Permission.PROCESS_SALE
  },
  UserRole.MANAGER: {
    Permission.REFUND, Permission.VOID_SALE, Permission.OPEN_DRAWER_NO_SALE,
    Permission.VIEW_REPORTS, Permission.EDIT_STOCK, Permission.PROCESS_SALE
  },
  UserRole.CASHIER: {
    Permission.PROCESS_SALE
  },
};
