import 'package:drift/drift.dart';

@DataClassName('Product')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get barcode => text().unique()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get categoryId => integer().nullable()();
  RealColumn get price => real()(); // Selling Price
  RealColumn get cost => real()(); // Approx Cost (for quick calc)
  BoolColumn get isStockTracked => boolean().withDefault(const Constant(true))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get taxGroupId => integer().nullable()();
  
  // Sync Status
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
}

@DataClassName('StockBatch')
class StockBatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get batchCode => text()(); // e.g GRN-2024-001
  RealColumn get costPrice => real()(); // Actual cost for this batch
  RealColumn get quantityOnHand => real()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  DateTimeColumn get receivedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get supplierId => integer().nullable()();
}

@DataClassName('Sale')
class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  DateTimeColumn get saleDate => dateTime().withDefault(currentDateAndTime)();
  RealColumn get totalAmount => real()();
  RealColumn get taxAmount => real()();
  RealColumn get discountAmount => real()();
  TextColumn get paymentMethod => text()(); // CASH, CARD, SPLIT
  IntColumn get userId => integer()(); // Cashier ID
  
  // States: DRAFT, COMPLETED, VOIDED
  TextColumn get status => text().withDefault(const Constant('COMPLETED'))();
  
  // Sync
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

@DataClassName('SaleItem')
class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get stockBatchId => integer().nullable().references(StockBatches, #id)(); // Which batch was sold
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()(); 
  RealColumn get costPrice => real()(); // Snapshotted cost at moment of sale
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get tax => real().withDefault(const Constant(0.0))();
}

@DataClassName('Supplier')
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

@DataClassName('PurchaseGrn')
class PurchaseGrns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()(); // GRN-2024-001
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  DateTimeColumn get receivedDate => dateTime().withDefault(currentDateAndTime)();
  RealColumn get totalCost => real()();
  TextColumn get status => text().withDefault(const Constant('COMPLETED'))(); // PENDING, COMPLETED, CANCELLED
  IntColumn get receivedByUserId => integer()();
  TextColumn get notes => text().nullable()();
}

@DataClassName('PurchaseGrnItem')
class PurchaseGrnItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get grnId => integer().references(PurchaseGrns, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get quantity => real()();
  RealColumn get freeQuantity => real().withDefault(const Constant(0.0))(); // Free issues
  RealColumn get unitCost => real()(); // Buying Price per unit
  RealColumn get discount => real().withDefault(const Constant(0.0))(); // Line discount
  
  // Fraud Detection / Audit Reference
  RealColumn get previousCost => real().nullable()(); // Snapshot of last buying price
  BoolColumn get isPriceIncrease => boolean().withDefault(const Constant(false))();
}

@DataClassName('User')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get pinCode => text()(); // Hashed PIN
  TextColumn get role => text().withDefault(const Constant('CASHIER'))(); // OWNER, MANAGER, CASHIER
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastLogin => dateTime().nullable()();
}

@DataClassName('AuditLog')
class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  IntColumn get userId => integer().nullable()();
  TextColumn get action => text()(); // e.g. VOID_SALE, OPEN_DRAWER
  TextColumn get entityTable => text().nullable()();
  TextColumn get entityId => text().nullable()();
  TextColumn get detailsJson => text().nullable()(); // Changed values
  TextColumn get hash => text()(); // SHA-256 of previous hash + this record
}
