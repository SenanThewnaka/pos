import 'dart:io';
import 'dart:async';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

enum PrinterType { bluetooth, network, none }

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  // Bluetooth
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;

  // Network
  String? _networkIp;
  int _networkPort = 9100;

  PrinterType _type = PrinterType.none;
  
  PrinterType get type => _type;
  bool get isConnected => _isConnected || (_type == PrinterType.network && _networkIp != null);
  BluetoothDevice? get selectedDevice => _selectedDevice;
  List<BluetoothDevice> get devices => _devices;
  String? get networkIp => _networkIp;

  // Init
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final typeIndex = prefs.getInt('printer_type') ?? 2; // Default none
    final savedMac = prefs.getString('printer_mac');
    final savedIp = prefs.getString('printer_ip');
    
    _type = PrinterType.values[typeIndex];
    _networkIp = savedIp;

    if (_type == PrinterType.bluetooth && savedMac != null) {
       // Attempt Reconnect
       // Check if bluetooth is on
       bool? isOn = await _bluetooth.isOn;
       if (isOn == true) {
         try {
           // We need to rescan to get the device object usually, 
           // but some libs allow connecting by address. 
           // BlueThermalPrinter needs object.
           await scan();
           final device = _devices.firstWhere((d) => d.address == savedMac, orElse: () => BluetoothDevice("Unknown", savedMac!));
           if (device.address != null) {
              await connectBluetooth(device);
           }
         } catch (e) {
           print("Auto-connect failed: $e");
         }
       }
    }
    
    // Listen to state
    try {
      _bluetooth.onStateChanged().listen((state) {
        if (state == BlueThermalPrinter.CONNECTED) {
          _isConnected = true;
        } else if (state == BlueThermalPrinter.DISCONNECTED) {
          _isConnected = false;
        }
      });
    } catch(e) {
      print("Bluetooth state listener failed (not on mobile?): $e");
    }
  }

  // --- Bluetooth ---

  Future<List<BluetoothDevice>> scan() async {
    try {
      _devices = await _bluetooth.getBondedDevices();
      return _devices;
    } catch (e) {
      print("Scan Error: $e");
      return [];
    }
  }

  Future<void> connectBluetooth(BluetoothDevice device) async {
    if (_isConnected) {
      await _bluetooth.disconnect();
    }
    try {
      await _bluetooth.connect(device);
      _selectedDevice = device;
      _type = PrinterType.bluetooth;
      _isConnected = true;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('printer_type', PrinterType.bluetooth.index);
      await prefs.setString('printer_mac', device.address ?? "");
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }

  // --- Network ---

  Future<void> setNetworkPrinter(String ip, {int port = 9100}) async {
    _networkIp = ip;
    _networkPort = port;
    _type = PrinterType.network;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('printer_type', PrinterType.network.index);
    await prefs.setString('printer_ip', ip);
  }

  // --- Printing ---

  Future<void> printBytes(List<int> bytes) async {
    if (_type == PrinterType.bluetooth) {
       if (!_isConnected && _selectedDevice != null) {
         // Try reconnect
         await _bluetooth.connect(_selectedDevice!);
       }
       if (await _bluetooth.isConnected == true) {
         // BlueThermalPrinter write bytes
         // It accepts Uint8List
         _bluetooth.writeBytes(Uint8List.fromList(bytes));
       } else {
         throw Exception("Bluetooth Printer not connected");
       }
    } else if (_type == PrinterType.network) {
       if (_networkIp == null) throw Exception("Network IP not set");
       
       Socket? socket;
       try {
         socket = await Socket.connect(_networkIp!, _networkPort, timeout: const Duration(seconds: 5));
         socket.add(bytes);
         await socket.flush();
         socket.destroy();
       } catch (e) {
         throw Exception("Network Print Failed: $e");
       }
    } else {
      print("Simulated Print (No HW config): ${bytes.length} bytes");
    }
  }
  
  Future<void> disconnect() async {
    if (_type == PrinterType.bluetooth) {
      await _bluetooth.disconnect();
    }
    _type = PrinterType.none;
    _isConnected = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('printer_type', PrinterType.none.index);
  }
}
