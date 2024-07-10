import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailHelper {
  static Future<void> sendWelcomeEmail(String email, String name, {String? message}) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final serviceId = 'service_ceomouo';
    final templateId = 'template_bhnwrhr';
    final userId = '602lV2ItpcOJZX3x1';
    String welcomeMessage;
    message==null
        ? welcomeMessage = "Welcome to Digital Menu Service \n You are logged in as $name with email id: $email"
    : welcomeMessage = message;
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': userId,
      'template_params': {
        'reply_to': 'mail2gautamraj@gmail.com',
        'to_email': email,
        'to_name': name,
        'message': welcomeMessage,
      },
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        print('Email sent successfully');
      } else {
        print('Failed to send email. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to send email: $e');
    }
  }

  static Future<void> sendOrderPlacedEmail(String email, String name, String orderId) async {
    const String serviceId = 'service_9nohf3q';
    const templateId = 'template_hpmes4o';
    const userId = 'dgk1j2qdZTemaTfYy';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': userId,
      'template_params': {
        'reply_to': 'mail2gautamraj@gmail.com',
        'to_email': email,
        'to_name': name,
        'message': "Dear $name,\nYour order with ID $orderId has been successfully placed. Thank you!",
      },
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        print('Order placed email sent successfully');
      } else {
        print('Failed to send order placed email. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to send order placed email: $e');
    }
  }
}
