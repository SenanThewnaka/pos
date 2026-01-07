import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';

class GrnHistoryScreen extends StatefulWidget {
  final AppDatabase db;
  const GrnHistoryScreen({Key? key, required this.db}) : super(key: key);

  @override
  State<GrnHistoryScreen> createState() => _GrnHistoryScreenState();
}

class _GrnHistoryScreenState extends State<GrnHistoryScreen> {
  late Future<List<drift.TypedResult>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture = (widget.db.select(widget.db.purchaseGrns)
            ..orderBy([(t) => drift.OrderingTerm(expression: t.receivedDate, mode: drift.OrderingMode.desc)]))
          .join([
            drift.leftOuterJoin(widget.db.suppliers, widget.db.suppliers.id.equalsExp(widget.db.purchaseGrns.supplierId))
          ])
          .get();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text("GRN HISTORY", style: GoogleFonts.outfit(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<drift.TypedResult>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
          
          final rows = snapshot.data!;
          if (rows.isEmpty) return Center(child: Text("No Stock Entries Found", style: TextStyle(color: Colors.white.withOpacity(0.5))));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_,__) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final row = rows[index];
              final grn = row.readTable(widget.db.purchaseGrns);
              final supplier = row.readTableOrNull(widget.db.suppliers);
              
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05))
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.accentColor.withOpacity(0.2),
                    child: const Icon(Icons.inventory_2_outlined, color: AppTheme.accentColor),
                  ),
                  title: Text(supplier?.name ?? "Unknown Supplier", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Code: ${grn.code}", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      Text(DateFormat('dd MMM yyyy, hh:mm a').format(grn.receivedDate), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Rs. ${grn.totalCost.toStringAsFixed(2)}", style: GoogleFonts.robotoMono(color: AppTheme.successColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(grn.status, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
