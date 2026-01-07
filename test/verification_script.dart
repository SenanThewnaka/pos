import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/logic/transaction_service.dart';
import 'package:pos_app/core/logic/shadow_logger.dart';

import 'dart:io';

Future<void> main() async {
  print("--- STARTING TRANSACTION VERIFICATION ---");

  final db = AppDatabase(NativeDatabase.memory());
  final txService = TransactionService(db);
  // Use system temp for testing to avoid path_provider platform channel
  await ShadowLogger.init(overrideDir: Directory.systemTemp);

  try {
    // 1. Setup Dummy Data
    print("Step 1: Creating Dummy Product & Batch...");
    final prodId = await db.productDao.addProduct(
      ProductsCompanion(
        uuid: Value("PROD-001"),
        barcode: Value("888123456"),
        name: Value("Munchee Super Cream Cracker"),
        price: Value(150.00),
        cost: Value(120.00),
      )
    );
    
    final batchId = await db.productDao.addStockBatch(
      StockBatchesCompanion(
        productId: Value(prodId),
        batchCode: Value("BATCH-001"),
        costPrice: Value(120.00),
        quantityOnHand: Value(100.0), // Initial Stock
        expiryDate: Value(DateTime.now().add(const Duration(days: 30))),
      )
    );
    
    print("Product Created: ID $prodId, Batch: $batchId (Qty: 100)");

    // 2. Perform Sale
    print("Step 2: Processing Sale (Qty: 5)...");
    final cartItem = CartItem(
      productId: prodId,
      productName: "Munchee Super Cream Cracker",
      quantity: 5.0,
      unitPrice: 150.00,
      tax: 0.0,
      discount: 0.0,
    );

    await txService.processSale(
      cashierId: 1, // Admin
      items: [cartItem],
      totalAmount: 750.00,
      taxAmount: 0.0,
      discountAmount: 0.0,
      paymentMethod: "CASH",
    );

    print("Sale Transaction Success!");

    // 3. Verify Stock
    print("Step 3: Verifying Stock Deduction...");
    final batches = await db.productDao.getBatchesForProduct(prodId);
    final currentQty = batches.first.quantityOnHand;
    print("Current Stock Qty: $currentQty (Expected: 95.0)");
    
    if (currentQty == 95.0) {
      print("✅ STOCK VERIFICATION PASSED");
    } else {
      print("❌ STOCK VERIFICATION FAILED");
    }
    
    // 4. Verify Audit Log
    print("Step 4: Checking Audit Hash...");
    final hash = await db.salesDao.getLatestAuditHash();
    print("Latest Audit Hash: $hash");
    
    if (hash != null && hash.isNotEmpty) {
      print("✅ AUDIT LOG PASSED");
    } else {
      print("❌ AUDIT LOG FAILED");
    }

  } catch (e, s) {
    print("❌ CRITICAL FAILURE: $e");
    print(s);
  } finally {
    await db.close();
  }
}
