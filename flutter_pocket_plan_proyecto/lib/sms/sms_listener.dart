import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_telephony/telephony.dart';

import 'sms_auto_processor.dart';

class SmsListenerService {
  static const String _prefUserId = 'sms_auto_user_id';
  static final Telephony _telephony = Telephony.instance;

  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefUserId, userId);
  }

  static Future<int?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefUserId);
  }

  static Future<void> start(int userId) async {
    await saveUserId(userId);

    final bool? granted = await _telephony.requestSmsPermissions;
    if (granted != true) return;

    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        final address = message.address ?? '';
        final body = message.body ?? '';
        await SmsAutoProcessor.processIncomingSms(
          userId: userId,
          sender: address,
          body: body,
        );
      },
      onBackgroundMessage: smsBackgroundHandler,
      listenInBackground: true,
    );
  }
}

@pragma('vm:entry-point')
Future<void> smsBackgroundHandler(SmsMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  final userId = await SmsListenerService.getSavedUserId();
  if (userId == null) return;
  final address = message.address ?? '';
  final body = message.body ?? '';
  await SmsAutoProcessor.processIncomingSms(
    userId: userId,
    sender: address,
    body: body,
  );
}
