import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/logic/inventory_service.dart';
import 'package:pos_app/features/inventory/presentation/pages/grn_entry_screen.dart';

import 'package:pos_app/core/logic/label_printing_service.dart';

void main() {
  late AppDatabase db;
  late InventoryService inventoryService;
  late LabelPrintingService labelService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    inventoryService = InventoryService(db);
    labelService = LabelPrintingService();
    
    // Seed Data
    await db.into(db.suppliers).insert(SuppliersCompanion.insert(name: 'Test Supplier'));
    await db.into(db.products).insert(ProductsCompanion.insert(
      uuid: 'p1',
      barcode: '111', 
      name: 'Test Product', 
      price: 100, 
      cost: 80
    ));
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('GRN Entry Flow: Select Supplier, Add Item, Finalize', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GrnEntryScreen(
        db: db, 
        inventoryService: inventoryService,
        labelService: labelService
      ),
    ));
    await tester.pumpAndSettle();

    // 1. Select Supplier
    // Dropdown testing can be tricky, let's verify it exists
    expect(find.text("Select Supplier"), findsOneWidget);
    // Tap and select
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Test Supplier").last);
    await tester.pumpAndSettle();

    // 2. Scan Item (Enter 111)
    await tester.enterText(find.widgetWithText(TextField, "Scan Barcode / SKU"), "111");
    // Simulate lookup trigger? The UI triggers lookup on 'Add' but uses textfield.
    // The code only triggers lookup in _addItem which is called by button.
    // But _addItem reads controller.
    
    await tester.enterText(find.widgetWithText(TextField, "Cost Price"), "85");
    await tester.enterText(find.widgetWithText(TextField, "Qty"), "10");
    
    await tester.tap(find.text("ADD"));
    await tester.pumpAndSettle(); // Async lookup

    // 3. Verify Item in List
    expect(find.text("Test Product"), findsOneWidget);
    expect(find.text("Cost: 85.0 | Qty: 10.0"), findsOneWidget);

    // 4. Finalize
    await tester.tap(find.text("FINALIZE GRN"));
    await tester.pumpAndSettle();
    
    // 5. Check Database
    final grns = await db.select(db.purchaseGrns).get();
    expect(grns.length, 1);
    expect(grns.first.totalCost, 850.0);
    
    // Check Stock Batch
    final batches = await db.select(db.stockBatches).get();
    expect(batches.length, 1);
    expect(batches.first.quantityOnHand, 10.0);
  });
}
