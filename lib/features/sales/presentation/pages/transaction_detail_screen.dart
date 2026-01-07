import 'package:flutter/material.dart';
import 'package:pos_app/core/logic/receipt_service.dart';
import 'package:pos_app/core/logic/transaction_service.dart'; // For CartItem
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/sales_dao.dart';
import '../../../../core/database/daos/product_dao.dart';

class TransactionDetailScreen extends StatefulWidget {
  final SalesDao dao;
  final ProductDao productDao;
  final Sale sale;

  const TransactionDetailScreen({Key? key, required this.dao, required this.productDao, required this.sale}) : super(key: key);

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  List<SaleItem> _items = [];
  Map<int, String> _productNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final items = await widget.dao.getItemsForSale(widget.sale.id);
    
    // Fetch product names
    Map<int, String> names = {};
    for (var item in items) {
      // Very inefficient N+1 but acceptable for detail view of one receipt
      // Ideally DAO should do a join
      // We don't have getProductById exposed, let's just use "Unknown" or implement getProductById
      // Actually ProductDao has getProductByBarcode, but not ID easily accessible without custom query
      // Let's rely on cached or just "Product #{id}" if we can't easily get it, 
      // OR better: let's add getProductById to ProductDao in next step if needed.
      // For now, I'll try to find a way. 
      // Wait, ProductDao is available.
      // Let's assume we can fetch all or search. 
      // Actually, let's just display ID for now in this step and fix name fetching properly.
      names[item.productId] = "Item #${item.productId}";
    }

    if (mounted) {
      setState(() {
        _items = items;
        _productNames = names;
        _isLoading = false;
      });
    }
  }
  
  void _reprint() async {
     final receiptService = ReceiptService();
     
     // Convert SaleItems to CartItems for printing
     List<CartItem> cartItems = _items.map((i) => CartItem(
       productId: i.productId,
       productName: _productNames[i.productId] ?? "Item",
       quantity: i.quantity,
       unitPrice: i.unitPrice,
       tax: 0, // No tax info in SaleItem currently, assume 0 for reprint or valid value
       discount: 0 // No discount info in SaleItem currently
     )).toList();
     
     final receipt = receiptService.generateReceipt(
       shopName: "Synthora POS", // Should get from config
       cashierName: "Manager", // History doesn't assume current user
       saleUuid: widget.sale.uuid,
       date: widget.sale.saleDate,
       items: cartItems,
       total: widget.sale.totalAmount,
       paymentMethod: widget.sale.paymentMethod
     );
     
     await receiptService.printReceipt(receipt);
     if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Receipt Sent to Printer")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transaction Details")),
      body: Column(
        children: [
          // Header Summary
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.grey[100],
            child: Column(
              children: [
                Text("Total Amount", style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text("Rs. ${widget.sale.totalAmount.toStringAsFixed(2)}", 
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)
                ),
                const SizedBox(height: 8),
                Text("ID: ${widget.sale.uuid.substring(0, 8)}...", style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                      title: Text(_productNames[item.productId] ?? "Product ${item.productId}"), 
                      subtitle: Text("${item.quantity} x ${item.unitPrice}"),
                      trailing: Text("Rs. ${(item.quantity * item.unitPrice).toStringAsFixed(2)}"),
                    );
                  },
                ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text("REPRINT RECEIPT"),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                onPressed: _reprint, 
              ),
            ),
          )
        ],
      ),
    );
  }
}
