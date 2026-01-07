import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/logic/inventory_service.dart';
import '../../../../core/theme/app_theme.dart';

import 'package:pos_app/core/logic/label_printing_service.dart';
import 'grn_history_screen.dart';

class GrnEntryScreen extends StatefulWidget {
  final AppDatabase db;
  final InventoryService inventoryService;
  final LabelPrintingService labelService;

  const GrnEntryScreen({
    Key? key,
    required this.db,
    required this.inventoryService,
    required this.labelService,
  }) : super(key: key);

  @override
  State<GrnEntryScreen> createState() => _GrnEntryScreenState();
}

class _GrnEntryScreenState extends State<GrnEntryScreen> {
  // State
  int? _selectedSupplierId;
  final _barcodeCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _sellCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  final _barcodeFocus = FocusNode();
  final _costFocus = FocusNode();
  final _sellFocus = FocusNode();
  final _qtyFocus = FocusNode();
  
  // Temporary list of items to be added to GRN
  final List<Map<String, dynamic>> _grnItems = [];

  bool _isLoading = false;

  @override
  void dispose() {
    _barcodeFocus.dispose();
    _costFocus.dispose();
    _sellFocus.dispose();
    _qtyFocus.dispose();
    _barcodeCtrl.dispose();
    _costCtrl.dispose();
    _sellCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text("NEW STOCK ENTRY (GRN)", style: GoogleFonts.outfit(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: "View History",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GrnHistoryScreen(db: widget.db))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Container(height: 1, color: Colors.white.withOpacity(0.1)),
          _buildEntryForm(),
          Container(height: 1, color: Colors.white.withOpacity(0.1)),
          Expanded(child: _buildItemsList()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.cardColor,
      child: FutureBuilder<List<Supplier>>(
        future: widget.db.select(widget.db.suppliers).get(),
        builder: (context, snapshot) {
           if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
           final suppliers = snapshot.data!;
           
           return Row(
             children: [
               Expanded(
                 child: Autocomplete<Supplier>(
                   displayStringForOption: (Supplier s) => s.name,
                   optionsBuilder: (TextEditingValue val) {
                     if (val.text.isEmpty) return suppliers;
                     return suppliers.where((s) => s.name.toLowerCase().contains(val.text.toLowerCase()));
                   },
                   onSelected: (Supplier s) {
                     setState(() => _selectedSupplierId = s.id);
                   },
                   fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                     return TextField(
                       controller: controller,
                       focusNode: focusNode,
                       style: const TextStyle(color: Colors.white),
                       decoration: InputDecoration(
                         labelText: "Search or Select Supplier",
                         labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                         prefixIcon: const Icon(Icons.search, color: AppTheme.accentColor),
                         suffixIcon: const Icon(Icons.arrow_drop_down, color: AppTheme.accentColor, size: 28),
                         enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                         focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.accentColor)),
                       ),
                     );
                   },
                   optionsViewBuilder: (context, onSelected, options) {
                     return Align(
                       alignment: Alignment.topLeft,
                       child: Material(
                         elevation: 4,
                         color: AppTheme.cardColor,
                         borderRadius: BorderRadius.circular(8),
                         child: Container(
                           width: 300,
                           constraints: const BoxConstraints(maxHeight: 300),
                           child: ListView.builder(
                             padding: EdgeInsets.zero,
                             shrinkWrap: true,
                             itemCount: options.length,
                             itemBuilder: (context, index) {
                               final option = options.elementAt(index);
                               return ListTile(
                                 title: Text(option.name, style: const TextStyle(color: Colors.white)),
                                 onTap: () => onSelected(option),
                                 hoverColor: Colors.white.withOpacity(0.1),
                               );
                             },
                           ),
                         ),
                       ),
                     );
                   },
                 ),
               ),
               const SizedBox(width: 16),
               IconButton(
                 onPressed: _showAddSupplierDialog, 
                 icon: const Icon(Icons.person_add, color: AppTheme.successColor, size: 28),
                 tooltip: "Add New Supplier",
               )
             ],
           );
        },
      ),
    );
  }

  Future<void> _showAddSupplierDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? errorText;
    
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: Text("ADD SUPPLIER", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               TextField(
                 controller: nameCtrl, 
                 style: const TextStyle(color: Colors.white),
                 decoration: InputDecoration(
                   labelText: "Supplier Name",
                   labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                   enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                 )
               ),
               const SizedBox(height: 16),
               TextField(
                 controller: phoneCtrl, 
                 keyboardType: TextInputType.phone,
                 style: const TextStyle(color: Colors.white),
                 decoration: InputDecoration(
                   labelText: "Phone Number",
                   errorText: errorText,
                   labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                   enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                 )
               ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)), 
              onPressed: () => Navigator.pop(context)
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
              child: const Text("SAVE SUPPLIER"), 
              onPressed: () async {
                 if (nameCtrl.text.isEmpty) return;

                 // Validate Phone (SL Format: 07x or +947x or 9-10 digits)
                 final phone = phoneCtrl.text.trim();
                 final phoneRegex = RegExp(r'^(?:0|94|\+94)?(?:7[0-9]|11|2[1-7]|3[1-8]|4[1-5]|5[1-2]|6[36-7]|8[1-2])[0-9]{7}$');
                 
                 if (!phoneRegex.hasMatch(phone)) {
                   setDialogState(() => errorText = "Invalid Phone Number (Use valid SL format)");
                   return;
                 }
                 
                 await widget.db.into(widget.db.suppliers).insert(SuppliersCompanion.insert(
                   name: nameCtrl.text,
                   phone: drift.Value(phone),
                 ));
                 
                 if (mounted) {
                   Navigator.pop(context);
                   setState(() {}); // Refresh List
                 }
              }
            )
          ],
        ),
      )
    );
  }

  void _focusAndSelect(TextEditingController ctrl, FocusNode node) {
    node.requestFocus();
    if (ctrl.text.isNotEmpty) {
      ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
    }
  }

  Widget _buildEntryForm() {
    return Container(
      color: AppTheme.bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 2,
            child: _buildSmallTextField(_barcodeCtrl, "Scan Barcode / SKU", Icons.qr_code_scanner, 
              focusNode: _barcodeFocus,
              onSubmitted: (_) => _lookupProduct()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSmallTextField(_costCtrl, "Cost Price", null, 
              isNumber: true, 
              focusNode: _costFocus,
              onSubmitted: (_) => _focusAndSelect(_sellCtrl, _sellFocus)),
          ),
          const SizedBox(width: 12),
          Expanded(
             child: _buildSmallTextField(_sellCtrl, "Sell Price", null, 
               isNumber: true, 
               focusNode: _sellFocus,
               onSubmitted: (_) => _focusAndSelect(_qtyCtrl, _qtyFocus)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSmallTextField(_qtyCtrl, "Qty", null, 
              isNumber: true, 
              focusNode: _qtyFocus,
              onSubmitted: (_) => _addItem()),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _addItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16)
            ),
            child: const Icon(Icons.add, color: Colors.white),
          )
        ],
      ),
    );
  }
  
  Widget _buildSmallTextField(TextEditingController ctrl, String hint, IconData? icon, 
      {bool isNumber = false, Function(String)? onSubmitted, FocusNode? focusNode}) {
    return TextField(
      controller: ctrl,
      focusNode: focusNode,
      style: const TextStyle(color: Colors.white),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      textInputAction: onSubmitted != null ? TextInputAction.next : TextInputAction.done,
      onTap: () {
        if (ctrl.text.isNotEmpty) {
          ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
        }
      },
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        suffixIcon: icon != null ? Icon(icon, color: AppTheme.accentColor, size: 16) : null,
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.accentColor)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onSubmitted: onSubmitted, 
    );
  }

  Widget _buildItemsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _grnItems.length,
      separatorBuilder: (_,__) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _grnItems[index];
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05))
          ),
          child: ListTile(
            title: Text(item['name'], style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text("Cost: ${item['cost']} | Sell: ${item['sellingPrice']} | Qty: ${item['quantity']}", style: TextStyle(color: AppTheme.textSecondary)),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: AppTheme.dangerColor.withOpacity(0.8)),
              onPressed: () => setState(() => _grnItems.removeAt(index)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    final total = _grnItems.fold(0.0, (sum, item) => sum + (item['cost'] * item['quantity']));
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("TOTAL COST", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text("Rs. ${total.toStringAsFixed(2)}", style: GoogleFonts.robotoMono(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("FINALIZE GRN"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
            ),
            onPressed: _grnItems.isEmpty ? null : _finalizeGrn,
          )
        ],
      ),
    );
  }

  Future<void> _lookupProduct() async {
     final barcode = _barcodeCtrl.text.trim();
     if (barcode.isEmpty) return;
     
     final product = await (widget.db.select(widget.db.products)..where((t) => t.barcode.equals(barcode))).getSingleOrNull();
     if (product != null) {
       setState(() {
         // Auto-fill existing prices
         _costCtrl.text = product.cost.toStringAsFixed(2);
         _sellCtrl.text = product.price.toStringAsFixed(2); 
       });
       // Auto-focus Cost and Select All for overwrite
       _focusAndSelect(_costCtrl, _costFocus);
     } else {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product not found!")));
       _barcodeCtrl.clear();
       _barcodeFocus.requestFocus();
     }
  }

  Future<void> _addItem() async {
    final barcode = _barcodeCtrl.text.trim();
    if (barcode.isEmpty) return;
    
    // 1. Lookup Product (Again to be safe)
    final product = await (widget.db.select(widget.db.products)..where((t) => t.barcode.equals(barcode))).getSingleOrNull();
    
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product not found! Add to Catalog first.")));
      return;
    }

    final cost = double.tryParse(_costCtrl.text) ?? 0.0;
    final sell = double.tryParse(_sellCtrl.text) ?? 0.0;
    final qty = double.tryParse(_qtyCtrl.text) ?? 0.0;

    if (cost <= 0 || qty <= 0 || sell <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Cost, Sell Price or Qty")));
       return;
    }

    setState(() {
      _grnItems.add({
        'productId': product.id,
        'name': product.name,
        'barcode': product.barcode,
        'sellingPrice': sell,
        'cost': cost,
        'quantity': qty,
        'previousCost': product.cost
      });
      
      _barcodeCtrl.clear();
      _costCtrl.clear();
      _sellCtrl.clear();
      _qtyCtrl.clear();
      
      // Auto-focus Barcode for next item
      _barcodeFocus.requestFocus();
    });
  }

  Future<bool> _showPriceHikeDialog(double oldCost, double newCost) async {
    return await showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text("⚠️ PRICE HIKE DETECTED", style: GoogleFonts.outfit(color: AppTheme.dangerColor, fontWeight: FontWeight.bold)),
        content: Text("New Cost ($newCost) is significantly higher than previous ($oldCost). Proceed?", style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("APPROVE CLICK")
          ),
        ],
      )
    ) ?? false;
  }

  Future<void> _finalizeGrn() async {
     setState(() => _isLoading = true);
     
     try {
       await widget.inventoryService.processGrn(
         supplierId: _selectedSupplierId ?? 0, 
         userId: 1, 
         items: _grnItems.map((i) => InventoryItemInput(
           productId: i['productId'], 
           quantity: i['quantity'], 
           unitCost: i['cost'],
           sellingPrice: i['sellingPrice'] // Passing selling price
         )).toList()
       );
       
       // Print Labels logic... (same as before)
       
        if (mounted) {
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("GRN Completed & Inventory Updated!")));
       }
     } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
     } finally {
        if (mounted) setState(() => _isLoading = false);
     }
  }
}
