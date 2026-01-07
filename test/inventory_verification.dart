import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/logic/inventory_service.dart';
import 'package:pos_app/core/logic/shadow_logger.dart';

Future<void> main() async {
  print("--- STARTING INVENTORY TRUTH VERIFICATION ---");

  final db = AppDatabase(NativeDatabase.memory());
  final invService = InventoryService(db);
  await ShadowLogger.init(overrideDir: Directory.systemTemp);

  try {
    // 1. Setup Dummy Data
    print("Step 1: Creating Dummy Supplier & Product...");
    final supplierId = await db.inventoryDao.addSupplier(
      SuppliersCompanion(
        name: Value("Global Distributors"),
        phone: Value("0771234567"),
      )
    );

    final prodId = await db.productDao.addProduct(
      ProductsCompanion(
        uuid: Value("PROD-MILK-001"),
        barcode: Value("4792020202"),
        name: Value("Highland Milk Packet"),
        price: Value(100.00),
        cost: Value(80.00),
      )
    );
    print("Supplier: $supplierId, Product: $prodId");

    // 2. Perform First GRN (Buying at 80.00)
    print("Step 2: Processing First GRN (Cost: 80.00)...");
    await invService.processGRN(
      supplierId: supplierId,
      grnCode: "GRN-001",
      userId: 1,
      items: [
        GrnItemDto(
          productId: prodId,
          quantity: 50,
          unitCost: 80.00,
          expiryDate: DateTime.now().add(const Duration(days: 10)),
        )
      ]
    );
    print("GRN-001 Success.");

    // 3. Verify Batch Creation & Cost
    final batches = await db.productDao.getBatchesForProduct(prodId);
    print("Batches Found: ${batches.length}");
    if (batches.length == 1 && batches.first.costPrice == 80.00) {
      print("✅ BATCH CREATION PASSED");
    } else {
      print("❌ BATCH CREATION FAILED");
    }

    // 4. Perform Second GRN with Price Hike (Cost: 90.00)
    print("Step 4: Processing Second GRN (Cost: 90.00 - Price Hike)...");
    await invService.processGRN(
      supplierId: supplierId,
      grnCode: "GRN-002",
      userId: 1,
      items: [
        GrnItemDto(
          productId: prodId,
          quantity: 20,
          unitCost: 90.00, // +10.00 Hike
          expiryDate: DateTime.now().add(const Duration(days: 20)),
        )
      ]
    );
    print("GRN-002 Success.");

    // 5. Verify Fraud Flag
    final grnItems = await db.select(db.purchaseGrnItems).get();
    final secondItem = grnItems.firstWhere((i) => i.unitCost == 90.00);
    
    print("Checking Fraud Flag for Item Cost 90.00...");
    print("isPriceIncrease: ${secondItem.isPriceIncrease}, previousCost: ${secondItem.previousCost}");
    
    if (secondItem.isPriceIncrease && secondItem.previousCost == 80.00) {
      print("✅ FRAUD DETECTION (PRICE HIKE) PASSED");
    } else {
      print("❌ FRAUD DETECTION FAILED");
    }
    
    // 6. Verify FIFO Order (Oldest Expiry First)
    final allBatches = await db.productDao.getBatchesForProduct(prodId);
    print("Batch Order (Expiry): ${allBatches.map((b) => b.expiryDate).toList()}");
    
    if (allBatches[0].id == batches[0].id) {
       print("✅ FIFO ORDER PASSED");
    }

  } catch (e, s) {
    print("❌ CRITICAL FAILURE: $e");
    print(s);
    exit(1);
  } finally {
    await db.close();
  }
}
