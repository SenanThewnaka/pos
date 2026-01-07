import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';

class SupplierManagementScreen extends StatefulWidget {
  final AppDatabase db;
  const SupplierManagementScreen({Key? key, required this.db}) : super(key: key);

  @override
  State<SupplierManagementScreen> createState() => _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends State<SupplierManagementScreen> {
  late Stream<List<Supplier>> _suppliersStream;

  @override
  void initState() {
    super.initState();
    _suppliersStream = widget.db.select(widget.db.suppliers).watch();
  }

  Future<void> _showSupplierDialog({Supplier? supplier}) async {
    final nameCtrl = TextEditingController(text: supplier?.name);
    final phoneCtrl = TextEditingController(text: supplier?.phone);
    String? errorText;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: Text(supplier == null ? "ADD SUPPLIER" : "EDIT SUPPLIER", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
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
              child: Text(supplier == null ? "SAVE" : "UPDATE"), 
              onPressed: () async {
                 if (nameCtrl.text.isEmpty) return;

                 final phone = phoneCtrl.text.trim();
                 final phoneRegex = RegExp(r'^(?:0|94|\+94)?(?:7[0-9]|11|2[1-7]|3[1-8]|4[1-5]|5[1-2]|6[36-7]|8[1-2])[0-9]{7}$');
                 
                 if (!phoneRegex.hasMatch(phone)) {
                   setDialogState(() => errorText = "Invalid Phone Number");
                   return;
                 }
                 
                 if (supplier == null) {
                   await widget.db.into(widget.db.suppliers).insert(SuppliersCompanion.insert(
                     name: nameCtrl.text,
                     phone: drift.Value(phone),
                   ));
                 } else {
                   await (widget.db.update(widget.db.suppliers)..where((t) => t.id.equals(supplier.id))).write(SuppliersCompanion(
                     name: drift.Value(nameCtrl.text),
                     phone: drift.Value(phone),
                   ));
                 }
                 
                 if (mounted) Navigator.pop(context);
              }
            )
          ],
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text("SUPPLIERS", style: GoogleFonts.outfit(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showSupplierDialog(),
      ),
      body: StreamBuilder<List<Supplier>>(
        stream: _suppliersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
          }
          final suppliers = snapshot.data ?? [];
          if (suppliers.isEmpty) return Center(child: Text("No Suppliers Found", style: TextStyle(color: Colors.white.withOpacity(0.5))));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: suppliers.length,
            separatorBuilder: (_,__) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final s = suppliers[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05))
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: Text(s.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(s.name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16)),
                  subtitle: Text(s.phone ?? "No Phone", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.accentColor),
                    onPressed: () => _showSupplierDialog(supplier: s),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
