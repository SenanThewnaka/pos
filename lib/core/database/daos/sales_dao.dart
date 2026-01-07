import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'sales_dao.g.dart';

@DriftAccessor(tables: [Sales, SaleItems, AuditLogs])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(AppDatabase db) : super(db);

  Future<int> createSaleHeader(SalesCompanion entry) => into(sales).insert(entry);

  Future<void> addSaleItems(List<SaleItemsCompanion> items) async {
    await batch((batch) {
      batch.insertAll(saleItems, items);
    });
  }

  // --- Queries ---
  Future<List<Sale>> getRecentSales({int limit = 50}) {
    return (select(sales)
      ..orderBy([(t) => OrderingTerm(expression: t.saleDate, mode: OrderingMode.desc)])
      ..limit(limit)
    ).get();
  }

  Future<List<SaleItem>> getItemsForSale(int saleId) {
    return (select(saleItems)..where((t) => t.saleId.equals(saleId))).get();
  }

  Future<void> logAudit(AuditLogsCompanion entry) => into(auditLogs).insert(entry);
  
  // Fetch latest audit hash to chain the next one
  Future<String?> getLatestAuditHash() async {
    final query = select(auditLogs)
      ..orderBy([(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)])
      ..limit(1);
    final log = await query.getSingleOrNull();
    return log?.hash;
  }
}
