import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/core/logic/sync_service.dart';
import 'package:pos_app/features/sales/presentation/pages/sales_screen.dart';
import 'package:pos_app/features/dashboard/presentation/pages/owner_dashboard_screen.dart';
import 'package:pos_app/features/inventory/presentation/pages/inventory_screen.dart';
import 'package:pos_app/features/inventory/presentation/pages/product_catalog_screen.dart';
import 'package:pos_app/features/inventory/presentation/pages/grn_entry_screen.dart';
import 'package:pos_app/features/dashboard/presentation/pages/staff_management_screen.dart';
import 'package:pos_app/features/dashboard/presentation/pages/settings_screen.dart';
import 'package:pos_app/core/logic/inventory_service.dart';
import 'package:pos_app/core/logic/label_printing_service.dart';
import 'package:pos_app/core/logic/transaction_service.dart';

class PortalLauncherScreen extends StatelessWidget {
  final AppDatabase db;
  final User user;
  final SyncService syncService;

  const PortalLauncherScreen({
    Key? key,
    required this.db,
    required this.user,
    required this.syncService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOwner = user.role == 'OWNER' || user.role == 'MANAGER';

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text("NEXUS PORTAL", style: GoogleFonts.outfit(letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox(), // Hide back button for now (logout later)
        actions: [
          // SHOP CODE
          if (syncService.shopCode != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1))
                  ),
                  child: Row(
                    children: [
                       Icon(Icons.storefront, size: 14, color: Colors.grey[400]),
                       const SizedBox(width: 8),
                       Text(syncService.shopCode!, style: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              label: Text(user.name.toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              backgroundColor: AppTheme.accentColor.withOpacity(0.2),
              side: BorderSide(color: AppTheme.accentColor.withOpacity(0.5)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("OPERATIONAL MODULES", style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            
            // Sales Engine (Everyone)
            _buildPortalCard(
              context,
              title: "SALES ENGINE",
              subtitle: "POS Terminal & Checkout",
              icon: Icons.point_of_sale,
              color: AppTheme.successColor,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SalesScreen(
                transactionService: TransactionService(db),
                productDao: db.productDao,
                currentUserId: user.id
              ))),
            ),
            
            if (isOwner) ...[
              const SizedBox(height: 24),
              Text("COMMAND MODULES", style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220, // Responsive width
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                   final portals = [
                      _buildSmallPortal(context, "Command Center", Icons.dashboard_customize, AppTheme.accentColor, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerDashboardScreen(db: db)))),
                      _buildSmallPortal(context, "Inventory Control", Icons.inventory_2, Colors.purpleAccent, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => InventoryScreen(dao: db.productDao)))),
                      _buildSmallPortal(context, "Product Catalog", Icons.class_, Colors.orangeAccent, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductCatalogScreen(dao: db.productDao)))),
                      _buildSmallPortal(context, "GRN Entry", Icons.add_shopping_cart, Colors.tealAccent, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => GrnEntryScreen(db: db, inventoryService: InventoryService(db), labelService: LabelPrintingService())))),
                      _buildSmallPortal(context, "Staff Management", Icons.badge, Colors.pinkAccent, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => StaffManagementScreen(db: db, syncService: syncService)))),
                      _buildSmallPortal(context, "System Config", Icons.settings_suggest, Colors.blueGrey, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(syncService: syncService)))),
                   ];
                   return portals[index];
                },
              )
            ],

            const SizedBox(height: 48),
            Center(
               child: TextButton.icon(
                 icon: const Icon(Icons.logout, color: AppTheme.dangerColor),
                 label: const Text("TERMINATE SESSION", style: TextStyle(color: AppTheme.dangerColor)),
                 onPressed: () => Navigator.pop(context),
               ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPortalCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 120,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.cardColor, color.withOpacity(0.1)]
          )
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.2))
          ],
        ),
      ),
    );
  }

  Widget _buildSmallPortal(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
       onTap: onTap,
       borderRadius: BorderRadius.circular(16),
       child: Container(
         decoration: BoxDecoration(
           color: AppTheme.cardColor,
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: Colors.white.withOpacity(0.05))
         ),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(icon, color: color, size: 32),
             const SizedBox(height: 12),
             Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
           ],
         ),
       ),
    );
  }
}
