import 'package:intl/intl.dart';
import '../database/app_database.dart'; // Entities
import 'transaction_service.dart'; // Helpers if needed

class ReceiptService {
  // In a real app, we'd use 'esc_pos_utils' to generate bytes.
  // For this core verification, we will generate a formatted String
  // which simulates exactly what would be printed.
  
  String generateReceipt({
    required String shopName,
    required String cashierName, // User name
    required String saleUuid,
    required DateTime date,
    required List<CartItem> items,
    required double total,
    required String paymentMethod,
  }) {
    final buffer = StringBuffer();
    final fmt = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    // Header
    buffer.writeln("================================");
    buffer.writeln("       $shopName        ");
    buffer.writeln("================================");
    buffer.writeln("Date: ${dateFmt.format(date)}");
    buffer.writeln("Cashier: $cashierName");
    buffer.writeln("Bill No: ${saleUuid.substring(0, 8)}");
    buffer.writeln("--------------------------------");
    buffer.writeln("ITEM          QTY      TOTAL");
    buffer.writeln("--------------------------------");

    // Items
    for (var item in items) {
      String name = item.productName;
      if (name.length > 12) name = name.substring(0, 12); // Truncate for print
      
      String qty = item.quantity.toStringAsFixed(0).padLeft(3);
      String lineTotal = (item.unitPrice * item.quantity).toStringAsFixed(2).padLeft(10);
      
      // "Milk Packet   002   Rs. 200.00"
      buffer.writeln("${name.padRight(12)} $qty $lineTotal");
    }

    // Footer
    buffer.writeln("--------------------------------");
    buffer.writeln("TOTAL:        ${fmt.format(total).padLeft(12)}");
    buffer.writeln("--------------------------------");
    buffer.writeln("Paid via: $paymentMethod");
    buffer.writeln("================================");
    buffer.writeln("   Thank You, Come Again!   ");
    buffer.writeln("================================");
    buffer.writeln("\n\n"); // Feed lines

    return buffer.toString();
  }

  Future<void> printReceipt(String receiptContent) async {
    // Mock Driver: Connect -> Print -> Cut
    print("🖨️ SENDING TO PRINTER...");
    await Future.delayed(const Duration(milliseconds: 500));
    print(receiptContent);
    print("✅ PRINT COMPLETE");
  }
}
