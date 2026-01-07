import 'package:drift/drift.dart';
import '../database/app_database.dart';

class DailySalesMetric {
  final DateTime date;
  final double totalSales;
  final double totalCost;
  final double grossProfit;

  DailySalesMetric({
    required this.date,
    required this.totalSales,
    required this.totalCost,
    required this.grossProfit,
  });
}

class TopProductMetric {
  final String productName;
  final double quantitySold;
  final double totalRevenue;

  TopProductMetric({
    required this.productName,
    required this.quantitySold,
    required this.totalRevenue,
  });
}

class AnalyticsService {
  final AppDatabase db;

  AnalyticsService(this.db);

  /// Calculates Sales, Cost, and Profit for each day in the given range.
  Future<List<DailySalesMetric>> getDailySales(DateTime start, DateTime end) async {
    // 1. Fetch all COMPLETED sales in range
    final sales = await (db.select(db.sales)
      ..where((t) => 
         t.saleDate.isBiggerOrEqualValue(start) & 
         t.saleDate.isSmallerOrEqualValue(end) &
         t.status.equals('COMPLETED')
      )).get();

    final Map<String, List<Sale>> groupedByDate = {};
    
    // Group by Day (YYYY-MM-DD)
    for (final sale in sales) {
      final dateKey = sale.saleDate.toIso8601String().substring(0, 10);
      groupedByDate.putIfAbsent(dateKey, () => []).add(sale);
    }

    final List<DailySalesMetric> metrics = [];

    for (final dateKey in groupedByDate.keys) {
      final dailySales = groupedByDate[dateKey]!;
      double revenue = 0;
      double cost = 0;

      for (final sale in dailySales) {
        revenue += sale.totalAmount;
        
        // Calculate Cost (We need items for this)
        // Note: In a real high-volume app, we would use a JOIN or pre-calculated columns.
        // For local SQLite, running a query per day or per sale might be okay for small scale,
        // but fetching all items for these sales properly is better.
        // Let's optimize: Fetch all relevant SaleItems in one go? 
        // Or just query per sale for now (MVP).
        
        // Let's use the 'saleItems' table to get costs
        // Only if SaleItems table has costPrice snapshot (which we should have added in Phase 2/3)
        // Checking tables.dart: SaleItem has 'costPrice' column! Perfect.
        
        final items = await (db.select(db.saleItems)..where((t) => t.saleId.equals(sale.id))).get();
        cost += items.fold(0.0, (sum, i) => sum + (i.costPrice * i.quantity));
      }

      metrics.add(DailySalesMetric(
        date: DateTime.parse(dateKey),
        totalSales: revenue,
        totalCost: cost,
        grossProfit: revenue - cost,
      ));
    }
    
    // Sort by date desc
    metrics.sort((a, b) => b.date.compareTo(a.date));
    return metrics;
  }

  /// Returns top N selling products by Quantity
  Future<List<TopProductMetric>> getTopSellingProducts(int limit) async {
    // This requires aggregation. Drift supports basic custom queries.
    // SELECT productId, SUM(quantity) as calc_qty, SUM(quantity * unitPrice) as calc_rev 
    // FROM sale_items GROUP BY productId ORDER BY calc_qty DESC LIMIT N
    
    final revenueExpr = db.saleItems.quantity * db.saleItems.unitPrice;

    final query = db.select(db.saleItems).join([
      innerJoin(db.products, db.products.id.equalsExp(db.saleItems.productId))
    ]);
    
    query
      ..addColumns([
        db.products.name,
        db.saleItems.quantity.sum(),
        revenueExpr.sum(),
      ])
      ..groupBy([db.saleItems.productId])
      ..orderBy([OrderingTerm.desc(db.saleItems.quantity.sum())])
      ..limit(limit);

    final result = await query.get();

    return result.map((row) {
      return TopProductMetric(
        productName: row.read(db.products.name) ?? 'Unknown',
        quantitySold: row.read(db.saleItems.quantity.sum()) ?? 0,
        totalRevenue: row.read(revenueExpr.sum()) ?? 0,
      );
    }).toList();
  }
}
