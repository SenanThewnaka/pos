import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/sales_bloc.dart';
import '../bloc/sales_state.dart';
import '../bloc/sales_event.dart';
import '../../../../core/theme/app_theme.dart';

class CartList extends StatelessWidget {
  const CartList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, state) {
        if (state.cartItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 16),
                Text("TERMINAL READY", style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.2), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                Text("Scan item or select from catalog", style: TextStyle(color: Colors.white.withOpacity(0.1))),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.cartItems.length,
          separatorBuilder: (c, i) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = state.cartItems[index];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
                ]
              ),
              child: Row(
                children: [
                  // Qty Badge
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentColor.withOpacity(0.3))
                    ),
                    child: Text("${item.quantity.toInt()}", style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        Text("@ Rs. ${item.unitPrice.toStringAsFixed(2)}", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Rs. ${(item.unitPrice * item.quantity).toStringAsFixed(2)}", 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                       // Delete Button
                       const SizedBox(height: 4),
                       InkWell(
                         onTap: () => context.read<SalesBloc>().add(UpdateCartItemQuantity(index, 0)),
                         child: Icon(Icons.delete_outline, color: AppTheme.dangerColor.withOpacity(0.8), size: 20),
                       )
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
