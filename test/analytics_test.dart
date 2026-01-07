import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/logic/analytics_service.dart';

void main() {
  late AppDatabase db;
  late AnalyticsService analyticsService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    analyticsService = AnalyticsService(db);
    
    // 1. Seed Products
    await db.into(db.products).insert(ProductsCompanion.insert(
      id: const drift.Value(1),
      uuid: 'p1',
      barcode: 'A',
      name: 'Product A',
      price: 100,
      cost: 60, // Profit = 40
    ));
    await db.into(db.products).insert(ProductsCompanion.insert(
      id: const drift.Value(2),
      uuid: 'p2',
      barcode: 'B',
      name: 'Product B',
      price: 200,
      cost: 150, // Profit = 50
    ));

    // 2. Seed Sales (Yesterday & Today)
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    // Sale 1: Yesterday (2x Prod A)
    final s1 = await db.into(db.sales).insert(SalesCompanion.insert(
      uuid: 's1',
      totalAmount: 200,
      paymentMethod: 'CASH',
      saleDate: drift.Value(yesterday),
      taxAmount: 0,
      discountAmount: 0,
      userId: 1,
    ));
    await db.into(db.saleItems).insert(SaleItemsCompanion.insert(
      saleId: s1,
      productId: 1,
      quantity: 2,
      unitPrice: 100,
      // totalPrice removed
      costPrice: 60,
    ));

    // Sale 2: Today (1x Prod A, 1x Prod B)
    final s2 = await db.into(db.sales).insert(SalesCompanion.insert(
      uuid: 's2',
      totalAmount: 300,
      paymentMethod: 'CARD',
      saleDate: drift.Value(today),
      taxAmount: 0,
      discountAmount: 0,
      userId: 1,
    ));
    await db.into(db.saleItems).insert(SaleItemsCompanion.insert(
      saleId: s2,
      productId: 1,
      quantity: 1,
      unitPrice: 100,
      // totalPrice removed
      costPrice: 60,
    ));
    await db.into(db.saleItems).insert(SaleItemsCompanion.insert(
      saleId: s2,
      productId: 2,
      quantity: 1,
      unitPrice: 200,
      // totalPrice removed
      costPrice: 150,
    ));
  });

  tearDown(() async {
    await db.close();
  });

  test('getDailySales returns correct revenue and profit', () async {
    final start = DateTime.now().subtract(const Duration(days: 2));
    final end = DateTime.now();
    
    final metrics = await analyticsService.getDailySales(start, end);
    
    // Should have 2 entries (Today and Yesterday)
    expect(metrics.length, 2);
    
    // Check Today: Revenue 300 (100+200), Cost 210 (60+150), Profit 90
    final todayMetric = metrics.first; 
    expect(todayMetric.totalSales, 300);
    expect(todayMetric.totalCost, 210);
    expect(todayMetric.grossProfit, 90);
    
    // Check Yesterday: Revenue 200, Cost 120 (2*60), Profit 80
    final yesterdayMetric = metrics.last;
    expect(yesterdayMetric.totalSales, 200);
    expect(yesterdayMetric.totalCost, 120);
    expect(yesterdayMetric.grossProfit, 80);
  });

  test('getTopSellingProducts returns grouped items', () async {
    final top = await analyticsService.getTopSellingProducts(5);
    
    // Product A: 2 (Yesterday) + 1 (Today) = 3
    // Product B: 1 (Today) = 1
    
    expect(top.length, 2);
    expect(top[0].productName, 'Product A');
    expect(top[0].quantitySold, 3);
    
    expect(top[1].productName, 'Product B');
    expect(top[1].quantitySold, 1);
  });
}
