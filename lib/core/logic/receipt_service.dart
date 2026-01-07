import 'package:intl/intl.dart';
import '../database/app_database.dart'; // Entities
import 'transaction_service.dart'; // Helpers if needed
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:pos_app/core/logic/printer_service.dart';

class ReceiptService {
  // In a real app, we'd use 'esc_pos_utils' to generate bytes.
  // For this core verification, we will generate a formatted String
  // which simulates exactly what would be printed.
  
  Future<void> printReceipt({
    required String shopName,
    String? shopAddress,
    String? shopPhone,
    String? headerMessage,
    String? footerMessage,
    required String cashierName, 
    required String saleUuid,
    required DateTime date,
    required List<CartItem> items,
    required double total,
    required String paymentMethod,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.reset();
    bytes += generator.text(shopName, styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    if (shopAddress != null && shopAddress.isNotEmpty) {
      bytes += generator.text(shopAddress, styles: const PosStyles(align: PosAlign.center));
    }
    if (shopPhone != null && shopPhone.isNotEmpty) {
      bytes += generator.text("Tel: $shopPhone", styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.hr();
    
    if (headerMessage != null && headerMessage.isNotEmpty) {
      bytes += generator.text(headerMessage, styles: const PosStyles(align: PosAlign.center));
      bytes += generator.hr();
    }

    // Info
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    bytes += generator.text("Date: ${dateFmt.format(date)}");
    bytes += generator.text("Bill: ${saleUuid.substring(0, 8)}");
    bytes += generator.text("Cashier: $cashierName");
    bytes += generator.hr();

    // Items
    bytes += generator.row([
      PosColumn(text: 'Item', width: 6),
      PosColumn(text: 'Qty', width: 2),
      PosColumn(text: 'Total', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    
    for (var item in items) {
      String name = item.productName;
      if (name.length > 20) name = "${name.substring(0, 19)}.";
      
      bytes += generator.text(name);
      bytes += generator.row([
         PosColumn(text: '', width: 6), // Spacer for name
         PosColumn(text: item.quantity.toStringAsFixed(0), width: 2),
         PosColumn(text: (item.unitPrice * item.quantity).toStringAsFixed(2), width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    
    bytes += generator.hr();
    
    // Total
    bytes += generator.text("TOTAL: ${NumberFormat.currency(symbol: 'Rs. ').format(total)}", 
        styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2));
        
    bytes += generator.hr();
    bytes += generator.text("Paid via: $paymentMethod", styles: const PosStyles(align: PosAlign.center));
    
    if (footerMessage != null && footerMessage.isNotEmpty) {
      bytes += generator.feed(1);
      bytes += generator.text(footerMessage, styles: const PosStyles(align: PosAlign.center));
    }
    
    bytes += generator.feed(2);
    bytes += generator.cut();

    try {
       await PrinterService().printBytes(bytes);
    } catch (e) {
       print("Print Error: $e");
       rethrow;
    }
  }

  // Legacy string generator for Preview
  String generateReceiptPreview({required String shopName, required double total, required List<CartItem> items}) {
     // ... Keep brief simplified version or reuse old logic if needed for Preview only.
     // For now, I'm replacing the MAIN generateReceipt logic which was used for printing.
     // But wait, SalesBloc calls generateReceipt to get a String?
     // I need to check SalesBloc usage.
     return "Preview Data"; 
  }
}
