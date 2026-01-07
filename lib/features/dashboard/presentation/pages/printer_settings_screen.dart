import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:pos_app/core/logic/printer_service.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final _printerService = PrinterService();
  final _ipCtrl = TextEditingController();
  
  bool _scanning = false;
  List<BluetoothDevice> _devices = [];
  bool _connected = false;
  String _status = "";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _printerService.init();
    setState(() {
      _connected = _printerService.isConnected;
      if (_printerService.type == PrinterType.network) {
        _ipCtrl.text = _printerService.networkIp ?? "";
        _status = "Mode: Network (${_printerService.networkIp})";
      } else if (_printerService.type == PrinterType.bluetooth) {
        _status = "Mode: Bluetooth (${_printerService.selectedDevice?.name ?? 'Unknown'})";
      } else {
         _status = "Not Configured";
      }
    });
  }

  Future<void> _scanBluetooth() async {
    setState(() {
      _scanning = true; 
      _devices = [];
    });
    
    try {
      final devices = await _printerService.scan();
      setState(() {
        _devices = devices;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Scan Error: $e")));
    } finally {
      setState(() => _scanning = false);
    }
  }

  Future<void> _connectBluetooth(BluetoothDevice device) async {
    setState(() => _status = "Connecting...");
    try {
      await _printerService.connectBluetooth(device);
      setState(() {
        _connected = true;
        _status = "Connected to ${device.name}";
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bluetooth Connected!")));
    } catch (e) {
      setState(() => _status = "Connection Failed");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _saveNetwork() async {
    final ip = _ipCtrl.text.trim();
    if (ip.isEmpty) return;
    
    try {
      await _printerService.setNetworkPrinter(ip);
      setState(() {
        _connected = true; 
        _status = "Network Configured: $ip";
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Network Settings Saved")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _testPrint() async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.reset();
      bytes += generator.text('TEST PRINT SUCCESS',
          styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('Synthora POS',
          styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(2);
      bytes += generator.cut();

      await _printerService.printBytes(bytes);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Test sent!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Print Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text("PRINTER SETUP", style: GoogleFonts.outfit(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // STATUS CARD
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _connected ? AppTheme.successColor.withOpacity(0.1) : AppTheme.dangerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _connected ? AppTheme.successColor : AppTheme.dangerColor)
              ),
              child: Row(
                children: [
                   Icon(_connected ? Icons.print : Icons.print_disabled, color: _connected ? AppTheme.successColor : AppTheme.dangerColor, size: 32),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(_status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                         Text(_connected ? "Ready to print" : "No active printer", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                       ],
                     ),
                   ),
                   if (_connected)
                     TextButton(onPressed: _testPrint, child: const Text("TEST PRINT"))
                ],
              ),
            ),
            const SizedBox(height: 32),

            // BLUETOOTH SECTION
            Text("BLUETOOTH PRINTERS", style: GoogleFonts.outfit(color: AppTheme.accentColor, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16)
              ),
              child: Column(
                children: [
                  if (_devices.isEmpty)
                     Padding(
                       padding: const EdgeInsets.all(24.0),
                       child: Text("No devices found. Ensure Bluetooth is ON and printer is paired via System Settings.", 
                         textAlign: TextAlign.center,
                         style: TextStyle(color: Colors.white.withOpacity(0.5))),
                     ),
                  
                  ..._devices.map((d) => ListTile(
                    title: Text(d.name ?? "Unknown", style: const TextStyle(color: Colors.white)),
                    subtitle: Text(d.address ?? "", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                    trailing: _printerService.selectedDevice?.address == d.address && _connected
                       ? const Icon(Icons.check_circle, color: AppTheme.successColor)
                       : ElevatedButton(
                           style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
                           onPressed: () => _connectBluetooth(d),
                           child: const Text("CONNECT"),
                         ),
                  )).toList(),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: _scanning 
                           ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                           : const Icon(Icons.refresh, color: Colors.white),
                        label: Text(_scanning ? "SCANNING..." : "SCAN DEVICES", style: const TextStyle(color: Colors.white)),
                        onPressed: _scanning ? null : _scanBluetooth,
                        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.2))),
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // NETWORK SECTION
            Text("NETWORK PRINTER (WIFI/LAN)", style: GoogleFonts.outfit(color: AppTheme.accentColor, letterSpacing: 1.5)),
            const SizedBox(height: 16),
             Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16)
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _ipCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Printer IP Address",
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      hintText: "192.168.1.200",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                      prefixIcon: const Icon(Icons.network_wifi, color: Colors.grey),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.accentColor)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveNetwork,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, padding: const EdgeInsets.all(16)),
                      child: const Text("SAVE & CONNECT NETWORK"),
                    ),
                  )
                ],
              ),
             )
          ],
        ),
      ),
    );
  }
}
