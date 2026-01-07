import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/features/dashboard/presentation/pages/analytics_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    
    // Seed some data for the chart to render
    final today = DateTime.now();
    await db.into(db.products).insert(ProductsCompanion.insert(
      id: const drift.Value(1),
      uuid: 'p1',
      barcode: 'A',
      name: 'Product A',
      price: 100, cost: 50
    ));
    
    final s1 = await db.into(db.sales).insert(SalesCompanion.insert(
      uuid: 's1',
      totalAmount: 100,
      paymentMethod: 'CASH',
      saleDate: drift.Value(today),
      taxAmount: 0, discountAmount: 0, userId: 1
    ));
    
    await db.into(db.saleItems).insert(SaleItemsCompanion.insert(
      saleId: s1,
      productId: 1,
      quantity: 1,
      unitPrice: 100,
      costPrice: 50
    ));
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('Analytics Screen loads and displays data', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AnalyticsScreen(db: db),
    ));
    
    // Expect Loading first
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Wait for Future
    await tester.pumpAndSettle();
    
    // Expect Title
    expect(find.text("Business Intelligence"), findsOneWidget);
    
    // Expect Summary Cards
    // Sales: 100, Profit: 50
    expect(find.text("Today's Sales"), findsOneWidget);
    expect(find.textContaining("Rs. 100.00"), findsOneWidget);
    expect(find.textContaining("Rs. 50.00"), findsOneWidget);
    
    // Expect Chart Title
    expect(find.text("Performance (Last 7 Days)"), findsOneWidget);
    
    // Expect Top Products Title
    expect(find.text("Top Selling Products (All Time)"), findsOneWidget);
    expect(find.text("Product A"), findsOneWidget);
  });
}
