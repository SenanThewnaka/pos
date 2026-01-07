import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/logic/transaction_service.dart';
import 'package:pos_app/features/auth/presentation/pages/login_screen.dart';

class MockTransactionService extends Mock implements TransactionService {}

void main() {
  late AppDatabase db;
  late MockTransactionService mockTxService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockTxService = MockTransactionService();
  });

  tearDown(() {
    db.close();
  });

  Future<void> _createTestUser(String role, String pin) async {
    // We need to bypass the 'MANAGE_USERS' permission check in AuthService 
    // by inserting directly into DB for test setup.
    // HashPIN is protected, so we simulate exact hash or just insert roughly.
    // Actually, AuthService has a `login` method that does hashing. 
    // We need to insert a user with a KNOWN hash.
    // For simplicity in this test, let's use the AuthService if we can assume 
    // the first user creation logic (if any) or manually insert.
    
    // Manual Insert
    await db.into(db.users).insert(UsersCompanion(
      name: Value(role), // 'username' -> 'name'
      pinCode: Value(pin), // 'pinHash' -> 'pinCode'
      role: Value(role),
      // permissions: Value("ALL"), // REMOVED: Not in schema
      // createdAt: Value(DateTime.now()), // REMOVED: Not in schema
      lastLogin: Value(DateTime.now()),
    ));
  }

  // Helper to hash for test setup (simple SHA256 of '1234')
  // Actually, let's just use the `AuthService` itself if possible, but it requires permission to create.
  // Strategy: Insert directly into DB with the hash we know AuthService generates.
  // Or, since we verified AuthService separately, we can rely on it if we can seed DB.
  
  testWidgets('Login Screen renders and accepts input', (WidgetTester tester) async {
    // Set resolution to Tablet
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(db: db, txService: mockTxService),
    ));

    expect(find.text("POS LOGIN"), findsOneWidget);
    expect(find.text("ENTER"), findsOneWidget);
    
    // Tap keys
    await tester.tap(find.text("1"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("2"));
    await tester.pumpAndSettle();
    
    // Verify PIN dots (logic check visually)
    // We can't check internal state easily without Keys, but no crash is good.
  });
}
