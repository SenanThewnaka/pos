import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/sales_bloc.dart';
import '../bloc/sales_event.dart';
import '../bloc/sales_state.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/product_dao.dart';
import '../../../../core/logic/transaction_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/control_pad.dart';
import '../widgets/cart_list.dart';

class SalesScreen extends StatelessWidget {
  final TransactionService transactionService;
  final ProductDao productDao;
  final int currentUserId;

  const SalesScreen({
    Key? key,
    required this.transactionService,
    required this.productDao,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SalesBloc(
        transactionService: transactionService,
        productDao: productDao,
        currentUserId: currentUserId,
      ),
      child: const SalesView(),
    );
  }
}

class SalesView extends StatelessWidget {
  const SalesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Row(
        children: [
          // LEFT: Cart View (65%)
          Expanded(
            flex: 65,
            child: Container(
              color: AppTheme.bgColor,
              child: Column(
                children: [
                  _buildHeader(context),
                  Container(height: 1, color: Colors.white.withOpacity(0.1)),
                  const Expanded(child: CartList()),
                  _buildTotals(context),
                ],
              ),
            ),
          ),
          
          Container(width: 1, color: Colors.white.withOpacity(0.1)),

          // RIGHT: Control Pad (35%)
          Expanded(
            flex: 35,
            child: Container(
              color: AppTheme.cardColor,
              padding: const EdgeInsets.all(16.0),
              child: const ControlPad(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.cardColor,
      child: Row(
        children: [
           IconButton(
             onPressed: () => Navigator.pop(context),
             icon: const Icon(Icons.arrow_back, color: Colors.white),
           ),
           const SizedBox(width: 8),
           Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(color: AppTheme.accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
             child: const Icon(Icons.shopping_cart_outlined, color: AppTheme.accentColor),
           ),
           const SizedBox(width: 16),
           Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text("ACTIVE TRANSACTION", style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
               Text("Ready to Scan", style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
             ],
           ),
           const Spacer(),
           Expanded(
             child: Container(
               height: 48,
               decoration: BoxDecoration(
                 color: AppTheme.bgColor,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: AppTheme.accentColor.withOpacity(0.3))
               ),
               child: TextField(
                 autofocus: true,
                 style: const TextStyle(color: Colors.white),
                 decoration: InputDecoration(
                   hintText: "SCAN BARCODE ...",
                   hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                   prefixIcon: const Icon(Icons.qr_code_scanner, color: AppTheme.accentColor, size: 20),
                   border: InputBorder.none,
                   focusedBorder: InputBorder.none,
                   enabledBorder: InputBorder.none,
                   contentPadding: const EdgeInsets.symmetric(vertical: 14),
                 ),
               ),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildTotals(BuildContext context) {
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, state) {
         return Container(
           padding: const EdgeInsets.all(24),
           decoration: BoxDecoration(
             color: AppTheme.cardColor,
             border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))
           ),
           child: Column(
             children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text("SUBTOTAL", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                   Text("Rs. ${state.grandTotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 14)),
                 ],
               ),
               const SizedBox(height: 8),
               Container(height: 1, color: Colors.white.withOpacity(0.1)),
               const SizedBox(height: 16),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text("TOTAL DUE", style: GoogleFonts.outfit(color: AppTheme.accentColor, fontSize: 20, fontWeight: FontWeight.bold)),
                   Text("Rs. ${state.grandTotal.toStringAsFixed(2)}", 
                     style: GoogleFonts.robotoMono(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.successColor)),
                 ],
               ),
             ],
           ),
         );
      },
    );
  }
}
