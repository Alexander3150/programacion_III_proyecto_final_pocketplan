class SmsParsedResult {
  final String tipo; // 'ingreso' o 'egreso'
  final double monto;
  final String concepto;
  final DateTime fecha;
  final String identifier;
  final String identifierType; // 'cuenta' o 'tarjeta'
  final String? auth;
  final String raw;

  SmsParsedResult({
    required this.tipo,
    required this.monto,
    required this.concepto,
    required this.fecha,
    required this.identifier,
    required this.identifierType,
    required this.raw,
    this.auth,
  });
}

class SmsMessageParser {
  static SmsParsedResult? parseBiMovil(String body) {
    final text = body.trim();

    // Consumo
    final consumo = RegExp(
      r'Consumo\s+por\s+Q\.?([0-9,]+\.\d{2})\s+en:\s*([^\.]+?)\s+Cuenta:\s*([A-Za-z0-9]+)\s+(\d{2}-[A-Za-z]{3})\s+(\d{2}:\d{2})\s+Aut\.?(\d+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (consumo != null) {
      final monto = _parseMonto(consumo.group(1)!);
      final lugar = consumo.group(2)!.trim();
      final identifier = consumo.group(3)!.trim().toUpperCase();
      final fecha = _parseFecha(consumo.group(4)!, consumo.group(5)!);
      final auth = consumo.group(6);
      return SmsParsedResult(
        tipo: 'egreso',
        monto: monto,
        concepto: 'Consumo en $lugar',
        fecha: fecha,
        identifier: identifier,
        identifierType: 'cuenta',
        auth: auth,
        raw: text,
      );
    }

    // Retiro
    final retiro = RegExp(
      r'Retiro\s+por\s+Q\.?([0-9,]+\.\d{2})\s+en\s+el\s+Cajero:\s*([^\.]+?)\s+con\s+su\s+tarjeta:\s*([A-Za-z0-9]+)\s+(\d{2}-[A-Za-z]{3})\s+(\d{2}:\d{2})\s+Aut\.?(\d+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (retiro != null) {
      final monto = _parseMonto(retiro.group(1)!);
      final lugar = retiro.group(2)!.trim();
      final identifier = retiro.group(3)!.trim().toUpperCase();
      final fecha = _parseFecha(retiro.group(4)!, retiro.group(5)!);
      final auth = retiro.group(6);
      return SmsParsedResult(
        tipo: 'egreso',
        monto: monto,
        concepto: 'Retiro en cajero $lugar',
        fecha: fecha,
        identifier: identifier,
        identifierType: 'tarjeta',
        auth: auth,
        raw: text,
      );
    }

    // Credito
    final credito = RegExp(
      r'Credito\s+por\s+Q\.?([0-9,]+\.\d{2})\s+en\s+la\s+Agencia:\s*([^\.]+?)\s+Cuenta:\s*([A-Za-z0-9]+)\s+(\d{2}-[A-Za-z]{3})\s+(\d{2}:\d{2})\s+Autorizacion:\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (credito != null) {
      final monto = _parseMonto(credito.group(1)!);
      final lugar = credito.group(2)!.trim();
      final identifier = credito.group(3)!.trim().toUpperCase();
      final fecha = _parseFecha(credito.group(4)!, credito.group(5)!);
      final auth = credito.group(6);
      return SmsParsedResult(
        tipo: 'ingreso',
        monto: monto,
        concepto: 'Credito en agencia $lugar',
        fecha: fecha,
        identifier: identifier,
        identifierType: 'cuenta',
        auth: auth,
        raw: text,
      );
    }

    return null;
  }

  static double _parseMonto(String raw) {
    final cleaned = raw.replaceAll(',', '').replaceAll('Q', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  static DateTime _parseFecha(String ddMon, String hhmm) {
    final parts = ddMon.split('-');
    final day = int.tryParse(parts[0]) ?? 1;
    final monthStr = parts[1].toLowerCase();
    final month = _monthFromAbbr(monthStr);
    final time = hhmm.split(':');
    final hour = int.tryParse(time[0]) ?? 0;
    final minute = int.tryParse(time[1]) ?? 0;

    final now = DateTime.now();
    var date = DateTime(now.year, month, day, hour, minute);
    if (date.isAfter(now.add(const Duration(days: 1)))) {
      date = DateTime(now.year - 1, month, day, hour, minute);
    }
    return date;
  }

  static int _monthFromAbbr(String abbr) {
    const map = {
      'ene': 1,
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'abr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'ago': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
      'dic': 12,
    };
    return map[abbr] ?? 1;
  }
}
