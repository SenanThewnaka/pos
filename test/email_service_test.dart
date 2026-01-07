import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:pos_app/core/logic/email_service.dart';

// Generate a MockClient
@GenerateMocks([http.Client])
import 'email_service_test.mocks.dart';


void main() {
  test('EmailService sends correct payload to Brevo', () async {
    final mockClient = MockClient();
    final service = EmailService(client: mockClient);
    
    // Stub response
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body')
    )).thenAnswer((_) async => http.Response('{"messageId": "123"}', 201));

    await service.sendVerificationEmail('test@example.com', '123456');

    // Verify
    verify(mockClient.post(
      Uri.parse('https://api.brevo.com/v3/smtp/email'),
      headers: anyNamed('headers'),
      body: argThat(contains('test@example.com'), named: 'body')
    )).called(1);
  });
}
