import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/logic/firebase_service.dart';
import 'package:pos_app/core/logic/sync_service.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Fake FirebaseService
class FakeFirebaseService extends Fake implements FirebaseService {
  final List<Map<String, dynamic>> savedSales = [];

  @override
  Future<void> saveSale({required String storeId, required Map<String, dynamic> saleData}) async {
    savedSales.add(saleData);
  }
  
  // Stubs for other methods to satisfy interface
  @override
  Future<String> createStore({required String name, required String ownerEmail, required String shopCode}) async => "mock-store-id";
  
  @override
  Future<Map<String, dynamic>?> verifyShopCode(String code) async => {'id': 'mock-store-id', 'name': 'Mock Store'};

  @override
  Future<bool> isEmailRegistered(String email) async => false;
  
  @override
  Future<void> createCloudUser({required String storeId, required String name, required String pin, required String role}) async {}
  
  @override
  Future<List<Map<String, dynamic>>> getStoreUsers(String storeId) async => [];
}

void main() {
  late AppDatabase db;
  late FakeFirebaseService fakeFirebase;
  late SyncService syncService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'store_id': 'test_store_123'});
    db = AppDatabase(NativeDatabase.memory());
    fakeFirebase = FakeFirebaseService();
    syncService = SyncService(db, fakeFirebase);
  });

  tearDown(() async {
    await db.close();
  });

  test('SyncService pushes offline sales to FirebaseService', () async {
    // 1. Create offline sale
    final saleUuid = 'sale-abc-123';
    // Insert and get ID
    final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
      uuid: saleUuid,
      totalAmount: 100.0,
      taxAmount: 0.0,
      discountAmount: 0.0,
      userId: 1, // Default user
      paymentMethod: 'CASH',
      saleDate: Value(DateTime.now()), // Wrapped in Value
      isSynced: const Value(false)
    ));
    
    await db.into(db.saleItems).insert(SaleItemsCompanion.insert(
      saleId: saleId,
      productId: 1,
      quantity: 1,
      unitPrice: 100,
      costPrice: 80, // Mandatory
    ));

    // 2. Trigger Sync
    // init() triggers processOutbox internally.
    await syncService.init(); 
    
    // Wait for async sync to complete
    await Future.delayed(const Duration(milliseconds: 200)); 
    
    // 3. Verify Firebase called
    expect(fakeFirebase.savedSales.length, 1);
    expect(fakeFirebase.savedSales.first['uuid'], saleUuid);
    expect(fakeFirebase.savedSales.first['totalAmount'], 100.0);
    expect(fakeFirebase.savedSales.first['items'][0]['subtotal'], 100.0);
    
    // 4. Verify Local DB Updated
    final sale = await (db.select(db.sales)..where((t) => t.uuid.equals(saleUuid))).getSingle();
    expect(sale.isSynced, true);
  });
}
