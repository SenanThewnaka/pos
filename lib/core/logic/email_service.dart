import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class EmailService {
  final String _apiKey = EnvConfig.brevoApiKey; 
  final String _senderName = "Synthora POS";
  final String _senderEmail = "noreply@synthora.lk";
  
  final http.Client _client;

  EmailService({http.Client? client}) : _client = client ?? http.Client();

  /// Sends a verification code via Brevo API.
  /// Returns [true] if successful.
  Future<bool> sendVerificationEmail(String email, String code) async {
    const url = 'https://api.brevo.com/v3/smtp/email';
    
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'api-key': _apiKey,
          'content-type': 'application/json',
        },
        body: jsonEncode({
          "sender": {
            "name": _senderName,
            "email": _senderEmail
          },
          "to": [
            {
              "email": email,
            }
          ],
          "subject": "Synthora POS Verification Code",
          "htmlContent": "<html><body><h1>Your Code: $code</h1><p>Please enter this code to verify your account.</p></body></html>"
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("Brevo Error: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Email Send Failed: $e");
      return false;
    }
  }
  /// Sends welcome email with credentials
  Future<bool> sendWelcomeEmail({required String email, required String shopCode, required String username}) async {
    const url = 'https://api.brevo.com/v3/smtp/email';
    
    final htmlContent = '''
      <html>
        <body style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
          <h1 style="color: #0EA5E9;">Welcome to Synthora POS</h1>
          <p>Your store has been successfully initialized.</p>
          <div style="background-color: #f3f4f6; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <p><strong>Shop Code:</strong> <span style="font-size: 18px; color: #10B981; font-weight: bold;">$shopCode</span></p>
            <p><strong>Username:</strong> $username</p>
          </div>
          <p>Please keep these credentials safe. You will need the Shop Code to connect additional terminals.</p>
          <p>Thank you for choosing Synthora.</p>
        </body>
      </html>
    ''';

    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'api-key': _apiKey,
          'content-type': 'application/json',
        },
        body: jsonEncode({
          "sender": {
            "name": _senderName,
            "email": _senderEmail
          },
          "to": [
            {"email": email}
          ],
          "subject": "Synthora Credentials: $shopCode",
          "htmlContent": htmlContent
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("Brevo Error: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Welcome Email Failed: $e");
      return false;
    }
  }
}
