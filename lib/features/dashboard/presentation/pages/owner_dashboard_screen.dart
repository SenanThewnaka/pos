import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/logic/owner_control_service.dart';
import '../../../../core/logic/auth_service.dart';
import '../../../../core/database/daos/product_dao.dart';
import 'package:pos_app/core/logic/sync_service.dart';
import 'package:pos_app/core/logic/firebase_service.dart';
import 'package:pos_app/features/dashboard/presentation/pages/settings_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  final AppDatabase db;

  const OwnerDashboardScreen({Key? key, required this.db}) : super(key: key);

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  late OwnerControlService _controlService;
  late SyncService _syncService;
  List<Alert> _alerts = [];
  bool _loading = true;

  // Theme Constants
  final _bgColor = const Color(0xFF0F172A); // Slate 900
  final _cardColor = const Color(0xFF1E293B); // Slate 800
  final _accentColor = const Color(0xFF0EA5E9); // Sky 500
  final _dangerColor = const Color(0xFFEF4444); // Red 500
  final _successColor = const Color(0xFF10B981); // Emerald 500
  final _warningColor = const Color(0xFFF59E0B); // Amber 500

  @override
  void initState() {
    super.initState();
    _controlService = OwnerControlService(widget.db);
    _syncService = SyncService(widget.db, FirebaseService());
    _syncService.init(); 
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final alerts = await _controlService.generateAlerts();
    if (mounted) {
      setState(() {
        _alerts = alerts;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text("COMMAND CENTER", style: GoogleFonts.outfit(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_suggest_outlined, color: _accentColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(syncService: _syncService))),
          )
        ],
      ),
      body: _loading 
          ? Center(child: CircularProgressIndicator(color: _accentColor))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOP ROW: Health HUD
                    Row(
                      children: [
                        Expanded(flex: 3, child: _buildMoneyLeakRadar()),
                        const SizedBox(width: 16),
                        Expanded(flex: 4, child: _buildStockTruthHud()),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // PULSE ALERTS
                    Row(
                      children: [
                        Icon(Icons.monitor_heart_outlined, color: _dangerColor),
                        const SizedBox(width: 8),
                        Text("LIVE PULSE ALERTS", style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _alerts.isEmpty 
                      ? _buildSystemNominal()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _alerts.length,
                          itemBuilder: (ctx, i) => _buildAlertCard(_alerts[i]),
                        )
                  ],
                ),
              ),
            ),
    );
  }

  void _nav(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  // --- WIDGETS ---

  Widget _buildMoneyLeakRadar() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("MONEY LEAK RADAR", style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Simplified Radar Viz
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _successColor.withOpacity(0.5), width: 3)),
                child: Center(
                  child: Text("98%", style: TextStyle(color: _successColor, fontWeight: FontWeight.bold)), // Placeholder for Efficiency
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("REFUNDS: 0%", style: TextStyle(color: _accentColor, fontSize: 12)),
                  Text("VOIDS: 0%", style: TextStyle(color: _accentColor, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text("SECURE", style: TextStyle(color: _successColor, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStockTruthHud() {
    return StreamBuilder<StockHealthMetrics>(
      stream: widget.db.productDao.getHealthMetrics(),
      builder: (context, snapshot) {
        final metrics = snapshot.data ?? StockHealthMetrics(totalCostValue: 0, totalRetailValue: 0);
        final profit = metrics.totalRetailValue - metrics.totalCostValue;

        return Container(
          height: 140,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_cardColor, _bgColor]
            )
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("STOCK TRUTH (LIVE)", style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatColumn("TOTAL COST", "Rs ${metrics.totalCostValue.toStringAsFixed(0)}", Colors.white),
                  _buildStatColumn("RETAIL VAL", "Rs ${metrics.totalRetailValue.toStringAsFixed(0)}", _accentColor),
                ],
              ),
              const SizedBox(height: 8),
              Container(height: 1, color: Colors.white10),
              const SizedBox(height: 8),
              Text("POTENTIAL PROFIT: Rs ${profit.toStringAsFixed(0)}", style: TextStyle(color: _successColor, fontWeight: FontWeight.bold, fontSize: 12))
            ],
          ),
        );
      }
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        Text(value, style: GoogleFonts.robotoMono(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _accentColor, size: 28),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(Alert alert) {
    Color color;
    switch(alert.severity) {
      case Severity.CRITICAL: color = _dangerColor; break;
      case Severity.HIGH: color = _warningColor; break;
      default: color = _accentColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: BorderRadius.circular(8)
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.type.toString().split('.').last, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                Text(alert.message, style: TextStyle(color: Colors.grey[300])),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: Text("RESOLVE", style: TextStyle(color: color)))
        ],
      ),
    );
  }

  Widget _buildSystemNominal() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _successColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _successColor.withOpacity(0.2))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, color: _successColor),
          const SizedBox(width: 12),
          Text("SYSTEM NOMINAL - ZERO ANOMALIES", style: GoogleFonts.outfit(color: _successColor, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
