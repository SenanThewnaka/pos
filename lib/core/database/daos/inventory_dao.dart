import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'inventory_dao.g.dart';

@DriftAccessor(tables: [Products, StockBatches, Suppliers, PurchaseGrns, PurchaseGrnItems])
class InventoryDao extends DatabaseAccessor<AppDatabase> with _$InventoryDaoMixin {
  InventoryDao(AppDatabase db) : super(db);

  // --- Supplier ---
  Future<int> addSupplier(SuppliersCompanion entry) => into(suppliers).insert(entry);
  
  Future<List<Supplier>> getAllSuppliers() => select(suppliers).get();

  // --- Purchase / GRN ---
  
  // Create Header
  Future<int> createGrnHeader(PurchaseGrnsCompanion entry) => into(purchaseGrns).insert(entry);
  
  // Add Items
  Future<void> addGrnItems(List<PurchaseGrnItemsCompanion> items) => 
      batch((batch) => batch.insertAll(purchaseGrnItems, items));
      
  // Get Last Buying Price for a Product (from this specific supplier or any?)
  // Usually fraud check compares against *last global purchase cost* or *last supplier specific cost*.
  // Let's get the absolute last purchase item for this product to compare.
  Future<PurchaseGrnItem?> getLastPurchaseItem(int productId) {
    return (select(purchaseGrnItems)
      ..where((tbl) => tbl.productId.equals(productId))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc)])
      ..limit(1))
      .getSingleOrNull();
  }
}
