import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/logic/transaction_service.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'owner_signup_screen.dart';
import 'universal_login_screen.dart';

class LandingScreen extends StatelessWidget {
  final AppDatabase db;
  final TransactionService txService;

  const LandingScreen({
    Key? key,
    required this.db,
    required this.txService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Branding
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppTheme.accentColor.withOpacity(0.2), blurRadius: 30, spreadRadius: 5)
                  ]
                ),
                child: const Icon(Icons.store_mall_directory_outlined, size: 64, color: AppTheme.accentColor),
              ),
              const SizedBox(height: 24),
              Text(
                "SYNTHORA POS", 
                style: GoogleFonts.outfit(
                  color: Colors.white, 
                  fontSize: 36, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 4
                )
              ),
              Text(
                "NEXT-GEN RETAIL OPERATING SYSTEM", 
                style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary, 
                  fontSize: 12, 
                  letterSpacing: 2
                )
              ),
              const SizedBox(height: 64),
              
              // Connect Terminal (Unified Login)
              _buildOptionCard(
                context,
                icon: Icons.power_settings_new,
                title: "CONNECT TERMINAL",
                subtitle: "Login with Shop Code & PIN",
                isPrimary: true,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => UniversalLoginScreen(db: db, txService: txService)
                  ));
                }
              ),
              
              const SizedBox(height: 32),
              
              // Create Store Option
              _buildOptionCard(
                context,
                icon: Icons.add_business_outlined,
                title: "CREATE NEW STORE",
                subtitle: "Initialize a new Synthora instance",
                width: 340, // Full width
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(
                    builder: (_) => OwnerSignupScreen(db: db)
                  ));
                }
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, {
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required VoidCallback onTap,
    bool isPrimary = false,
    double width = 340,
  }) {
    final isSmall = width < 200;
    final color = isPrimary ? AppTheme.accentColor : AppTheme.cardColor;
    final textColor = isPrimary ? Colors.white : Colors.white;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.accentColor : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: isPrimary ? null : Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: isPrimary 
            ? [BoxShadow(color: AppTheme.accentColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0,8))]
            : [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0,4))]
        ),
        child: isSmall ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(icon, size: 32, color: isPrimary ? Colors.white : AppTheme.accentColor),
             const SizedBox(height: 16),
             Text(title, textAlign: TextAlign.center, style: GoogleFonts.outfit(
                fontSize: 14, 
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: textColor
              )),
              const SizedBox(height: 4),
              Text(subtitle, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                fontSize: 10, 
                color: isPrimary ? Colors.white.withOpacity(0.8) : AppTheme.textSecondary
              )),
          ],
        ) : Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12)
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: textColor
                  )),
                  Text(subtitle, style: TextStyle(
                    fontSize: 12, 
                    color: Colors.white.withOpacity(0.8)
                  )),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54)
          ],
        ),
      ),
    );
  }
}
