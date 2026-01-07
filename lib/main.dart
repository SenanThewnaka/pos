import 'package:flutter/material.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/logic/transaction_service.dart';
import 'package:pos_app/core/logic/shadow_logger.dart';
import 'package:pos_app/core/logic/firebase_service.dart';
import 'package:pos_app/core/logic/sync_service.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'features/auth/presentation/pages/landing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Init Database
  final db = AppDatabase();
  
  // 2. Init Core Services
  await FirebaseService.init();
  final transactionService = TransactionService(db);
  await ShadowLogger.init(); 
  
  // 3. Init Sync
  final syncService = SyncService(db, FirebaseService());
  await syncService.init(); // Loads storeId and starts timer
  
  // 3. Run App
  runApp(PosApp(
    db: db,
    transactionService: transactionService,
  ));
}

class PosApp extends StatelessWidget {
  final AppDatabase db;
  final TransactionService transactionService;

  const PosApp({
    Key? key,
    required this.db,
    required this.transactionService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synthora POS',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      theme: AppTheme.darkTheme,
      home: LandingScreen(
        db: db,
        txService: transactionService,
      ),
    );
  }
}
