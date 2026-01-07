import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift; 
import 'package:pos_app/core/database/app_database.dart';
import '../../../../core/logic/auth_service.dart';
import '../../../sales/presentation/pages/sales_screen.dart'; 
import '../../../dashboard/presentation/pages/owner_dashboard_screen.dart'; 
import '../../../../core/logic/transaction_service.dart';
import '../../../../core/database/daos/product_dao.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/logic/sync_service.dart';
import '../../../../core/logic/firebase_service.dart';
import 'portal_launcher_screen.dart';

class LoginScreen extends StatefulWidget {
  final AppDatabase db;
  final TransactionService txService;

  const LoginScreen({
    Key? key,
    required this.db,
    required this.txService,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late AuthService _authService;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(widget.db);
    // bootstrap dev users if needed...
  }

  Future<void> _attemptLogin() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (username.isEmpty || password.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    // Simulate network/crypto delay
    await Future.delayed(const Duration(milliseconds: 500));

    final user = await _authService.loginWithCredentials(username, password);
    
    setState(() => _isLoading = false);

    if (user != null) {
      if (!mounted) return;
      
      // Clear sensitive fields
      _passwordCtrl.clear();
      
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => PortalLauncherScreen(
          db: widget.db,
          user: user,
          syncService: SyncService(widget.db, FirebaseService()),
        )
      ));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("Invalid Credentials"), backgroundColor: AppTheme.dangerColor)
      );
      _passwordCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text("TERMINAL ACCESS", style: GoogleFonts.outfit(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView( 
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_person_outlined, size: 64, color: AppTheme.accentColor),
                ),
                const SizedBox(height: 24),
                Text("USER AUTHENTICATION", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                Text("Enter credentials to access Nexus.", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 32),
                
                // Username
                TextField(
                  controller: _usernameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Username",
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.person_outline, color: AppTheme.accentColor.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accentColor)),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _isObscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.vpn_key_outlined, color: AppTheme.accentColor.withOpacity(0.7)),
                    suffixIcon: IconButton(
                      icon: Icon(_isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    ),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accentColor)),
                  ),
                  onSubmitted: (_) => _attemptLogin(),
                ),
                
                const SizedBox(height: 48), // Spacing
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _attemptLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 8,
                      shadowColor: AppTheme.accentColor.withOpacity(0.4)
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("AUTHENTICATE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
