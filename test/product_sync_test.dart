import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/logic/firebase_service.dart';
import 'package:pos_app/core/logic/sync_service.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Fake FirebaseService
class FakeFirebaseService extends Fake implements FirebaseService {
  List<Map<String, dynamic>> productsToReturn = [];

  @override
  Future<List<Map<String, dynamic>>> fetchProducts(String storeId, {DateTime? lastSync}) async {
    return productsToReturn;
  }
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

  test('SyncService pulls products and upserts local DB', () async {
    // 1. Stub Firebase Response
    fakeFirebase.productsToReturn = [{
      'uuid': 'prod-001',
      'name': 'Cloud Product',
      'barcode': '123456',
      'price': 150.0,
      'cost': 100.0,
      'isActive': true,
      'updatedAt': DateTime.now().toIso8601String()
    }];

    // 2. Run Pull
    await syncService.init(); // Sets storeId
    final count = await syncService.pullProducts();
    
    // 3. Verify
    expect(count, 1);
    
    final product = await (db.select(db.products)..where((p) => p.uuid.equals('prod-001'))).getSingle();
    expect(product.name, 'Cloud Product');
    expect(product.price, 150.0);
  });
}
