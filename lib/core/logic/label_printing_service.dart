import 'dart:convert';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/logic/printer_service.dart';

class LabelPrintingService {
  
  /// Prints a barcode label for a product.
  /// Currently mocks the output to console.
  /// Format: 50mm x 25mm Sticky Label
  Future<void> printLabel({
    required String productName,
    required String barcode,
    required double price,
    int quantity = 1,
  }) async {
    final labelCommand = _generateEscPosCommand(productName, barcode, price);
    // Convert string command (TSPL/CPCL) to bytes
    final bytes = utf8.encode(labelCommand);
    
    for (int i = 0; i < quantity; i++) {
        try {
           await PrinterService().printBytes(bytes);
        } catch (e) {
           print("Label Print Error: $e");
           // Rethrow only on first attempt to notify UI? 
           // Or just log it.
        }
    }
  }

  String _generateEscPosCommand(String name, String barcode, double price) {
    // Simple ESC/POS simulation
    final buffer = StringBuffer();
    buffer.writeln("SIZE 50 mm, 25 mm");
    buffer.writeln("CLS");
    buffer.writeln("TEXT 10,10,\"3\",0,1,1,\"$name\"");
    buffer.writeln("BARCODE 10,50,\"128\",50,1,0,2,2,\"$barcode\"");
    buffer.writeln("TEXT 10,120,\"3\",0,1,1,\"Rs. ${price.toStringAsFixed(2)}\"");
    buffer.writeln("PRINT 1");
    return buffer.toString();
  }
}
