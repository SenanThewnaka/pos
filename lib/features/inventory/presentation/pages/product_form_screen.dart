import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/product_dao.dart';
import '../../../../core/theme/app_theme.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductDao dao;
  final Product? product; // Null means Add Mode

  const ProductFormScreen({Key? key, required this.dao, this.product}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _barcodeFocus = FocusNode();

  @override
  void dispose() {
    _barcodeFocus.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameCtrl.text = widget.product!.name;
      _barcodeCtrl.text = widget.product!.barcode;
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final name = _nameCtrl.text.trim();
      final barcode = _barcodeCtrl.text.trim();
      // Price & Cost defaults. Real values managed in GRN Stoc Batches.
      final price = widget.product?.price ?? 0.0;
      final cost = widget.product?.cost ?? 0.0;

      if (widget.product == null) {
        // Create New
        await widget.dao.addProduct(ProductsCompanion(
          uuid: drift.Value(DateTime.now().millisecondsSinceEpoch.toString()), // Simple UUID for now
          name: drift.Value(name),
          barcode: drift.Value(barcode),
          price: drift.Value(price),
          cost: drift.Value(cost),
          isActive: const drift.Value(true),
          updatedAt: drift.Value(DateTime.now()),
        ));
      } else {
        // Update Existing (Preserve price/cost)
        final updated = widget.product!.copyWith(
          name: name,
          barcode: barcode,
          updatedAt: DateTime.now(),
        );
        await widget.dao.updateProduct(updated);
      }
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text(widget.product == null ? "NEW PRODUCT" : "EDIT PRODUCT", style: GoogleFonts.outfit(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05))
                ),
                child: Column(
                  children: [
                    _buildTextField(_nameCtrl, "Product Name", Icons.label, 
                      isAutofocus: true, 
                      action: TextInputAction.next),
                    const SizedBox(height: 16),
                    _buildTextField(_barcodeCtrl, "Barcode / SKU", Icons.qr_code, 
                      focusNode: _barcodeFocus, 
                      action: TextInputAction.done,
                      onSubmitted: (_) => _save()), // Auto-save on Enter (Scanner)
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _save, 
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: AppTheme.accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                icon: const Icon(Icons.save, color: Colors.white),
                label: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) 
                  : Text("SAVE PRODUCT", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, 
      {bool isNumber = false, bool isAutofocus = false, FocusNode? focusNode, TextInputAction? action, Function(String)? onSubmitted}) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: isAutofocus,
      textInputAction: action,
      onFieldSubmitted: onSubmitted,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: AppTheme.accentColor),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.accentColor)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.dangerColor)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.dangerColor)),
      ),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }
}
