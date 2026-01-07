import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'dart:convert';

class InventoryItemInput {
  final int productId;
  final double quantity;
  final double unitCost;
  final double? sellingPrice;
  final double discount;
  final DateTime? expiryDate;

  InventoryItemInput({
    required this.productId,
    required this.quantity,
    required this.unitCost,
    this.sellingPrice,
    this.discount = 0.0,
    this.expiryDate,
  });
}

class InventoryService {
  final AppDatabase db;
  // Threshold for price hike warning (e.g. 10%)
  static const double priceHikeThreshold = 0.10;

  InventoryService(this.db);

  /// Processes a GRN (Goods Received Note)
  Future<void> processGrn({
    required int supplierId,
    required int userId,
    required List<InventoryItemInput> items,
    String? notes,
  }) async {
    return db.transaction(() async {
      final grnCode = 'GRN-${DateTime.now().millisecondsSinceEpoch}';
      
      // Calculate Total Cost
      final totalCost = items.fold(0.0, (sum, item) => sum + (item.unitCost * item.quantity) - item.discount);

      // 1. Create GRN Record
      final grnId = await db.into(db.purchaseGrns).insert(PurchaseGrnsCompanion.insert(
        code: grnCode,
        supplierId: supplierId,
        receivedByUserId: userId,
        totalCost: totalCost,
        receivedDate: Value(DateTime.now()),
        notes: Value(notes),
        status: const Value('COMPLETED'),
      ));

      for (final item in items) {
        // 2. Create GRN Item
        await db.into(db.purchaseGrnItems).insert(PurchaseGrnItemsCompanion.insert(
          grnId: grnId,
          productId: item.productId,
          quantity: item.quantity,
          unitCost: item.unitCost,
          discount: Value(item.discount),
          // previousCost: Value(...) // Can fetch if needed
        ));

        // 3. Add to Stock Batch
        final batchCode = '$grnCode-${item.productId}';
        await db.into(db.stockBatches).insert(StockBatchesCompanion.insert(
          productId: item.productId,
          batchCode: batchCode,
          costPrice: item.unitCost,
          quantityOnHand: item.quantity, // + freeQuantity if implemented
          receivedAt: Value(DateTime.now()),
          supplierId: Value(supplierId),
          expiryDate: Value(item.expiryDate),
        ));

        // 4. Update Product Cost & Price (Latest Cost/Price Strategy)
        var productUpdate = ProductsCompanion(
          cost: Value(item.unitCost),
          updatedAt: Value(DateTime.now()),
        );
        
        if (item.sellingPrice != null && item.sellingPrice! > 0) {
           productUpdate = productUpdate.copyWith(price: Value(item.sellingPrice!));
        }

        await (db.update(db.products)..where((p) => p.id.equals(item.productId)))
            .write(productUpdate);
      }
      
      // 5. Audit Log (Placeholder) - Assuming AuditLogs exists and we wan't to log it.
      // logic omitted for simplicity to pass compilation first.
    });
  }
}
