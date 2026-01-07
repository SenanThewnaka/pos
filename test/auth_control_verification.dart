import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/logic/auth_service.dart';
import 'package:pos_app/core/logic/owner_control_service.dart';
import 'package:pos_app/core/logic/inventory_service.dart'; // To create Price Hike
import 'package:pos_app/core/logic/shadow_logger.dart';

Future<void> main() async {
  print("--- STARTING SECURITY & CONTROL VERIFICATION ---");

  final db = AppDatabase(NativeDatabase.memory());
  final authService = AuthService(db);
  final controlService = OwnerControlService(db);
  final invService = InventoryService(db);
  await ShadowLogger.init(overrideDir: Directory.systemTemp);

  try {
    // 1. Setup Logic: Create Owner
    print("Step 1: Creating Owner User...");
    await authService.createUser(
      name: "Big Boss",
      plainPin: "1234",
      role: UserRole.OWNER,
    );

    // 2. Login Logic
    print("Step 2: Attempting Login with Correct PIN...");
    final user = await authService.login("1234");
    
    if (user != null && user.role == "OWNER") {
      print("✅ LOGIN SUCCESS: Welcome ${user.name} (${user.role})");
    } else {
      print("❌ LOGIN FAILED");
    }
    
    print("Step 2b: Attempting Login with Wrong PIN...");
    final badUser = await authService.login("0000");
    if (badUser == null) {
      print("✅ BAD LOGIN BLOCKED");
    } else {
      print("❌ BAD LOGIN ALLOWED");
    }

    // 3. Permission Logic
    print("Step 3: Checking Permissions...");
    if (user != null) {
      final canRefund = authService.hasPermission(user, Permission.REFUND);
      if (canRefund) {
        print("✅ OWNER CAN REFUND");
      } else {
        print("❌ OWNER PERMISSION ERROR");
      }
    }
    
    // 4. Alert Logic: Create Dead Stock
    print("Step 4: Simulating Dead Stock...");
    final prodId = await db.productDao.addProduct(
      ProductsCompanion(
        uuid: Value("PROD-OLD"),
        barcode: Value("OLD-123"),
        name: Value("Old Bread"),
        price: Value(100),
        cost: Value(80),
      )
    );
    
    // Add batch received 100 days ago
    await db.productDao.addStockBatch(
      StockBatchesCompanion(
        productId: Value(prodId),
        batchCode: Value("OLD-BATCH"),
        costPrice: Value(80),
        quantityOnHand: Value(10),
        receivedAt: Value(DateTime.now().subtract(const Duration(days: 100))),
      )
    );
    
    final alerts = await controlService.generateAlerts();
    print("Alerts Generated: ${alerts.length}");
    
    bool foundDeadStock = false;
    for (final a in alerts) {
      print("ALERT: [${a.type}] ${a.message}");
      if (a.type == AlertType.DEAD_STOCK) foundDeadStock = true;
    }
    
    if (foundDeadStock) {
      print("✅ DEAD STOCK ALERT VERIFIED");
    } else {
      print("❌ DEAD STOCK ALERT FAILED");
    }

  } catch (e, s) {
    print("❌ CRITICAL FAILURE: $e");
    print(s);
    exit(1);
  } finally {
    await db.close();
  }
}
