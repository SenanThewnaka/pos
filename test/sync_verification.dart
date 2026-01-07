import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/logic/transaction_service.dart';
import 'package:pos_app/core/logic/sync_service.dart';
import 'package:pos_app/core/logic/shadow_logger.dart';

Future<void> main() async {
  print("--- STARTING SYNC ENGINE VERIFICATION ---");

  final db = AppDatabase(NativeDatabase.memory());
  final txService = TransactionService(db);
  final syncService = SyncService(db);
  await ShadowLogger.init(overrideDir: Directory.systemTemp);

  try {
    // 1. Setup Data
    print("Step 1: Creating Product...");
    final prodId = await db.productDao.addProduct(
      ProductsCompanion(
        uuid: Value("PROD-SYNC"),
        barcode: Value("SYNC-123"),
        name: Value("Sync Test Item"),
        price: Value(100),
        cost: Value(50),
      )
    );
    await db.productDao.addStockBatch(
      StockBatchesCompanion(
          productId: Value(prodId),
          batchCode: Value("BATCH-1"),
          costPrice: Value(50),
          quantityOnHand: Value(100)
      )
    );

    // 2. Perform Offline Sale
    print("Step 2: Processing Offline Sale...");
    await txService.processSale(
      cashierId: 1,
      items: [CartItem(productId: prodId, productName: "Sync Item", quantity: 1, unitPrice: 100, tax: 0, discount: 0)],
      totalAmount: 100,
      taxAmount: 0,
      discountAmount: 0,
      paymentMethod: "CASH"
    );

    // 3. Verify Unsynced Status
    final pending = await (db.select(db.sales)..where((t) => t.isSynced.equals(false))).get();
    print("Pending Sales: ${pending.length}");
    if (pending.length == 1) {
      print("✅ SALE IS PENDING SYNC");
    } else {
      print("❌ FAILED: Sale not marked as unsynced");
    }

    // 4. Trigger Sync
    print("Step 4: Triggering Cloud Sync...");
    final uploadedCount = await syncService.pushSales();
    print("Uploaded Count: $uploadedCount");
    
    // 5. Verify Synced Status
    final remaining = await (db.select(db.sales)..where((t) => t.isSynced.equals(false))).get();
    if (remaining.isEmpty && uploadedCount == 1) {
      print("✅ SYNC SUCCESSFUL (Database Updated)");
    } else {
      print("❌ SYNC FAILED");
    }

  } catch (e, s) {
    print("❌ CRITICAL FAILURE: $e");
    print(s);
    exit(1);
  } finally {
    await db.close();
  }
}
