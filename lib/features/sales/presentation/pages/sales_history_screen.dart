import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/sales_dao.dart';
import '../../../../core/database/daos/product_dao.dart';
import '../../../../core/theme/app_theme.dart';
import 'transaction_detail_screen.dart';

class SalesHistoryScreen extends StatefulWidget {
  final SalesDao dao;
  final ProductDao productDao;
  const SalesHistoryScreen({Key? key, required this.dao, required this.productDao}) : super(key: key);

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<Sale> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    final sales = await widget.dao.getRecentSales();
    if (mounted) {
      setState(() {
        _sales = sales;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text("TRANSACTION LOG", style: GoogleFonts.outfit(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : _sales.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 60, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 16),
                      Text("NO TRANSACTIONS", style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 18, letterSpacing: 2)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sales.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final sale = _sales[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.successColor.withOpacity(0.1),
                          child: const Icon(Icons.attach_money, color: AppTheme.successColor),
                        ),
                        title: Text("Rs. ${sale.totalAmount.toStringAsFixed(2)}", style: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(
                            "${sale.paymentMethod} • ${sale.saleDate.toString().substring(0, 16)}", 
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                        onTap: () {
                           Navigator.push(context, MaterialPageRoute(
                             builder: (_) => TransactionDetailScreen(
                               dao: widget.dao, 
                               productDao: widget.productDao,
                               sale: sale
                             )
                           ));
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
