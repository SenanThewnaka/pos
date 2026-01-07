import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pos_app/core/utils/crypto_utils.dart';
import '../../firebase_options.dart'; 

class FirebaseService {
  static bool _isInitialized = false;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _isInitialized = true;
      print("FIREBASE INITIALIZED");
    } catch (e) {
      print("Firebase Init Failed: $e");
    }
  }

  static final _db = FirebaseFirestore.instance;

  // --- Store Management ---
  
  /// Creates a new Store document. Returns the storeId (auto-generated ID).
  Future<String> createStore({
    required String name,
    required String ownerEmail,
    required String shopCode, // Unique 6-char code
    required String password,
  }) async {
    if (!_isInitialized) await init();
    
    final storeRef = _db.collection('stores').doc();
    
    // Hash password before storage
    final hashedPassword = generateHash(password);
    
    await storeRef.set({
      'name': name,
      'ownerEmail': ownerEmail,
      'shopCode': shopCode,
      'password': hashedPassword,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return storeRef.id;
  }
  
  /// Checks if a Shop Code exists and returns Store ID + Name
  Future<Map<String, dynamic>?> verifyShopCode(String code) async {
    if (!_isInitialized) await init();

    final query = await _db.collection('stores')
      .where('shopCode', isEqualTo: code)
      .limit(1)
      .get();
      
    if (query.docs.isEmpty) return null;
    
    final doc = query.docs.first;
    return {
      'id': doc.id,
      'name': doc.data()['name'],
    };
  }
  
  /// Validates if an email is already registered as an Owner
  Future<bool> isEmailRegistered(String email) async {
    if (!_isInitialized) await init();
     final query = await _db.collection('stores')
      .where('ownerEmail', isEqualTo: email)
      .limit(1)
      .get();
    return query.docs.isNotEmpty;
  }
  
  Future<Map<String, dynamic>?> getStoreByEmail(String email) async {
    if (!_isInitialized) await init();
     final query = await _db.collection('stores')
      .where('ownerEmail', isEqualTo: email)
      .limit(1)
      .get();
    
    if (query.docs.isEmpty) return null;
    
    final doc = query.docs.first;
    var data = doc.data();
    data['id'] = doc.id;
    return data;
  }
  
  Future<Map<String, dynamic>?> verifyOwnerCredentials(String email, String password) async {
    if (!_isInitialized) await init();

    // Hash input to match stored hash
    final hashedPassword = generateHash(password);

    final query = await _db.collection('stores')
      .where('ownerEmail', isEqualTo: email)
      .where('password', isEqualTo: hashedPassword)
      .limit(1)
      .get();
      
    if (query.docs.isEmpty) return null;
    
    final doc = query.docs.first;
    var data = doc.data();
    data['id'] = doc.id;
    return data;
  }
  
  Future<void> deleteStore(String email) async {
    if (!_isInitialized) await init();
    
    final query = await _db.collection('stores')
      .where('ownerEmail', isEqualTo: email)
      .limit(1)
      .get();
      
    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }
  
  // --- User Management ---
  
  Future<void> createCloudUser({
    required String storeId,
    required String name,
    required String pin,
    required String role,
  }) async {
    // Expecting caller to hash PIN/Password
    
    await _db.collection('stores').doc(storeId).collection('users').add({
      'name': name,
      'pinCode': pin,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  
  Future<List<Map<String, dynamic>>> getStoreUsers(String storeId) async {
    final snapshot = await _db.collection('stores').doc(storeId).collection('users').get();
    return snapshot.docs.map((d) => d.data()).toList();
  }

  // --- Sales Sync ---

  Future<void> saveSale({required String storeId, required Map<String, dynamic> saleData}) async {
    final saleId = saleData['uuid'];
    await _db.collection('stores').doc(storeId).collection('sales').doc(saleId).set(saleData);
  }
  
  // --- Product Management ---
  
  Stream<QuerySnapshot> streamProducts(String storeId) {
    return _db.collection('stores').doc(storeId).collection('products').snapshots();
  }
  
  Future<List<Map<String, dynamic>>> fetchProducts(String storeId, {DateTime? lastSync}) async {
    Query query = _db.collection('stores').doc(storeId).collection('products');
    if (lastSync != null) {
      query = query.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSync));
    }
    final snapshot = await query.get();
    return snapshot.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }
}
