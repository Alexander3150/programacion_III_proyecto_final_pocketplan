import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../data/models/credit_card_model.dart';
import '../data/models/debit_card_model.dart';
import '../data/models/simulador_ahorro.dart';
import '../data/models/simulador_deuda.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _timeZoneInitialized = false;

  Future<void> init() async {
    if (!_timeZoneInitialized) {
      tz_data.initializeTimeZones();
      _timeZoneInitialized = true;
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: android);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _tryZonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: androidScheduleMode,
          payload: payload,
          matchDateTimeComponents: matchDateTimeComponents,
        );
      } on PlatformException catch (e) {
        if (e.code == 'exact_alarms_not_permitted') {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            scheduledDate,
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload,
            matchDateTimeComponents: matchDateTimeComponents,
          );
        } else {
          print('Error al programar notificación: $e');
        }
      }
    } else {
      print(
        'No se agenda notificación: la fecha programada está en el pasado. scheduledDate=$scheduledDate',
      );
    }
  }

  // ===================== MÉTODOS DE NOTIFICACIÓN =====================

  // --------- 1. Recordatorio diario ---------
  Future<void> scheduleDailyTransactionReminder({
    required int hour,
    required int minute,
    int notificationId = 101,
  }) async {
    await _tryZonedSchedule(
      id: notificationId,
      title: 'Pocket Plan',
      body:
          '¡Recuerda registrar tus ingresos y egresos de hoy para llevar un buen control de tus finanzas! 📒💡',
      scheduledDate: _nextInstanceOfTime(hour, minute),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'registro_transacciones',
          'Registro Diario',
          channelDescription: 'Recordatorio diario para registrar movimientos',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_stat_pocketplan',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'registro',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // --------- 2. Notificaciones de Simulador de Ahorro ---------
  Future<void> scheduleAhorroNotifications(
    SimuladorAhorro ahorro,
    int userId,
  ) async {
    final int baseId = (ahorro.id ?? 10000 + userId) * 10;
    DateTime fecha = ahorro.fechaInicio;
    final String periodo = ahorro.periodo;
    final int totalPagos = _calcularPagosTotales(ahorro);

    for (int i = 0; i < totalPagos; i++) {
      if (i != 0) {
        if (periodo.toLowerCase().startsWith('m')) {
          fecha = DateTime(fecha.year, fecha.month + 1, fecha.day);
        } else if (periodo.toLowerCase().startsWith('q')) {
          fecha = fecha.add(const Duration(days: 15));
        }
      }
      await scheduleAhorroReminder(
        id: baseId + i + 1,
        objetivo: ahorro.objetivo,
        fechaProximoPago: fecha,
        pagosRestantes: totalPagos - i,
        periodo: periodo,
        hour: 8,
        minute: 0,
      );
      await scheduleAhorroReminderToday(
        idBase: baseId + i + 1,
        objetivo: ahorro.objetivo,
        fechaPago: fecha,
        pagosRestantes: totalPagos - i,
        periodo: periodo,
        hour: 8,
        minute: 0,
      );
    }
  }

  Future<void> scheduleAhorroReminder({
    required int id,
    required String objetivo,
    required DateTime fechaProximoPago,
    required int pagosRestantes,
    required String periodo,
    required int hour,
    required int minute,
  }) async {
    final notificationDate = fechaProximoPago.subtract(const Duration(days: 1));
    final friendlyDate = _friendlyDate(fechaProximoPago);

    await _tryZonedSchedule(
      id: id,
      title: 'Pocket Plan',
      body:
          '¡Recuerda! Mañana te toca ahorrar para "$objetivo".\nTe quedan $pagosRestantes pago(s) para alcanzar tu meta. ($friendlyDate)',
      scheduledDate: _nextInstanceOfDate(hour, minute, notificationDate),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'simulador_ahorro',
          'Simulador de Ahorro',
          channelDescription: 'Recordatorio para simuladores de ahorro',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_stat_monetization_on',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'ahorro',
    );
  }

  Future<void> scheduleAhorroReminderToday({
    required int idBase,
    required String objetivo,
    required DateTime fechaPago,
    required int pagosRestantes,
    required String periodo,
    required int hour,
    required int minute,
  }) async {
    await _tryZonedSchedule(
      id: idBase + 10000,
      title: 'Pocket Plan',
      body:
          '¡Hoy es el día para ahorrar en tu meta "$objetivo"! Solo te quedan $pagosRestantes pago(s) para culminar tu objetivo. No pierdas el ritmo, ¡tú puedes lograrlo! 🚀',
      scheduledDate: _nextInstanceOfDate(hour, minute, fechaPago),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'simulador_ahorro',
          'Simulador de Ahorro',
          channelDescription: 'Recordatorio para simuladores de ahorro',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_stat_monetization_on',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'ahorro_hoy',
    );
  }

  // --------- 3. Notificaciones de Simulador de Deuda ---------
  Future<void> scheduleDeudaNotifications(
    SimuladorDeuda deuda,
    int userId,
  ) async {
    final int baseId = (deuda.id ?? 30000 + userId) * 10;
    DateTime fecha = deuda.fechaInicio;
    final String periodo = deuda.periodo;
    final int totalPagos = _calcularPagosTotalesDeuda(deuda);

    for (int i = 0; i < totalPagos; i++) {
      if (i != 0) {
        if (periodo.toLowerCase().startsWith('m')) {
          fecha = DateTime(fecha.year, fecha.month + 1, fecha.day);
        } else if (periodo.toLowerCase().startsWith('q')) {
          fecha = fecha.add(const Duration(days: 15));
        }
      }
      await scheduleDeudaReminder(
        id: baseId + i + 1,
        motivo: deuda.motivo,
        fechaProximoPago: fecha,
        pagosRestantes: totalPagos - i,
        periodo: periodo,
        hour: 8,
        minute: 0,
      );
      await scheduleDeudaReminderToday(
        idBase: baseId + i + 1,
        motivo: deuda.motivo,
        fechaPago: fecha,
        pagosRestantes: totalPagos - i,
        periodo: periodo,
        hour: 8,
        minute: 0,
      );
    }
  }

  Future<void> scheduleDeudaReminder({
    required int id,
    required String motivo,
    required DateTime fechaProximoPago,
    required int pagosRestantes,
    required String periodo,
    required int hour,
    required int minute,
  }) async {
    final notificationDate = fechaProximoPago.subtract(const Duration(days: 1));
    final friendlyDate = _friendlyDate(fechaProximoPago);

    await _tryZonedSchedule(
      id: id,
      title: 'Pocket Plan',
      body:
          '¡Recuerda! Mañana tienes que realizar un pago por tu deuda "$motivo".\nTe quedan $pagosRestantes pago(s) para finalizar. ($friendlyDate)',
      scheduledDate: _nextInstanceOfDate(hour, minute, notificationDate),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'simulador_deuda',
          'Simulador de Deuda',
          channelDescription: 'Recordatorio para simuladores de deuda',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_stat_receipt_long',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'deuda',
    );
  }

  Future<void> scheduleDeudaReminderToday({
    required int idBase,
    required String motivo,
    required DateTime fechaPago,
    required int pagosRestantes,
    required String periodo,
    required int hour,
    required int minute,
  }) async {
    await _tryZonedSchedule(
      id: idBase + 10000,
      title: 'Pocket Plan',
      body:
          '¡Hoy es el día para realizar tu pago de la deuda "$motivo"! Solo te quedan $pagosRestantes pago(s) para terminar. Mantente al día y evita recargos. 💸',
      scheduledDate: _nextInstanceOfDate(hour, minute, fechaPago),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'simulador_deuda',
          'Simulador de Deuda',
          channelDescription: 'Recordatorio para simuladores de deuda',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_stat_receipt_long',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'deuda_hoy',
    );
  }

  //Generadores de fechas
  DateTime _proximoDiaDelMes(int dia) {
    final now = DateTime.now();
    int mes = now.month;
    int anio = now.year;
    if (now.day >= dia) {
      // Si ya pasó este mes, programa para el siguiente mes
      mes++;
      if (mes > 12) {
        mes = 1;
        anio++;
      }
    }
    // Controla días que no existen (ej: 31 de febrero). Si el día no existe en el mes, usa el último día del mes.
    int ultimoDia = DateTime(anio, mes + 1, 0).day;
    if (dia > ultimoDia) dia = ultimoDia;
    return DateTime(anio, mes, dia);
  }

  DateTime? _fechaExpiracion(String exp) {
    try {
      // Soporta "08-2026" o "2026-08"
      final parts = exp.contains('-') ? exp.split('-') : exp.split('/');
      int mes, anio;
      if (parts[0].length == 4) {
        // "2026-08"
        anio = int.parse(parts[0]);
        mes = int.parse(parts[1]);
      } else {
        // "08-2026"
        mes = int.parse(parts[0]);
        anio = int.parse(parts[1]);
      }
      int ultimoDia = DateTime(anio, mes + 1, 0).day;
      return DateTime(anio, mes, ultimoDia);
    } catch (_) {
      return null;
    }
  }

  // --------- 4. Notificaciones de Tarjeta de Crédito ---------
  Future<void> scheduleCreditCardNotifications(
    CreditCard tarjeta,
    int userId,
  ) async {
    final int pagoBase = (tarjeta.id ?? 50000 + userId) * 10;
    final int corteBase = (tarjeta.id ?? 60000 + userId) * 10;
    final int expBase = (tarjeta.id ?? 70000 + userId) * 10;

    // ----------- 1. Pago mensual -----------
    int? diaPago = int.tryParse(tarjeta.pago);
    if (diaPago != null) {
      DateTime fechaPago = _proximoDiaDelMes(diaPago);
      await scheduleCreditCardPaymentReminder(
        id: pagoBase + 1,
        banco: tarjeta.banco,
        nombrePropietario: tarjeta.alias,
        fechaPago: fechaPago,
        hour: 8,
        minute: 0,
      );
      await scheduleCreditCardPaymentToday(
        idBase: pagoBase + 1,
        banco: tarjeta.banco,
        propietario: tarjeta.alias,
        fechaPago: fechaPago,
        hour: 8,
        minute: 0,
      );
    }

    // ----------- 2. Corte mensual -----------
    int? diaCorte = int.tryParse(tarjeta.corte);
    if (diaCorte != null) {
      DateTime fechaCorte = _proximoDiaDelMes(diaCorte);
      await scheduleCreditCardCorteReminder(
        id: corteBase + 1,
        banco: tarjeta.banco,
        nombrePropietario: tarjeta.alias,
        fechaCorte: fechaCorte,
        hour: 8,
        minute: 0,
      );
      await scheduleCreditCardCorteToday(
        idBase: corteBase + 1,
        banco: tarjeta.banco,
        propietario: tarjeta.alias,
        fechaCorte: fechaCorte,
        hour: 8,
        minute: 0,
      );
    }

    // ----------- 3. Expiración (mes/año) -----------
    DateTime? fechaExp = _fechaExpiracion(tarjeta.expiracion);
    if (fechaExp != null && fechaExp.isAfter(DateTime.now())) {
      await scheduleCardExpirationReminder(
        id: expBase + 1,
        tipoTarjeta: 'Crédito',
        banco: tarjeta.banco,
        nombrePropietario: tarjeta.alias,
        fechaExpiracion: fechaExp,
        hour: 8,
        minute: 0,
      );
      await scheduleCardExpirationToday(
        idBase: expBase + 1,
        tipo: 'Crédito',
        banco: tarjeta.banco,
        propietario: tarjeta.alias,
        fechaExpiracion: fechaExp,
        hour: 8,
        minute: 0,
      );
    }
  }

  Future<void> scheduleCreditCardPaymentReminder({
    required int id,
    required String banco,
    required String nombrePropietario,
    required DateTime fechaPago,
    required int hour,
    required int minute,
  }) async {
    final notificationDate = fechaPago.subtract(const Duration(days: 1));
    final friendlyDate = _friendlyDate(fechaPago);

    await _tryZonedSchedule(
      id: id,
      title: 'Pocket Plan',
      body:
          'Mañana es la fecha de pago de tu tarjeta de crédito en $banco.\nPropietario: $nombrePropietario.\nEvita cargos extra y mantén tu crédito al día. ($friendlyDate)',
      scheduledDate: _nextInstanceOfDate(hour, minute, notificationDate),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'pago_tarjeta',
          'Pago Tarjeta de Crédito',
          channelDescription: 'Recordatorio de pago de tarjeta de crédito',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_stat_credit_card',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'tarjeta_pago',
    );
  }

  Future<void> scheduleCreditCardPaymentToday({
    required int idBase,
    required String banco,
    required String propietario,
    required DateTime fechaPago,
    required int hour,
    required int minute,
  }) async {
    await _tryZonedSchedule(
      id: idBase + 10000,
      title: 'Pocket Plan',
      body:
          '¡Hoy es tu fecha de pago de la tarjeta de crédito "$banco" ($propietario)! Recuerda mantenerte al día para evitar intereses.',
      scheduledDate: _nextInstanceOfDate(hour, minute, fechaPago),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'tarjeta_credito_pago',
          'Pago de Tarjeta de Crédito',
          channelDescription: 'Recordatorio de pago de tarjeta de crédito',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_stat_credit_card',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'tarjeta_credito_pago_hoy',
    );
  }

  Future<void> scheduleCreditCardCorteReminder({
    required int id,
    required String banco,
    required String nombrePropietario,
    required DateTime fechaCorte,
    required int hour,
    required int minute,
  }) async {
    final notificationDate = fechaCorte.subtract(const Duration(days: 1));
    final friendlyDate = _friendlyDate(fechaCorte);

    await _tryZonedSchedule(
      id: id,
      title: 'Pocket Plan',
      body:
          '¡Atención! Mañana es la fecha de corte de tu tarjeta de crédito en $banco.\nPropietario: $nombrePropietario.\nRecuerda que tu saldo se actualizará. ($friendlyDate)',
      scheduledDate: _nextInstanceOfDate(hour, minute, notificationDate),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'corte_tarjeta',
          'Corte Tarjeta de Crédito',
          channelDescription: 'Recordatorio de corte de tarjeta de crédito',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_stat_account_balance',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'tarjeta_corte',
    );
  }

  Future<void> scheduleCreditCardCorteToday({
    required int idBase,
    required String banco,
    required String propietario,
    required DateTime fechaCorte,
    required int hour,
    required int minute,
  }) async {
    await _tryZonedSchedule(
      id: idBase + 10000,
      title: 'Pocket Plan',
      body:
          '¡Hoy es tu fecha de corte de la tarjeta "$banco" ($propietario)! Se actualizará tu saldo, asegúrate de estar solvente.',
      scheduledDate: _nextInstanceOfDate(hour, minute, fechaCorte),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'tarjeta_credito_corte',
          'Corte de Tarjeta de Crédito',
          channelDescription:
              'Recordatorio de fecha de corte de tarjeta de crédito',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_stat_account_balance',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'tarjeta_credito_corte_hoy',
    );
  }

  Future<void> scheduleCardExpirationReminder({
    required int id,
    required String tipoTarjeta,
    required String banco,
    required String nombrePropietario,
    required DateTime fechaExpiracion,
    required int hour,
    required int minute,
  }) async {
    final notificationDate = fechaExpiracion.subtract(const Duration(days: 1));
    final friendlyDate = _friendlyDate(fechaExpiracion);

    await _tryZonedSchedule(
      id: id,
      title: 'Pocket Plan',
      body:
          '¡Importante! Mañana es la fecha de expiración de tu tarjeta $tipoTarjeta en $banco.\nPropietario: $nombrePropietario. Considera renovarla para seguir usando tus servicios. ($friendlyDate)',
      scheduledDate: _nextInstanceOfDate(hour, minute, notificationDate),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiracion_tarjeta',
          'Expiración de Tarjeta',
          channelDescription: 'Recordatorio de expiración de tarjetas',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_stat_account_balance_wallet',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'tarjeta_expiracion',
    );
  }

  Future<void> scheduleCardExpirationToday({
    required int idBase,
    required String tipo,
    required String banco,
    required String propietario,
    required DateTime fechaExpiracion,
    required int hour,
    required int minute,
  }) async {
    await _tryZonedSchedule(
      id: idBase + 10000,
      title: 'Pocket Plan',
      body:
          '¡Hoy es la fecha de expiración de tu tarjeta $tipo "$banco" ($propietario)! Recuerda renovarla para seguir usándola.',
      scheduledDate: _nextInstanceOfDate(hour, minute, fechaExpiracion),
      details: NotificationDetails(
        android: AndroidNotificationDetails(
          tipo.toLowerCase() == 'crédito'
              ? 'tarjeta_credito_expiracion'
              : 'tarjeta_debito_expiracion',
          tipo.toLowerCase() == 'crédito'
              ? 'Expiración de Tarjeta de Crédito'
              : 'Expiración de Tarjeta de Débito',
          channelDescription: 'Recordatorio de expiración de tarjeta',
          importance: Importance.max,
          priority: Priority.high,
          icon:
              tipo.toLowerCase() == 'crédito'
                  ? 'ic_stat_credit_card'
                  : 'ic_stat_account_balance_wallet',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'tarjeta_expira_hoy',
    );
  }

  // --------- 5. Notificaciones de Tarjeta de Débito ---------
  /// Convierte string de expiración a DateTime (usa el último día del mes)
  DateTime parseExpirationDate(String expiracion) {
    // Ejemplo de formatos válidos: '07/27', '07-2027', '2027-07'
    try {
      // Formato MM/yy
      if (RegExp(r'^\d{2}/\d{2}$').hasMatch(expiracion)) {
        final parts = expiracion.split('/');
        final month = int.parse(parts[0]);
        final year = 2000 + int.parse(parts[1]);
        return DateTime(year, month + 1, 0); // último día del mes
      }
      // Formato MM-yyyy
      if (RegExp(r'^\d{2}-\d{4}$').hasMatch(expiracion)) {
        final parts = expiracion.split('-');
        final month = int.parse(parts[0]);
        final year = int.parse(parts[1]);
        return DateTime(year, month + 1, 0);
      }
      // Formato yyyy-MM
      if (RegExp(r'^\d{4}-\d{2}$').hasMatch(expiracion)) {
        final parts = expiracion.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        return DateTime(year, month + 1, 0);
      }
      // Formato MM/yyyy
      if (RegExp(r'^\d{2}/\d{4}$').hasMatch(expiracion)) {
        final parts = expiracion.split('/');
        final month = int.parse(parts[0]);
        final year = int.parse(parts[1]);
        return DateTime(year, month + 1, 0);
      }
    } catch (_) {}
    throw FormatException(
      "Formato de expiración inválido: $expiracion. Usa MM/yy, MM-yyyy, yyyy-MM, o MM/yyyy",
    );
  }

  Future<void> scheduleDebitCardNotifications(
    DebitCard tarjeta,
    int userId,
  ) async {
    final int expBase = (tarjeta.id ?? 80000 + userId) * 10;
    DateTime fechaExpiracion = parseExpirationDate(tarjeta.expiracion);

    await scheduleCardExpirationReminder(
      id: expBase + 1,
      tipoTarjeta: 'Débito',
      banco: tarjeta.banco,
      nombrePropietario: tarjeta.alias,
      fechaExpiracion: fechaExpiracion,
      hour: 8,
      minute: 0,
    );
    await scheduleCardExpirationToday(
      idBase: expBase + 1,
      tipo: 'Débito',
      banco: tarjeta.banco,
      propietario: tarjeta.alias,
      fechaExpiracion: fechaExpiracion,
      hour: 8,
      minute: 0,
    );
  }

  Future<void> showTestNotification() async {
    await flutterLocalNotificationsPlugin.show(
      999,
      '¡Notificación de prueba!',
      'Esto es para verificar que el canal funciona.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'canal_prueba',
          'Canal de Prueba',
          channelDescription: 'Canal para pruebas rápidas',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_stat_pocketplan', // Ajusta si usas otro nombre
        ),
      ),
    );
  }
  // ===================== UTILIDADES Y CANCELACIONES =====================

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfDate(int hour, int minute, DateTime date) {
    if (!_timeZoneInitialized) {
      throw Exception(
        "Debes llamar a NotificationService().init() antes de programar notificaciones.",
      );
    }
    return tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  String _friendlyDate(DateTime date) {
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${date.day} de ${meses[date.month - 1]}';
  }

  int _calcularPagosTotales(SimuladorAhorro ahorro) {
    int meses =
        ((ahorro.fechaFin.year - ahorro.fechaInicio.year) * 12) +
        (ahorro.fechaFin.month - ahorro.fechaInicio.month);
    if (ahorro.fechaFin.day < ahorro.fechaInicio.day) meses--;
    meses = meses <= 0 ? 1 : meses;
    if (ahorro.periodo.toLowerCase().startsWith('q')) {
      return meses * 2;
    }
    return meses;
  }

  int _calcularPagosTotalesDeuda(SimuladorDeuda deuda) {
    int meses =
        ((deuda.fechaFin.year - deuda.fechaInicio.year) * 12) +
        (deuda.fechaFin.month - deuda.fechaInicio.month);
    if (deuda.fechaFin.day < deuda.fechaInicio.day) meses--;
    meses = meses <= 0 ? 1 : meses;
    if (deuda.periodo.toLowerCase().startsWith('q')) {
      return meses * 2;
    }
    return meses;
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelAhorroNotifications(int ahorroId, int userId) async {
    final int baseId = (ahorroId ?? 10000 + userId) * 10;
    await cancelNotification(baseId + 1);
    await cancelNotification(baseId + 2);
    await cancelNotification(baseId + 1 + 10000);
    await cancelNotification(baseId + 2 + 10000);
  }

  Future<void> cancelDeudaNotifications(int deudaId, int userId) async {
    final int baseId = (deudaId ?? 30000 + userId) * 10;
    await cancelNotification(baseId + 1);
    await cancelNotification(baseId + 2);
    await cancelNotification(baseId + 1 + 10000);
    await cancelNotification(baseId + 2 + 10000);
  }

  Future<void> cancelCreditCardNotifications(int tarjetaId, int userId) async {
    final int pagoBase = (tarjetaId ?? 50000 + userId) * 10;
    await cancelNotification(pagoBase + 1);
    await cancelNotification(pagoBase + 2);
    await cancelNotification(pagoBase + 1 + 10000);
    await cancelNotification(pagoBase + 2 + 10000);

    final int corteBase = (tarjetaId ?? 60000 + userId) * 10;
    await cancelNotification(corteBase + 1);
    await cancelNotification(corteBase + 2);
    await cancelNotification(corteBase + 1 + 10000);
    await cancelNotification(corteBase + 2 + 10000);

    final int expBase = (tarjetaId ?? 70000 + userId) * 10;
    await cancelNotification(expBase + 1);
    await cancelNotification(expBase + 2);
    await cancelNotification(expBase + 1 + 10000);
    await cancelNotification(expBase + 2 + 10000);
  }

  Future<void> cancelDebitCardNotifications(int tarjetaId, int userId) async {
    final int expBase = (tarjetaId ?? 80000 + userId) * 10;
    await cancelNotification(expBase + 1);
    await cancelNotification(expBase + 2);
    await cancelNotification(expBase + 1 + 10000);
    await cancelNotification(expBase + 2 + 10000);
  }
}
