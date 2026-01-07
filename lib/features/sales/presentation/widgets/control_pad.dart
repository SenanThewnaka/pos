import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/sales_bloc.dart';
import '../bloc/sales_event.dart';
import '../../../../core/theme/app_theme.dart';

class ControlPad extends StatelessWidget {
  const ControlPad({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Number Pad
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
               // Calculate aspect ratio dynamically
               return GridView.count(
                crossAxisCount: 3,
                childAspectRatio: (constraints.maxWidth / 3) / (constraints.maxHeight / 5),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                   for(var i=1; i<=9; i++) _numKey(context, i.toString()),
                   _numKey(context, "C", color: AppTheme.dangerColor.withOpacity(0.1), textColor: AppTheme.dangerColor, onTap: () => _handleClear(context)),
                   _numKey(context, "0"),
                   _numKey(context, "⏎", color: AppTheme.successColor.withOpacity(0.1), textColor: AppTheme.successColor, onTap: () => _handleEnter(context)),
                ],
              );
            }
          ),
        ),
        const SizedBox(height: 16),
        // Action Buttons
        SizedBox(
          width: double.infinity,
          height: 72,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              shadowColor: AppTheme.successColor.withOpacity(0.5)
            ),
            onPressed: () {
               context.read<SalesBloc>().add(const ProcessCheckout("CASH"));
            },
            icon: const Icon(Icons.payments_outlined, size: 32, color: Colors.white),
            label: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("PROCESS PAYMENT", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const Text("CASH TRANSACTION", style: TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ),
        )
      ],
    );
  }
  
  void _handleEnter(BuildContext context) {
    // Focus search or quick add logic
  }
  
  void _handleClear(BuildContext context) {
    // Logic to clear input
  }
  
  Widget _numKey(BuildContext context, String label, {Color? color, Color? textColor, VoidCallback? onTap}) {
    return Material(
      color: color ?? AppTheme.bgColor,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap ?? () {
          // Handle number input locally or via Bloc/Controller?
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05))
          ),
          child: Center(child: Text(label, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: textColor ?? Colors.white))),
        ),
      ),
    );
  }
}
