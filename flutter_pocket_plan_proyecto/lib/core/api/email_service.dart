import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailJSService {
  static const String serviceId = 'service_wgiq008';
  static const String templateId = 'template_046096q';
  static const String userId = 'v72cShmUXElNxsjPM';

  static Future<bool> sendRecoveryEmail({
    required String email,
    required String code,
  }) async {
    const String url = 'https://api.emailjs.com/api/v1.0/email/send';

    final Map<String, dynamic> payload = {
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': userId,
      'template_params': {
        'email': email,
        'verification_code': code,
        'link': 'https://pocketplan.app/recover/$code',
      },
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        print('✅ Correo enviado correctamente');
        return true;
      } else {
        print('❌ Error al enviar: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error de red o inesperado: $e');
      return false;
    }
  }
}
