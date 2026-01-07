import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/logic/sync_service.dart';
import '../../../../core/logic/shop_config_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'printer_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  final SyncService syncService;

  const SettingsScreen({Key? key, required this.syncService}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _configService = ShopConfigService();
  
  final _shopNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _headerCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  final _taxRateCtrl = TextEditingController();
  final _printerIpCtrl = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _configService.loadSettings();
    setState(() {
      _shopNameCtrl.text = _configService.shopName;
      _addressCtrl.text = _configService.shopAddress;
      _phoneCtrl.text = _configService.shopPhone;
      _headerCtrl.text = _configService.headerMessage;
      _footerCtrl.text = _configService.footerMessage;
      _taxRateCtrl.text = _configService.taxRate.toString();
      _printerIpCtrl.text = _configService.printerIp;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    await _configService.saveSettings(
      name: _shopNameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      header: _headerCtrl.text.trim(),
      footer: _footerCtrl.text.trim(),
      tax: double.tryParse(_taxRateCtrl.text) ?? 0.0,
      ip: _printerIpCtrl.text.trim(),
    );
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Configuration Saved!", style: TextStyle(color: Colors.white)), backgroundColor: AppTheme.successColor));
    }
  }

  void _previewReceipt() {
     final buffer = StringBuffer();
     final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
     
     buffer.writeln("================================");
     buffer.writeln((_shopNameCtrl.text.isEmpty ? "SHOP NAME" : _shopNameCtrl.text).padLeft((32 + _shopNameCtrl.text.length) ~/ 2).padRight(32)); // Center align attempt
     if (_addressCtrl.text.isNotEmpty) buffer.writeln(_addressCtrl.text);
     if (_phoneCtrl.text.isNotEmpty) buffer.writeln("Tel: ${_phoneCtrl.text}");
     buffer.writeln("================================");
     if (_headerCtrl.text.isNotEmpty) {
       buffer.writeln(_headerCtrl.text);
       buffer.writeln("--------------------------------");
     }
     buffer.writeln("Date: ${dateFmt.format(DateTime.now())}");
     buffer.writeln("Bill No: PREVIEW-101");
     buffer.writeln("--------------------------------");
     buffer.writeln("ITEM          QTY      TOTAL");
     buffer.writeln("--------------------------------");
     buffer.writeln("Sample Item 1  2     1,500.00");
     buffer.writeln("Sample Item 2  1       500.00");
     buffer.writeln("--------------------------------");
     buffer.writeln("TOTAL:               2,000.00");
     buffer.writeln("--------------------------------");
     if (_footerCtrl.text.isNotEmpty) {
        buffer.writeln(_footerCtrl.text);
        buffer.writeln("================================");
     }
     
     showDialog(
       context: context, 
       builder: (_) => AlertDialog(
         backgroundColor: Colors.white,
         title: const Text("RECEIPT PREVIEW", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
         content: SingleChildScrollView(
           child: Container(
             padding: const EdgeInsets.all(16),
             color: Colors.white,
             child: Text(
               buffer.toString(),
               style: GoogleFonts.robotoMono(color: Colors.black, fontSize: 12),
             ),
           ),
         ),
         actions: [
           TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE"))
         ],
       )
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text("SHOP CONFIGURATION", style: GoogleFonts.outfit(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionHeader("SHOP DETAILS", Icons.store),
              _buildCard([
                _buildTextField("Shop Name", _shopNameCtrl, icon: Icons.branding_watermark),
                const SizedBox(height: 16),
                _buildTextField("Address", _addressCtrl, icon: Icons.location_on),
                const SizedBox(height: 16),
                _buildTextField("Phone Number", _phoneCtrl, icon: Icons.phone, inputType: TextInputType.phone),
              ]),

              const SizedBox(height: 24),
              _buildSectionHeader("RECEIPT TEMPLATE", Icons.receipt_long),
              _buildCard([
                _buildTextField("Header Message", _headerCtrl, icon: Icons.short_text, helper: "Printed just below the shop info"),
                const SizedBox(height: 16),
                _buildTextField("Footer Message", _footerCtrl, icon: Icons.notes, helper: "Printed at the bottom"),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _previewReceipt,
                  icon: const Icon(Icons.visibility, color: AppTheme.accentColor), 
                  label: const Text("PREVIEW RECEIPT LAYOUT", style: TextStyle(color: AppTheme.accentColor)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    side: const BorderSide(color: AppTheme.accentColor)
                  ),
                )
              ]),
              
              const SizedBox(height: 24),
              _buildSectionHeader("SYSTEM SETTINGS", Icons.settings_applications),
              _buildCard([
                _buildTextField("Default Tax Rate (%)", _taxRateCtrl, icon: Icons.percent, inputType: TextInputType.number),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterSettingsScreen())),
                  icon: const Icon(Icons.print, color: AppTheme.accentColor),
                  label: const Text("CONFIGURE PRINTER CONNECTION", style: TextStyle(color: AppTheme.accentColor)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    side: const BorderSide(color: AppTheme.accentColor)
                  ),
                )
              ]),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("SAVE ALL CHANGES"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4
                  ),
                  onPressed: _saveSettings,
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentColor, size: 20),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1.5)),
        ],
      ),
    );
  }
  
  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {IconData? icon, TextInputType inputType = TextInputType.text, String? helper}) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        helperText: helper,
        helperStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: icon != null ? Icon(icon, color: AppTheme.accentColor.withOpacity(0.7)) : null,
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2)), borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.accentColor), borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2)
      ),
    );
  }

  Widget _buildImagePicker() {
    // Placeholder for future image upload implementation
    return Container(); 
  }
}
