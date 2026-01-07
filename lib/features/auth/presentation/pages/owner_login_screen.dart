import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart';
import '../../../../core/logic/firebase_service.dart';
import '../../../../core/logic/email_service.dart';
import '../../../../core/logic/sync_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/pages/owner_dashboard_screen.dart';

class OwnerLoginScreen extends StatefulWidget {
  final AppDatabase db;
  const OwnerLoginScreen({Key? key, required this.db}) : super(key: key);

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _firebase = FirebaseService();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
    
    // Verify Credentials
    final store = await _firebase.verifyOwnerCredentials(email, password);
    
    if (store != null) {
       await _syncAndLogin(store['id']);
    } else {
       setState(() => _isLoading = false);
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: const Text("Invalid Email or Password"),
         backgroundColor: AppTheme.dangerColor,
       ));
    }
  }

  Future<void> _syncAndLogin(String storeId) async {
    try {
      // 1. Set Local Store Context
      final syncService = SyncService(widget.db, _firebase);
      await syncService.setStoreId(storeId);

      // 2. Sync Users from Cloud
      final users = await _firebase.getStoreUsers(storeId);
      
      // Clear local users
      await widget.db.delete(widget.db.users).go();
      
      // Insert cloud users
      for (final u in users) {
        await widget.db.into(widget.db.users).insert(
          UsersCompanion.insert(
            name: u['name'],
            pinCode: u['pinCode'],
            role: drift.Value(u['role'])
          )
        );
      }

      setState(() => _isLoading = false);

      if (mounted) {
         Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
           builder: (_) => OwnerDashboardScreen(db: widget.db)
         ), (route) => false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text("COMMAND ACCESS", style: GoogleFonts.outfit(letterSpacing: 2)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
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
                  child: const Icon(Icons.lock_open_rounded, size: 48, color: AppTheme.accentColor),
                ),
                const SizedBox(height: 24),
                Text("AUTHENTICATION", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text("Enter credentials to unlock command center.", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 32),
                
                TextField(
                  controller: _emailCtrl, 
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Email Identity", 
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey)
                  )
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordCtrl, 
                  obscureText: !_isPasswordVisible, 
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Access Key", 
                    prefixIcon: const Icon(Icons.vpn_key_outlined, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    )
                  )
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login, 
                    child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text("INITIATE SESSION")
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
