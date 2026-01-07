import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:google_fonts/google_fonts.dart'; // Ensure google_fonts is imported
import '../../../../core/database/app_database.dart';
import '../../../../core/logic/firebase_service.dart';
import '../../../../core/logic/email_service.dart';
import '../../../../core/logic/sync_service.dart';
import '../../../../core/logic/auth_service.dart';
import '../../../dashboard/presentation/pages/owner_dashboard_screen.dart';
import 'portal_launcher_screen.dart';

class OwnerSignupScreen extends StatefulWidget {
  final AppDatabase db;
  const OwnerSignupScreen({Key? key, required this.db}) : super(key: key);

  @override
  State<OwnerSignupScreen> createState() => _OwnerSignupScreenState();
}

class _OwnerSignupScreenState extends State<OwnerSignupScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _storeNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController(); // New
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _firebase = FirebaseService();
  final _emailService = EmailService();
  
  int _step = 1; // 1: Email, 2: OTP, 3: Store Details
  String _generatedOtp = "";
  bool _isLoading = false;
  bool _isPasswordVisible = false; // Visibility state

  // ... (existing email/OTP logic)

  void _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) return;

    setState(() => _isLoading = true);
    
    try {
      // Check if store exists
      if (await _firebase.isEmailRegistered(email)) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: const Text("Email already registered!"),
           backgroundColor: Colors.redAccent.withOpacity(0.8),
           behavior: SnackBarBehavior.floating,
           action: SnackBarAction(
             label: "RESET ACCOUNT",
             textColor: Colors.white,
             onPressed: () async {
               try {
                 await _firebase.deleteStore(email);
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account reset. You can now signup again.")));
               } catch (e) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Reset Failed: $e")));
               }
             },
           ),
           duration: const Duration(seconds: 10),
         ));
         setState(() => _isLoading = false);
         return;
      }
  
      _generatedOtp = (100000 + DateTime.now().microsecond % 899999).toString();
      final success = await _emailService.sendVerificationEmail(email, _generatedOtp);
      
      if (success) {
        setState(() => _step = 2);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to send email")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _verifyOtp() {
    if (_otpCtrl.text.trim() == _generatedOtp) {
      setState(() => _step = 3);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }
  }

  void _createStore() async {
    final name = _storeNameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;

    if (name.isEmpty) return;
    if (username.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username cannot be empty")));
       return;
    }
    if (password.length < 6) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password must be at least 6 characters")));
       return;
    }
    if (password != confirm) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
       return;
    }

    setState(() => _isLoading = true);

    final shopCode = "SYN-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

    try {
      final storeId = await _firebase.createStore(
        name: name,
        ownerEmail: _emailCtrl.text.trim(),
        shopCode: shopCode,
        password: password,
      );
      
      // Create Owner User (Password acts as PIN for now in the schema)
      // Hash handled by FirebaseService or Local Store? 
      // Actually createCloudUser takes plain PIN usually. We pass plain Password.
      // SyncService will hash it when pulling to local DB if configured? 
      // Checking SyncService logic: `insert(pinCode: u['pinCode'])`.
      // If Firebase stores Plain Text, Sync pulls Plain Text. Local Auth hashes?
      // Wait, standard practice: FE sends Hash? Or BE hashes?
      // `createCloudUser` probably just saves what we send.
      // `AuthService` expects Hashed PIN in DB generally.
      // I will hash it here if possible, OR assume `createCloudUser` is just storage.
      // Let's rely on AuthService.hashPin(password) and send THAT to cloud?
      // If I send Hashed Password to Cloud, then Sync pulls Hash, then Local DB has Hash.
      // Yes, standard way.
      final auth = AuthService(widget.db);
      final passwordHash = auth.hashPin(password);

      await _firebase.createCloudUser(
          storeId: storeId,
          name: username, // User-defined or "Owner"
          pin: passwordHash, // Storing Hashed Password in 'pinCode' field
          role: "OWNER"
      );
      
      // Send Welcome Email with Credentials (Fail-safe)
      try {
        await _emailService.sendWelcomeEmail(
          email: _emailCtrl.text.trim(),
          shopCode: shopCode,
          username: username
        );
      } catch (e) {
        print("Failed to send welcome email: $e");
      }
      
      await _setupLocalData(storeId);

      // Fetch the created user locally to login
      final user = await (widget.db.select(widget.db.users)..where((u) => u.name.equals(username))).getSingle();

      setState(() => _isLoading = false);
      
      if (mounted) {
         // Show Credentials Reveal Dialog
         showDialog(
           context: context,
           barrierDismissible: false,
           builder: (context) => AlertDialog(
             backgroundColor: const Color(0xFF1E293B),
             title: Text("ACCESS GRANTED", style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, letterSpacing: 1.5)),
             content: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 64),
                 const SizedBox(height: 16),
                 Text("Store Identity Initialized successfully.", style: TextStyle(color: Colors.grey[300]), textAlign: TextAlign.center),
                 const SizedBox(height: 24),
                 
                 // Credentials Card
                 Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: Colors.black.withOpacity(0.3),
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.3))
                   ),
                   child: Column(
                     children: [
                       _credentialRow("SHOP CODE", shopCode, isHighlight: true),
                       const Divider(color: Colors.white10),
                       _credentialRow("USERNAME", username),
                     ],
                   ),
                 ),
                 const SizedBox(height: 16),
                 Text("SAVE THIS CODE SECURELY.\nIt is required to connect additional terminals.", 
                   style: TextStyle(color: Colors.amber[300], fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
               ],
             ),
             actions: [
               SizedBox(
                 width: double.infinity,
                 height: 48,
                 child: ElevatedButton(
                   style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9)),
                   onPressed: () {
                     Navigator.pop(context); // Close Dialog
                     Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                       builder: (_) => PortalLauncherScreen(
                         db: widget.db, 
                         user: user,
                         syncService: SyncService(widget.db, _firebase)
                        )
                     ), (route) => false);
                   },
                   child: const Text("ACKNOWLEDGE & ENTER", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                 ),
               )
             ],
           )
         );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _setupLocalData(String storeId) async {
      final syncService = SyncService(widget.db, _firebase);
      await syncService.setStoreId(storeId);
      await syncService.syncUsers();
  }

  @override
  Widget build(BuildContext context) {
    // Futuristic Dark Theme Colors
    final bgColor = const Color(0xFF0F172A); // Slate 900
    final accentColor = const Color(0xFF0EA5E9); // Sky 500 (Neon Cyan-ish)
    final cardColor = const Color(0xFF1E293B); // Slate 800

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Synthora Identity", style: GoogleFonts.outfit(letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 20, spreadRadius: -5),
                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 10)),
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
                  ).createShader(bounds),
                  child: const Icon(Icons.security, size: 64, color: Colors.white),
                ),
                const SizedBox(height: 24),
                
                if (_step == 1) ...[
                  Text("Identity Verification", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text("Enter your email to begin secure initialization.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 32),
                  _buildInput(_emailCtrl, "Email Address", Icons.email_outlined, accentColor),
                  const SizedBox(height: 24),
                  _buildButton("SEND VERIFICATION CODE", _isLoading ? null : _sendOtp, accentColor),
                ],
                
                if (_step == 2) ...[
                   Text("Security Check", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                   const SizedBox(height: 8),
                   Text("Enter the 6-digit code sent to ${_emailCtrl.text}", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400])),
                   const SizedBox(height: 32),
                   _buildInput(_otpCtrl, "Verification Code", Icons.lock_clock_outlined, accentColor),
                   const SizedBox(height: 24),
                   _buildButton("VERIFY IDENTITY", _verifyOtp, accentColor),
                ],

                if (_step == 3) ...[
                  Text("Establish Nexus", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text("Configure your credentials.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 32),
                  _buildInput(_storeNameCtrl, "Store Designation", Icons.store_mall_directory_outlined, accentColor),
                  const SizedBox(height: 16),
                  
                  // Owner Username
                  _buildInput(_usernameCtrl, "Owner Username", Icons.person_outline, accentColor),
                  const SizedBox(height: 16),

                  // Password Fields with Visibility Toggle
                  _buildPasswordInput(_passwordCtrl, "Access Key (Password)", accentColor),
                  const SizedBox(height: 16),
                  _buildPasswordInput(_confirmPasswordCtrl, "Confirm Access Key", accentColor),
                  
                  const SizedBox(height: 32),
                  _buildButton("INITIALIZE STORE", _isLoading ? null : _createStore, accentColor),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, Color accent, {bool isNumber = false, int? maxLength}) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        filled: true,
        counterText: "", // Hide character counter
        fillColor: Colors.black.withOpacity(0.2),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent, width: 2)),
      ),
    );
  }

  Widget _buildPasswordInput(TextEditingController ctrl, String label, Color accent) {
    return TextField(
      controller: ctrl,
      obscureText: !_isPasswordVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500]),
        suffixIcon: IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey[500]),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent, width: 2)),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback? onPressed, Color accent) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: accent.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
    );
  }

  Widget _credentialRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold)),
          SelectableText(value, style: GoogleFonts.robotoMono(
            color: isHighlight ? const Color(0xFF10B981) : Colors.white, 
            fontSize: isHighlight ? 20 : 16, 
            fontWeight: FontWeight.bold
          )),
        ],
      ),
    );
  }
}

