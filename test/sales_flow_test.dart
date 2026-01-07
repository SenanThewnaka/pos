import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/daos/product_dao.dart';
import 'package:pos_app/core/logic/transaction_service.dart';
import 'package:pos_app/features/sales/presentation/pages/sales_screen.dart';

class MockTransactionService extends Mock implements TransactionService {}
class MockProductDao extends Mock implements ProductDao {}

void main() {
  late MockTransactionService mockTxService;
  late MockProductDao mockProductDao;

  setUp(() {
    mockTxService = MockTransactionService();
    mockProductDao = MockProductDao();
  });

  // Helper to create the test widget
  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: SalesScreen(
        transactionService: mockTxService,
        productDao: mockProductDao,
        currentUserId: 1,
      ),
    );
  }
  
  testWidgets('Sales Screen renders correctly', (WidgetTester tester) async {
    // Set resolution to Landscape Tablet
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    
    await tester.pumpWidget(createWidgetUnderTest());
    
    // Verify Header
    expect(find.text('New Sale'), findsOneWidget);
    
    // Verify Empty Cart
    expect(find.text('Ready for Sale'), findsOneWidget); // From CartList empty state
    
    // Verify Keypad
    expect(find.text('PAY CASH'), findsOneWidget);
    expect(find.text('ENTER'), findsOneWidget);
  });
}
