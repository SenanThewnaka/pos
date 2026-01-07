import 'package:shared_preferences/shared_preferences.dart';

class ShopConfigService {
  static const String keyShopName = 'shop_name';
  static const String keyShopAddress = 'shop_address';
  static const String keyShopPhone = 'shop_phone';
  static const String keyHeader = 'receipt_header';
  static const String keyFooter = 'receipt_footer';
  static const String keyTaxRate = 'tax_rate';
  static const String keyPrinterIp = 'printer_ip';

  String shopName = "Synthora Store";
  String shopAddress = "123 Main Street, Colombo";
  String shopPhone = "011-2345678";
  String headerMessage = "Welcome!";
  String footerMessage = "Thank You, Come Again!";
  double taxRate = 0.0;
  String printerIp = "192.168.1.100";

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    shopName = prefs.getString(keyShopName) ?? "Synthora Store";
    shopAddress = prefs.getString(keyShopAddress) ?? "";
    shopPhone = prefs.getString(keyShopPhone) ?? "";
    headerMessage = prefs.getString(keyHeader) ?? "Welcome!";
    footerMessage = prefs.getString(keyFooter) ?? "Thank You, Come Again!";
    taxRate = prefs.getDouble(keyTaxRate) ?? 0.0;
    printerIp = prefs.getString(keyPrinterIp) ?? "192.168.1.100";
  }

  Future<void> saveSettings({
    required String name,
    required String address,
    required String phone,
    required String header,
    required String footer,
    required double tax,
    required String ip,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyShopName, name);
    await prefs.setString(keyShopAddress, address);
    await prefs.setString(keyShopPhone, phone);
    await prefs.setString(keyHeader, header);
    await prefs.setString(keyFooter, footer);
    await prefs.setDouble(keyTaxRate, tax);
    await prefs.setString(keyPrinterIp, ip);
    
    // Update local cache
    shopName = name;
    shopAddress = address;
    shopPhone = phone;
    headerMessage = header;
    footerMessage = footer;
    taxRate = tax;
    printerIp = ip;
  }
}
