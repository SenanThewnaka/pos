import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/daos/product_dao.dart';
import '../database/daos/sales_dao.dart';
import '../../core/utils/crypto_utils.dart';
import 'shadow_logger.dart';
import 'dart:convert';

class TransactionService {
  final AppDatabase _db;
  final ProductDao _productDao;
  final SalesDao _salesDao;

  TransactionService(this._db)
      : _productDao = _db.productDao,
        _salesDao = _db.salesDao;

  /// Executes a complete sale transaction atomically.
  /// 1. Deducts Stock (FIFO)
  /// 2. Creates Sale Header
  /// 3. Creates Sale Items
  /// 4. Logs Audit
   Future<void> processSale({
    required int cashierId,
    required List<CartItem> items,
    required double totalAmount,
    required double taxAmount,
    required double discountAmount,
    required String paymentMethod,
  }) async {
    final saleUuid = await _db.transaction(() async {
      final uuid = generateUuid(); // Implement in utils

      // 1. Create Sale Header
      final saleId = await _salesDao.createSaleHeader(
        SalesCompanion(
          uuid: Value(uuid),
          userId: Value(cashierId),
          totalAmount: Value(totalAmount),
          taxAmount: Value(taxAmount),
          discountAmount: Value(discountAmount),
          paymentMethod: Value(paymentMethod),
        ),
      );

      // 2. Process Items & Deduct Stock
      for (final item in items) {
        double remainingQtyToDeduct = item.quantity;
        
        // Get batches (FIFO)
        final batches = await _productDao.getBatchesForProduct(item.productId);
        
        for (final batch in batches) {
          if (remainingQtyToDeduct <= 0) break;
          
         double deduct = 0;
         if (batch.quantityOnHand >= remainingQtyToDeduct) {
           deduct = remainingQtyToDeduct;
         } else {
           deduct = batch.quantityOnHand;
         }
         
         // Update Batch
         await _productDao.updateStockBatchQty(batch.id, batch.quantityOnHand - deduct);
         
         // Add Sale Item linked to this batch
         await _salesDao.addSaleItems([
           SaleItemsCompanion(
             saleId: Value(saleId),
             productId: Value(item.productId),
             stockBatchId: Value(batch.id),
             quantity: Value(deduct),
             unitPrice: Value(item.unitPrice),
             costPrice: Value(batch.costPrice), // Snapshot cost!
             tax: Value(item.tax),
             discount: Value(item.discount),
           )
         ]);
         
         remainingQtyToDeduct -= deduct;
        }
        
        if (remainingQtyToDeduct > 0) {
          throw Exception("Insufficient stock for product ${item.productName}");
        }
      }
      
      // 3. Audit Log
      final prevHash = await _salesDao.getLatestAuditHash() ?? "";
      final logData = "SALE:$uuid|TOTAL:$totalAmount|USER:$cashierId";
      final newHash = generateHash(prevHash + logData);
      
      await _salesDao.logAudit(
        AuditLogsCompanion(
          userId: Value(cashierId),
          action: Value("SALE_COMPLETED"),
          entityTable: Value("sales"),
          entityId: Value(uuid),
          detailsJson: Value(jsonEncode({'items': items.length})),
          hash: Value(newHash),
        )
      );
      
      return uuid;
    });
    
    // 4. Shadow Log (Outside DB Transaction, but immediate)
    try {
       await ShadowLogger.performShadowWrite("SALE_COMPLETED|$saleUuid|TOTAL:$totalAmount|USER:$cashierId");
    } catch (e) {
      print("Shadow Log Failed: $e");
    }
  }
}

// Temporary DTO until we have full Cart Logic
class CartItem {
  final int productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double tax;
  final double discount;

  CartItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.tax,
    required this.discount,
  });
}

// Utils placeholders
String generateUuid() => DateTime.now().millisecondsSinceEpoch.toString(); // Replace with simple UUID later
