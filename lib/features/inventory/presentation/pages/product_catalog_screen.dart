import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/product_dao.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/logic/label_printing_service.dart';
import 'product_form_screen.dart';

class ProductCatalogScreen extends StatefulWidget {
  final ProductDao dao;
  const ProductCatalogScreen({Key? key, required this.dao}) : super(key: key);

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  String _searchQuery = "";
  final _labelService = LabelPrintingService();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = _searchQuery.isEmpty 
      ? await widget.dao.getAllProducts()
      : await widget.dao.searchProducts(_searchQuery);
    
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text("PRODUCT CATALOG", style: GoogleFonts.outfit(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => ProductFormScreen(dao: widget.dao)
          ));
          _loadProducts(); // Refresh on return
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1))
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Search Products",
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.accentColor),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                ),
                onChanged: _onSearch,
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
              : _products.isEmpty
                ? Center(child: Text("No products found.", style: GoogleFonts.outfit(color: AppTheme.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = _products[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.accentColor.withOpacity(0.1),
                            child: Text(p.name[0], style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(p.name, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text("Price: Rs. ${p.price.toStringAsFixed(2)} | Barcode: ${p.barcode}", style: const TextStyle(color: AppTheme.textSecondary)),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.print, color: AppTheme.accentColor),
                                tooltip: "Print Label",
                                onPressed: () {
                                  _labelService.printLabel(
                                    productName: p.name,
                                    barcode: p.barcode,
                                    price: p.price
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text("Printing label for ${p.name}..."),
                                    duration: const Duration(seconds: 1),
                                  ));
                                },
                              ),
                              const Icon(Icons.chevron_right, color: Colors.white54),
                            ],
                          ),
                          onTap: () async {
                             await Navigator.push(context, MaterialPageRoute(
                               builder: (_) => ProductFormScreen(dao: widget.dao, product: p)
                             ));
                             _loadProducts();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
