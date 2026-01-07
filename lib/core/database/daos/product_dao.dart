import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [Products, StockBatches])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(AppDatabase db) : super(db);

  // --- Product Queries ---
  Future<Product?> getProductByBarcode(String barcode) =>
      (select(products)..where((tbl) => tbl.barcode.equals(barcode))).getSingleOrNull();

  Future<List<Product>> getAllProducts() => select(products).get();

  Future<bool> updateProduct(Product product) => update(products).replace(product);

  Future<List<Product>> searchProducts(String query) {
    return (select(products)
          ..where((tbl) => tbl.name.contains(query) | tbl.barcode.contains(query)))
        .get();
  }
  
  // --- Stock Queries ---
  
  // Get all batches for a product, ordered by Expiry (FIFO)
  Future<List<StockBatch>> getBatchesForProduct(int productId) {
    return (select(stockBatches)
      ..where((tbl) => tbl.productId.equals(productId) & tbl.quantityOnHand.isBiggerThanValue(0))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.expiryDate, mode: OrderingMode.asc)]))
      .get();
  }
  
  // Get ALL batches (for Inventory Screen)
  Future<List<StockBatch>> getAllBatches() {
    return select(stockBatches).get();
  }

  Future<int> addProduct(ProductsCompanion entry) => into(products).insert(entry);
  
  Future<int> addStockBatch(StockBatchesCompanion entry) => into(stockBatches).insert(entry);
  
  Future<void> updateStockBatchQty(int batchId, double newQty) {
    return (update(stockBatches)..where((tbl) => tbl.id.equals(batchId)))
        .write(StockBatchesCompanion(quantityOnHand: Value(newQty)));
  }

  // --- Dashboard Metrics ---
  Stream<StockHealthMetrics> getHealthMetrics() {
    return (select(stockBatches).join([
      innerJoin(products, products.id.equalsExp(stockBatches.productId))
    ])).watch().map((rows) {
       double totalCost = 0;
       double totalRetail = 0;
       
       for (final row in rows) {
          final batch = row.readTable(stockBatches);
          final product = row.readTable(products);
          
          if (batch.quantityOnHand > 0) {
            totalCost += batch.quantityOnHand * batch.costPrice;
            totalRetail += batch.quantityOnHand * product.price;
          }
       }
       return StockHealthMetrics(totalCostValue: totalCost, totalRetailValue: totalRetail);
    });
  }
}

class StockHealthMetrics {
  final double totalCostValue;
  final double totalRetailValue;
  StockHealthMetrics({required this.totalCostValue, required this.totalRetailValue});
}
