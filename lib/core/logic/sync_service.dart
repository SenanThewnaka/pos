import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';

class SyncService {
  final AppDatabase db;
  final FirebaseService firebase;
  
  // Timer for background sync
  Timer? _syncTimer;
  
  // Cache storeId and Code
  String? _storeId;
  String? _shopCode;
  String? get storeId => _storeId;
  String? get shopCode => _shopCode;
  
  // Mutex
  bool _isSyncing = false;

  SyncService(this.db, this.firebase);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _storeId = prefs.getString('store_id');
    _shopCode = prefs.getString('shop_code');
    
    // Start background sync every 5 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
       await processOutbox();
       await pullProducts();
    });
    
    // Initial sync attempt
    processOutbox().then((_) => pullProducts());
  }

  /// Sets the active Store ID and Code and persists them.
  Future<void> setStoreContext(String id, String code) async {
    _storeId = id;
    _shopCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('store_id', id);
    await prefs.setString('shop_code', code);
  }
  
  // Deprecated: use setStoreContext
  Future<void> setStoreId(String id) async {
     await setStoreContext(id, "UNKNOWN");
  }

  /// Pushes un-synced sales to Firestore
  Future<void> processOutbox() async {
    if (_storeId == null || _isSyncing) return;
    _isSyncing = true;

    try {
      // 1. Get unsynced sales (limit 50 to avoid timeouts)
      final pendingSales = await (db.select(db.sales)
        ..where((t) => t.isSynced.equals(false))
        ..limit(50))
        .get();
        
      if (pendingSales.isEmpty) return;

      // 2. Push to Cloud
      // In a real app, we would batch these.
      for (final sale in pendingSales) {
        try {
          // We need items too.
          // SaleItems uses 'saleId' which is the Integer PK of Sales table.
          final items = await (db.select(db.saleItems)..where((t) => t.saleId.equals(sale.id))).get();
          final itemsJson = items.map((i) => {
            'productId': i.productId,
            'quantity': i.quantity,
            'unitPrice': i.unitPrice,
            'subtotal': i.quantity * i.unitPrice,
          }).toList();

          await firebase.saveSale(
            storeId: _storeId!,
            saleData: {
               'uuid': sale.uuid,
               'totalAmount': sale.totalAmount,
               'paymentMethod': sale.paymentMethod,
               'occurredAt': sale.saleDate.toIso8601String(),
               'items': itemsJson,
               'syncedAt': FieldValue.serverTimestamp(),
            }
          );

          // 3. Mark as Synced
          await (db.update(db.sales)..where((t) => t.uuid.equals(sale.uuid)))
              .write(SalesCompanion(isSynced: const Value(true)));
              
        } catch (e) {
          print("Failed to sync sale ${sale.uuid}: $e");
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
  
  // Pulls products from Cloud and updates local DB
  Future<int> pullProducts() async {
    if (_storeId == null) return 0;
    
    // 1. Get Last Sync Time
    final prefs = await SharedPreferences.getInstance();
    final lastSyncIso = prefs.getString('last_product_sync');
    final lastSync = lastSyncIso != null ? DateTime.parse(lastSyncIso) : null;
    
    try {
      // 2. Fetch Updates
      final start = DateTime.now();
      final products = await firebase.fetchProducts(_storeId!, lastSync: lastSync);
      
      if (products.isEmpty) return 0;
      
      // 3. Upsert Locally
      await db.batch((batch) {
        for (final p in products) {
           batch.insert(
             db.products,
             ProductsCompanion.insert(
               uuid: p['uuid'],
               name: p['name'],
               barcode: p['barcode'],
               price: (p['price'] as num).toDouble(),
               cost: (p['cost'] as num).toDouble(),
               isActive: Value(p['isActive'] ?? true),
               updatedAt: Value(DateTime.now()), // Local update time
             ),
             mode: InsertMode.insertOrReplace, // Update if exists
           );
        }
      });
      
      // 4. Update Last Sync Time
      await prefs.setString('last_product_sync', start.toIso8601String());
      
      return products.length;
      
    } catch (e) {
      print("Product Pull Failed: $e");
      return 0;
    }
  }


  // Pulls Users from Cloud and replaces local DB
  Future<void> syncUsers() async {
    if (_storeId == null) return;
    
    try {
      final users = await firebase.getStoreUsers(_storeId!);
      
      // Full Replace Strategy involved clearing and re-inserting
      // Ideally we would upsert using UUID, but for now this is safe for small user counts
      await db.delete(db.users).go();
      
      await db.batch((batch) {
        for (final u in users) {
          batch.insert(
            db.users,
            UsersCompanion.insert(
              name: u['name'],
              pinCode: u['pinCode'],
              role: Value(u['role']),
            )
          );
        }
      });
      print("Synced ${users.length} users.");
    } catch (e) {
      print("User Sync Failed: $e");
      rethrow;
    }
  }
}
