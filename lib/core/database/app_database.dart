import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';
import 'daos/product_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/inventory_dao.dart';
import 'daos/auth_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Products, StockBatches, Sales, SaleItems, AuditLogs, Suppliers, PurchaseGrns, PurchaseGrnItems, Users], daos: [ProductDao, SalesDao, InventoryDao, AuthDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pos_core.sqlite'));
    return NativeDatabase.createInBackground(file, logStatements: true);
  });
}
