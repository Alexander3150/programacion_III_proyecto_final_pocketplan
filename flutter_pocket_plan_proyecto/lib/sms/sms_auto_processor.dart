import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../data/models/movimiento_model.dart';
import '../data/models/repositories/movimiento_repository.dart';
import '../data/models/repositories/sms_auto_rule_repository.dart';
import '../data/models/repositories/tarjeta_credito_repository.dart';
import '../notifications/notification_service.dart';
import 'sms_message_parser.dart';

class SmsAutoProcessor {
  static String _normalizeSender(String sender) {
    final digits = sender.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) return digits;
    return '+$digits';
  }

  static String _buildSmsKey({
    required String sender,
    required String tipo,
    required double monto,
    required DateTime fecha,
    required String identifier,
    String? auth,
  }) {
    final raw =
        '$sender|$tipo|${monto.toStringAsFixed(2)}|${fecha.toIso8601String()}|$identifier|${auth ?? ''}';
    return sha1.convert(utf8.encode(raw)).toString();
  }

  static Future<bool> processIncomingSms({
    required int userId,
    required String sender,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (!trimmed.toLowerCase().startsWith('bimovil:')) return false;

    final parsed = SmsMessageParser.parseBiMovil(trimmed);
    if (parsed == null) return false;

    final ruleRepo = SmsAutoRuleRepository();
    final normalizedSender = _normalizeSender(sender);
    final identifier = parsed.identifier.toUpperCase();

    var rule = await ruleRepo.findMatchingRule(
      userId: userId,
      sender: normalizedSender,
      prefix: 'BiMovil:',
      identifier: identifier,
    );
    if (rule == null && normalizedSender.startsWith('+')) {
      rule = await ruleRepo.findMatchingRule(
        userId: userId,
        sender: normalizedSender.substring(1),
        prefix: 'BiMovil:',
        identifier: identifier,
      );
    }
    if (rule == null) return false;
    if (rule.identifierType.toLowerCase() !=
        parsed.identifierType.toLowerCase()) {
      return false;
    }

    final smsKey = _buildSmsKey(
      sender: normalizedSender,
      tipo: parsed.tipo,
      monto: parsed.monto,
      fecha: parsed.fecha,
      identifier: identifier,
      auth: parsed.auth,
    );

    final movRepo = MovimientoRepository();
    final exists = await movRepo.existsSmsKey(userId, smsKey);
    if (exists) return false;

    final metodoPago =
        rule.tipoTarjeta == 'Débito'
            ? 'Tarjeta Débito'
            : 'Tarjeta Crédito';

    final movimiento = Movimiento(
      userId: userId,
      tipo: parsed.tipo,
      fecha: parsed.fecha,
      monto: parsed.monto,
      concepto: parsed.concepto,
      etiqueta: 'Otros',
      metodoPago: metodoPago,
      tarjetaId: rule.tarjetaId,
      tipoTarjeta: rule.tipoTarjeta,
      origen: 'auto',
      smsKey: smsKey,
      smsSender: normalizedSender,
      smsAuth: parsed.auth,
      smsRaw: parsed.raw,
      createdAt: DateTime.now(),
    );

    final id = await movRepo.insertMovimientoAuto(movimiento);
    if (id == 0) return false;

    if (parsed.tipo == 'egreso' && rule.tipoTarjeta == 'Crédito') {
      final creditoRepo = TarjetaCreditoRepository();
      final tarjeta = await creditoRepo.getTarjetaCreditoById(
        rule.tarjetaId,
        userId,
      );
      if (tarjeta != null) {
        final nuevoSaldo = tarjeta.saldo - parsed.monto;
        await creditoRepo.actualizarSaldoTarjeta(
          tarjeta.id!,
          nuevoSaldo,
          userId,
        );
      }
    }

    await NotificationService().showAutoMovementNotification(
      tipo: parsed.tipo,
      monto: parsed.monto,
    );

    return true;
  }
}
