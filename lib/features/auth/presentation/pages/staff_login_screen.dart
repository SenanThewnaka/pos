import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart';
import '../../../../core/logic/auth_service.dart';
import '../../../../core/logic/firebase_service.dart';
import '../../../../core/logic/transaction_service.dart';
import '../../../../core/logic/sync_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../sales/presentation/pages/sales_screen.dart';
import 'login_screen.dart'; 

class StaffLoginScreen extends StatefulWidget {
  final AppDatabase db;
  final TransactionService txService;

  const StaffLoginScreen({Key? key, required this.db, required this.txService}) : super(key: key);

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _shopCodeCtrl = TextEditingController();
  final _firebase = FirebaseService();
  bool _isLoading = false;

  void _verifyShopAndProceed() async {
    final code = _shopCodeCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    
    // 1. Check Cloud
    final store = await _firebase.verifyShopCode(code);
    
    setState(() => _isLoading = false);

    if (store != null) {
      final storeId = store['id'];
      
      // 1b. Set Local Store Context
      final syncService = SyncService(widget.db, _firebase);
      await syncService.setStoreId(storeId);
      
      // 2. Sync Users from Cloud
      try {
        final users = await _firebase.getStoreUsers(storeId);
        
        // Clear local users and replace with cloud users (Naive Sync)
        await widget.db.delete(widget.db.users).go();
        
        for (final u in users) {
          await widget.db.into(widget.db.users).insert(
            UsersCompanion.insert(
              name: u['name'],
              pinCode: u['pinCode'],
              role: drift.Value(u['role'])
            )
          );
        }
      } catch (e) {
        print("Sync failed: $e");
        // Proceed anyway if offline? No, need users.
      }

      // 3. Proceed to PIN Screen (LoginScreen)
      if (mounted) {
         Navigator.push(context, MaterialPageRoute(
            builder: (_) => LoginScreen(db: widget.db, txService: widget.txService)
         ));
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Shop Code")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text("TERMINAL ACCESS", style: GoogleFonts.outfit(letterSpacing: 2)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    shape: BoxShape.circle
                  ),
                  child: const Icon(Icons.storefront_outlined, size: 48, color: AppTheme.accentColor),
                ),
                const SizedBox(height: 24),
                Text("STORE IDENTITY", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                Text("Enter the unique Store Code.", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 32),
                
                TextField(
                   controller: _shopCodeCtrl, 
                   textAlign: TextAlign.center,
                   textCapitalization: TextCapitalization.characters,
                   style: GoogleFonts.robotoMono(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold, color: Colors.white),
                   decoration: InputDecoration(
                     hintText: "SYN-XXXX",
                     hintStyle: TextStyle(color: Colors.grey[600]),
                     filled: true,
                     fillColor: Colors.black.withOpacity(0.3),
                   )
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyShopAndProceed,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("CONNECT TERMINAL")
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
