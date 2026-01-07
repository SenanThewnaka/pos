import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/logic/sync_service.dart';
import '../../../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final SyncService syncService;

  const SettingsScreen({Key? key, required this.syncService}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _printerIpCtrl = TextEditingController();
  final _taxRateCtrl = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _printerIpCtrl.text = prefs.getString('printer_ip') ?? "192.168.1.100";
      _taxRateCtrl.text = (prefs.getDouble('tax_rate') ?? 0.0).toString();
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_ip', _printerIpCtrl.text.trim());
    await prefs.setDouble('tax_rate', double.tryParse(_taxRateCtrl.text) ?? 0.0);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings Saved")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text("SYSTEM CONFIGURATION", style: GoogleFonts.outfit(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader("HARDWARE LINK"),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05))
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _printerIpCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Receipt Printer IP",
                        labelStyle: TextStyle(color: Colors.grey),
                        helperText: "e.g., 192.168.1.100",
                        helperStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.print, color: AppTheme.accentColor),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.accentColor))
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionHeader("STORE PARAMS"),
              Container(
                 decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05))
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _taxRateCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Default Tax Rate (%)",
                        labelStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.percent, color: AppTheme.accentColor),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.accentColor))
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("SAVE CONFIGURATION"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: AppTheme.accentColor, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: _saveSettings,
              ),

              const SizedBox(height: 40),
              _buildSectionHeader("CLOUD SYNC"),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accentColor.withOpacity(0.3))
                ),
                child: ListTile(
                  leading: const Icon(Icons.cloud_sync, color: AppTheme.accentColor),
                  title: Text("Manual Sync", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text("Store ID: ${widget.syncService.storeId ?? 'Unknown'}", style: const TextStyle(color: Colors.grey)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor.withOpacity(0.2)),
                    child: const Text("SYNC NOW", style: TextStyle(color: AppTheme.accentColor)),
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Syncing...")));
                      await widget.syncService.syncUsers();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sync Complete")));
                    },
                  ),
                ),
              )
            ],
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1)),
    );
  }
}
