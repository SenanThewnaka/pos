import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/product_dao.dart';
import '../../../../core/theme/app_theme.dart';

class InventoryScreen extends StatelessWidget {
  final ProductDao dao;

  const InventoryScreen({Key? key, required this.dao}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text("STOCK INVENTORY", style: GoogleFonts.outfit(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<StockBatch>>(
        // A real app would join with Product table for names
        // and have a dedicated getStockOverview() method
        future: dao.getAllBatches(), 
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
          
          final batches = snapshot.data!;
          if (batches.isEmpty) return Center(child: Text("No Stock Found", style: GoogleFonts.outfit(color: AppTheme.textSecondary)));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: batches.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final b = batches[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
                  ]
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: const Icon(Icons.inventory_2_outlined, color: AppTheme.accentColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("BATCH: ${b.batchCode}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text("Cost: Rs. ${b.costPrice.toStringAsFixed(2)}", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          Text("Expires: ${b.expiryDate.toString().split(' ')[0]}", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("${b.quantityOnHand}", 
                          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.successColor)),
                        const Text("UNITS", style: TextStyle(fontSize: 10, color: Colors.white54)),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
