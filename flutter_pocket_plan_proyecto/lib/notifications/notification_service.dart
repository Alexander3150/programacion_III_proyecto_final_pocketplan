import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// MODELOS Y REPOSITORIOS
import '../data/models/credit_card_model.dart';
import '../data/models/debit_card_model.dart';
import '../data/models/simulador_ahorro.dart';
import '../data/models/simulador_deuda.dart';
import '../data/models/repositories/tarjeta_credito_repository.dart';
import '../data/models/repositories/tarjeta_debito_repository.dart';
import '../data/models/repositories/simulador_ahorro_repository.dart';
import '../data/models/repositories/simulador_deuda_repository.dart';
import '../presentation/pages/datos_ahorro_page.dart';
import '../presentation/pages/datos_deuda_page.dart';
import '../presentation/pages/login_page.dart';
import '../presentation/pages/modificacion_detalle_tarjeta_credito_screen.dart';
import '../presentation/pages/modificacion_detalle_tarjeta_debito.dart';
import '../presentation/pages/registros_ie_page.dart';

import '../main.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _timeZoneInitialized = false;
  static const String _tzName = 'America/Guatemala';

  // --------- NUEVO: Constante para rango de dÃ­as mÃ¡ximo a programar ---------
  static const int MAX_DIAS_A_PROGRAMAR = 30;

  bool _estaDentroDeRango(DateTime fechaEvento) {
    final ahora = DateTime.now();
    final limite = ahora.add(Duration(days: MAX_DIAS_A_PROGRAMAR));
    return fechaEvento.isAfter(ahora) && fechaEvento.isBefore(limite);
  }

  /// InicializaciÃ³n Ãºnica, llamarla solo una vez en main()
  Future<void> initialize() async {
    if (!_timeZoneInitialized) {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(_tzName));
      _timeZoneInitialized = true;
    }
    await _requestNotificationPermission();
    await _createNotificationChannels();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: android);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  // === Permiso Android 13+ ===
  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      }
    }
  }

  // === Crear canales de notificaciÃ³n ===
  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    final channels = [
      AndroidNotificationChannel(
        'registro_transacciones',
        'Registro Diario',
        description: 'Recordatorio diario para registrar movimientos',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        'simulador_ahorro',
        'Simulador de Ahorro',
        description: 'Recordatorios para simuladores de ahorro',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        'simulador_deuda',
        'Simulador de Deuda',
        description: 'Recordatorios para simuladores de deuda',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        'pago_tarjeta',
        'Pago Tarjeta',
        description: 'Recordatorio de pago de tarjeta',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        'expiracion_tarjeta',
        'ExpiraciÃ³n de Tarjeta',
        description: 'Recordatorio de expiraciÃ³n de tarjeta',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        'tarjeta_credito_pago',
        'Pago de Tarjeta de CrÃ©dito',
        description: 'Pago de tarjeta de crÃ©dito',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        'tarjeta_credito_corte',
        'Corte de Tarjeta de CrÃ©dito',
        description: 'Fecha de corte de tarjeta de crÃ©dito',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        'tarjeta_credito_expiracion',
        'ExpiraciÃ³n de Tarjeta de CrÃ©dito',
        description: 'ExpiraciÃ³n de tarjeta de crÃ©dito',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        'tarjeta_debito_expiracion',
        'ExpiraciÃ³n de Tarjeta de DÃ©bito',
        description: 'ExpiraciÃ³n de tarjeta de dÃ©bito',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        'test_channel',
        'Pruebas',
        description: 'Canal de pruebas instantÃ¡neas',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        'auto_movimientos',
        'Movimientos AutomÃ¡ticos',
        description: 'Notificaciones por movimientos detectados en SMS',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    ];

    for (final ch in channels) {
      await androidPlugin?.createNotificationChannel(ch);
    }
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse details) {}

  Future<void> _handleNotificationTap(String? payload) async {
    if (payload == null) return;

    if (payload == 'login_test') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const IniciarSesion()),
      );
      return;
    }

    if (payload == 'registro') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const RegistroMovimientoScreen()),
      );
      return;
    }

    final parts = payload.split(':');
    if (parts.length < 4) return;
    final tipo = parts[0];
    final int? id = int.tryParse(parts[1]);
    final int? userId = int.tryParse(parts[2]);
    if (id == null || userId == null) return;

    if (tipo == 'ahorro') {
      final repo = SimuladorAhorroRepository();
      final ahorro = await repo.getSimuladorAhorroById(id, userId);
      if (ahorro != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => DatosAhorroPage(simulador: ahorro)),
        );
      }
    } else if (tipo == 'deuda') {
      final repo = SimuladorDeudaRepository();
      final deuda = await repo.getSimuladorDeudaById(id, userId);
      if (deuda != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => DatosDeudaPage(simulador: deuda)),
        );
      }
    } else if (tipo == 'tarjeta_credito') {
      final repo = TarjetaCreditoRepository();
      final tarjeta = await repo.getTarjetaCreditoById(id, userId);
      if (tarjeta != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder:
                (_) => ModificacionDetalleTarjetaCreditoScreen(
                  tarjeta: tarjeta,
                  modoEdicion: false,
                ),
          ),
        );
      }
    } else if (tipo == 'tarjeta_debito') {
      final repo = TarjetaDebitoRepository();
      final tarjeta = await repo.getTarjetaDebitoById(id, userId);
      if (tarjeta != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder:
                (_) => ModificacionDetalleTarjetaDebitoScreen(
                  tarjeta: tarjeta,
                  modoEdicion: false,
                ),
          ),
        );
      }
    }
  }

  // ========== UNIVERSAL SCHEDULER FILTRANDO FECHAS PASADAS Y POR RANGO ==========

  Future<void> _tryZonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationDetails details,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (!_timeZoneInitialized) {
      tz_data.initializeTimeZones();
      _timeZoneInitialized = true;
    }
    final location = tz.local;
    final tzScheduled = tz.TZDateTime.from(scheduledDate, location);
    final tzNow = tz.TZDateTime.now(location);
    print('[Debug TZ] tzNow: $tzNow | tzScheduled: $tzScheduled');

    tz.TZDateTime safeScheduled = tzScheduled;
    if (!tzScheduled.isAfter(tzNow)) {
      safeScheduled = tzScheduled.add(const Duration(days: 1));
      print(
        '[Notificaciones] La fecha programada estaba en el pasado/presente. Se ajustÃ³ automÃ¡ticamente: $safeScheduled',
      );
    }
    if (!safeScheduled.isAfter(tzNow)) {
      print(
        '[Notificaciones][ERROR] No se puede programar la notificaciÃ³n (ID: $id) porque la fecha es pasada: $safeScheduled',
      );
      return;
    }

    // ----------- FILTRO POR RANGO ANTES DE PROGRAMAR -------------
    if (!_estaDentroDeRango(safeScheduled)) {
      print(
        '[Notificaciones][SKIP] Fecha $safeScheduled fuera de rango, no se programa.',
      );
      return;
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: safeScheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
      matchDateTimeComponents: matchDateTimeComponents,
    );

    print('[Notificaciones] NotificaciÃ³n programada para: $safeScheduled');
  }

  // ===================== PROGRAMAR NOTIFICACIONES =====================

  Future<void> showTestNotification() async {
    print('Notificacion Instantanea ');
    final now = DateTime.now();
    final nowUtc = DateTime.now().toUtc();
    print('[Debug Hora] Local: $now - UTC: $nowUtc');
    final programadaPara = now.add(const Duration(minutes: 2));
    print(
      '[Debug Programada] Local: $programadaPara - UTC: ${programadaPara.toUtc()}',
    );
    await flutterLocalNotificationsPlugin.show(
      id: 99999,
      title: 'Pocket Plan',
      body: 'Â¡Esta es una notificaciÃ³n de prueba!',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Pruebas',
          channelDescription: 'Canal de pruebas instantÃ¡neas',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
          priority: Priority.high,
        ),
      ),
      payload: 'registro',
    );
  }

  Future<void> showAutoMovementNotification({
    required String tipo,
    required double monto,
  }) async {
    final isIngreso = tipo.toLowerCase() == 'ingreso';
    final title = 'Movimiento registrado';
    final body =
        '${isIngreso ? 'Ingreso' : 'Gasto'} de Q${monto.toStringAsFixed(2)}';

    await flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'auto_movimientos',
          'Movimientos AutomÃ¡ticos',
          channelDescription:
              'Notificaciones por movimientos detectados en SMS',
          importance: Importance.high,
          priority: Priority.high,
          channelShowBadge: true,
        ),
      ),
    );
  }

  Future<void> programarNotificacionPruebaProgramada() async {
    print('Notificacion Programada');
    final now = DateTime.now();
    final nowUtc = DateTime.now().toUtc();
    print('[Debug Hora] Local: $now - UTC: $nowUtc');
    final programadaPara = now.add(const Duration(minutes: 2));
    print(
      '[Debug Programada] Local: $programadaPara - UTC: ${programadaPara.toUtc()}',
    );

    await _tryZonedSchedule(
      id: 123456,
      title: 'Pocket Plan (Prueba programada)',
      body: 'NotificaciÃ³n programada de prueba para dentro de 10 segundos.',
      scheduledDate: programadaPara,
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Pruebas',
          channelDescription: 'Canal de pruebas instantÃ¡neas',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
          priority: Priority.high,
        ),
      ),
      payload: 'login_test',
    );
  }

  Future<void> programarNotificacionPruebaRapida() async {
    print('Notificacion Programada Rapida ');
    final now = DateTime.now();
    final programadaPara = now.add(const Duration(minutes: 2));
    print(
      '[Debug Programada] Local: $programadaPara - UTC: ${programadaPara.toUtc()}',
    );

    await NotificationService()._tryZonedSchedule(
      id: 123457,
      title: 'Prueba RÃ¡pida',
      body: 'NotificaciÃ³n programada para 20 segundos despuÃ©s.',
      scheduledDate: programadaPara,
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Pruebas',
          channelDescription: 'Canal de pruebas instantÃ¡neas',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
          priority: Priority.high,
        ),
      ),
      payload: 'login_test',
    );
  }

  // --- DIARIA, siempre se programa ---
  Future<void> scheduleDailyTransactionReminder({
    required int hour,
    required int minute,
    int notificationId = 101,
  }) async {
    await _tryZonedSchedule(
      id: notificationId,
      title: 'Pocket Plan',
      body:
          'Â¡Recuerda registrar tus ingresos y egresos de hoy para llevar un buen control de tus finanzas! ðŸ“’ðŸ’¡',
      scheduledDate: _nextInstanceOfTime(hour, minute),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'registro_transacciones',
          'Registro Diario',
          channelDescription: 'Recordatorio diario para registrar movimientos',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
          priority: Priority.high,
        ),
      ),
      payload: 'registro',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // --- AHORRO ---
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
      if (_estaDentroDeRango(fecha)) {
        await scheduleAhorroReminder(
          id: baseId + i + 1,
          ahorroId: ahorro.id!,
          userId: userId,
          objetivo: ahorro.objetivo,
          fechaProximoPago: fecha,
          pagosRestantes: totalPagos - i,
          periodo: periodo,
          hour: 8,
          minute: 0,
        );
        await scheduleAhorroReminderToday(
          idBase: baseId + i + 1,
          ahorroId: ahorro.id!,
          userId: userId,
          objetivo: ahorro.objetivo,
          fechaPago: fecha,
          pagosRestantes: totalPagos - i,
          periodo: periodo,
          hour: 9,
          minute: 0,
          extra: 0,
        );
        await scheduleAhorroReminderToday(
          idBase: baseId + i + 1,
          ahorroId: ahorro.id!,
          userId: userId,
          objetivo: ahorro.objetivo,
          fechaPago: fecha,
          pagosRestantes: totalPagos - i,
          periodo: periodo,
          hour: 15,
          minute: 0,
          extra: 1,
        );
      } else {
        print(
          '[Notificaciones][SKIP] Fecha de pago $fecha fuera de rango, no se programa.',
        );
      }
    }
  }

  Future<void> scheduleAhorroReminder({
    required int id,
    required int ahorroId,
    required int userId,
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
          'Â¡Recuerda! MaÃ±ana te toca ahorrar para "$objetivo".\nTe quedan $pagosRestantes pago(s) para alcanzar tu meta. ($friendlyDate)',
      scheduledDate: _nextInstanceOfDate(hour, minute, notificationDate),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'simulador_ahorro',
          'Simulador de Ahorro',
          channelDescription: 'Recordatorio para simuladores de ahorro',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
          priority: Priority.high,
        ),
      ),
      payload: 'ahorro:$ahorroId:$userId:manana',
    );
  }

  Future<void> scheduleAhorroReminderToday({
    required int idBase,
    required int ahorroId,
    required int userId,
    required String objetivo,
    required DateTime fechaPago,
    required int pagosRestantes,
    required String periodo,
    required int hour,
    required int minute,
    int extra = 0,
  }) async {
    await _tryZonedSchedule(
      id: idBase + 10000 + extra,
      title: 'Pocket Plan',
      body:
          'Â¡Hoy es el dÃ­a para ahorrar en tu meta "$objetivo"! Solo te quedan $pagosRestantes pago(s) para culminar tu objetivo. No pierdas el ritmo, Â¡tÃº puedes lograrlo! ðŸš€',
      scheduledDate: _nextInstanceOfDate(hour, minute, fechaPago),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'simulador_ahorro',
          'Simulador de Ahorro',
          channelDescription: 'Recordatorio para simuladores de ahorro',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
          priority: Priority.high,
        ),
      ),
      payload: 'ahorro:$ahorroId:$userId:hoy',
    );
  }

  // --- DEUDA ---
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
      if (_estaDentroDeRango(fecha)) {
        await scheduleDeudaReminder(
          id: baseId + i + 1,
          deudaId: deuda.id!,
          userId: userId,
          motivo: deuda.motivo,
          fechaProximoPago: fecha,
          pagosRestantes: totalPagos - i,
          periodo: periodo,
          hour: 8,
          minute: 0,
        );
        await scheduleDeudaReminderToday(
          idBase: baseId + i + 1,
          deudaId: deuda.id!,
          userId: userId,
          motivo: deuda.motivo,
          fechaPago: fecha,
          pagosRestantes: totalPagos - i,
          periodo: periodo,
          hour: 9,
          minute: 0,
          extra: 0,
        );
        await scheduleDeudaReminderToday(
          idBase: baseId + i + 1,
          deudaId: deuda.id!,
          userId: userId,
          motivo: deuda.motivo,
          fechaPago: fecha,
          pagosRestantes: totalPagos - i,
          periodo: periodo,
          hour: 15,
          minute: 0,
          extra: 1,
        );
      } else {
        print(
          '[Notificaciones][SKIP] Fecha de pago $fecha fuera de rango, no se programa.',
        );
      }
    }
  }

  Future<void> scheduleDeudaReminder({
    required int id,
    required int deudaId,
    required int userId,
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
          'Â¡Recuerda! MaÃ±ana tienes que realizar un pago por tu deuda "$motivo".\nTe quedan $pagosRestantes pago(s) para finalizar. ($friendlyDate)',
      scheduledDate: _nextInstanceOfDate(hour, minute, notificationDate),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'simulador_deuda',
          'Simulador de Deuda',
          channelDescription: 'Recordatorio para simuladores de deuda',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
          priority: Priority.high,
        ),
      ),
      payload: 'deuda:$deudaId:$userId:manana',
    );
  }

  Future<void> scheduleDeudaReminderToday({
    required int idBase,
    required int deudaId,
    required int userId,
    required String motivo,
    required DateTime fechaPago,
    required int pagosRestantes,
    required String periodo,
    required int hour,
    required int minute,
    int extra = 0,
  }) async {
    await _tryZonedSchedule(
      id: idBase + 10000 + extra,
      title: 'Pocket Plan',
      body:
          'Â¡Hoy es el dÃ­a para realizar tu pago de la deuda "$motivo"! Solo te quedan $pagosRestantes pago(s) para terminar. Mantente al dÃ­a y evita recargos. ðŸ’¸',
      scheduledDate: _nextInstanceOfDate(hour, minute, fechaPago),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'simulador_deuda',
          'Simulador de Deuda',
          channelDescription: 'Recordatorio para simuladores de deuda',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
          priority: Priority.high,
        ),
      ),
      payload: 'deuda:$deudaId:$userId:hoy',
    );
  }

  // --------- 4. Tarjeta de CrÃ©dito (pago, corte, expiraciÃ³n, ambos dÃ­as) ---------
  Future<void> scheduleCreditCardNotifications(
    CreditCard tarjeta,
    int userId,
  ) async {
    final int pagoBase = (tarjeta.id ?? 50000 + userId) * 10;
    final int corteBase = (tarjeta.id ?? 60000 + userId) * 10;
    final int expBase = (tarjeta.id ?? 70000 + userId) * 10;

    // PAGO
    int? diaPago = int.tryParse(tarjeta.pago);
    if (diaPago != null) {
      DateTime fechaPago = _proximoDiaDelMes(diaPago);
      if (_estaDentroDeRango(fechaPago)) {
        await scheduleCreditCardPaymentReminder(
          id: pagoBase + 1,
          tarjetaId: tarjeta.id!,
          userId: userId,
          banco: tarjeta.banco,
          nombrePropietario: tarjeta.alias,
          fechaPago: fechaPago,
          hour: 8,
          minute: 0,
        );
        await scheduleCreditCardPaymentToday(
          idBase: pagoBase + 1,
          tarjetaId: tarjeta.id!,
          userId: userId,
          banco: tarjeta.banco,
          propietario: tarjeta.alias,
          fechaPago: fechaPago,
          hour: 9,
          minute: 0,
          extra: 0,
        );
        await scheduleCreditCardPaymentToday(
          idBase: pagoBase + 1,
          tarjetaId: tarjeta.id!,
          userId: userId,
          banco: tarjeta.banco,
          propietario: tarjeta.alias,
          fechaPago: fechaPago,
          hour: 15,
          minute: 0,
          extra: 1,
        );
      } else {
        print(
          '[Notificaciones][SKIP] Fecha de pago de tarjeta crÃ©dito $fechaPago fuera de rango.',
        );
      }
    }

    // CORTE
    int? diaCorte = int.tryParse(tarjeta.corte);
    if (diaCorte != null) {
      DateTime fechaCorte = _proximoDiaDelMes(diaCorte);
      if (_estaDentroDeRango(fechaCorte)) {
        await scheduleCreditCardCorteReminder(
          id: corteBase + 1,
          tarjetaId: tarjeta.id!,
          userId: userId,
          banco: tarjeta.banco,
          nombrePropietario: tarjeta.alias,
          fechaCorte: fechaCorte,
          hour: 8,
          minute: 0,
        );
        await scheduleCreditCardCorteToday(
          idBase: corteBase + 1,
          tarjetaId: tarjeta.id!,
          userId: userId,
          banco: tarjeta.banco,
          propietario: tarjeta.alias,
          fechaCorte: fechaCorte,
          hour: 9,
          minute: 0,
          extra: 0,
        );
        await scheduleCreditCardCorteToday(
          idBase: corteBase + 1,
          tarjetaId: tarjeta.id!,
          userId: userId,
          banco: tarjeta.banco,
          propietario: tarjeta.alias,
          fechaCorte: fechaCorte,
          hour: 15,
          minute: 0,
          extra: 1,
        );
      } else {
        print(
          '[Notificaciones][SKIP] Fecha de corte de tarjeta crÃ©dito $fechaCorte fuera de rango.',
        );
      }
    }

    // EXPIRACIÃ“N
    DateTime? fechaExp = _fechaExpiracion(tarjeta.expiracion);
    if (fechaExp != null &&
        fechaExp.isAfter(DateTime.now()) &&
        _estaDentroDeRango(fechaExp)) {
      await scheduleCardExpirationReminder(
        id: expBase + 1,
        tarjetaId: tarjeta.id!,
        userId: userId,
        tipoTarjeta: 'CrÃ©dito',
        banco: tarjeta.banco,
        nombrePropietario: tarjeta.alias,
        fechaExpiracion: fechaExp,
        hour: 8,
        minute: 0,
      );
      await scheduleCardExpirationToday(
        idBase: expBase + 1,
        tarjetaId: tarjeta.id!,
        userId: userId,
        tipo: 'CrÃ©dito',
        banco: tarjeta.banco,
        propietario: tarjeta.alias,
        fechaExpiracion: fechaExp,
        hour: 9,
        minute: 0,
        extra: 0,
      );
      await scheduleCardExpirationToday(
        idBase: expBase + 1,
        tarjetaId: tarjeta.id!,
        userId: userId,
        tipo: 'CrÃ©dito',
        banco: tarjeta.banco,
        propietario: tarjeta.alias,
        fechaExpiracion: fechaExp,
        hour: 15,
        minute: 0,
        extra: 1,
      );
    } else {
      print(
        '[Notificaciones][SKIP] Fecha de expiraciÃ³n de tarjeta crÃ©dito $fechaExp fuera de rango.',
      );
    }
  }

  Future<void> scheduleCreditCardPaymentReminder({
    required int id,
    required int tarjetaId,
    required int userId,
    required String banco,
    required String nombrePropietario,
    required DateTime fechaPago,
    required int hour,
    required int minute,
  }) async {
    final notificationDate = fechaPago.subtract(const Duration(days: 1));
    await _tryZonedSchedule(
      id: id,
      title: 'Pocket Plan',
      body:
          'MaÃ±ana es la fecha de pago de tu tarjeta de crÃ©dito en $banco.\nPropietario: $nombrePropietario.\nEvita cargos extra y mantÃ©n tu crÃ©dito al dÃ­a.',
      scheduledDate: _nextInstanceOfDate(hour, minute, notificationDate),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'pago_tarjeta',
          'Pago Tarjeta de CrÃ©dito',
          channelDescription: 'Recordatorio de pago de tarjeta de crÃ©dito',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
          priority: Priority.high,
        ),
      ),
      payload: 'tarjeta_credito:$tarjetaId:$userId:pago_manana',
    );
  }

  Future<void> scheduleCreditCardPaymentToday({
    required int idBase,
    required int tarjetaId,
    required int userId,
    required String banco,
    required String propietario,
    required DateTime fechaPago,
    required int hour,
    required int minute,
    int extra = 0,
  }) async {
    await _tryZonedSchedule(
      id: idBase + 10000 + extra,
      title: 'Pocket Plan',
      body:
          'Â¡Hoy es tu fecha de pago de la tarjeta de crÃ©dito "$banco" ($propietario)! Recuerda mantenerte al dÃ­a para evitar intereses.',
      scheduledDate: _nextInstanceOfDate(hour, minute, fechaPago),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'tarjeta_credito_pago',
          'Pago de Tarjeta de CrÃ©dito',
          channelDescription: 'Recordatorio de pago de tarjeta de crÃ©dito',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
          priority: Priority.high,
        ),
      ),
      payload: 'tarjeta_credito:$tarjetaId:$userId:pago_hoy',
    );
  }

  Future<void> scheduleCreditCardCorteReminder({
    required int id,
    required int tarjetaId,
    required int userId,
    required String banco,
    required String nombrePropietario,
    required DateTime fechaCorte,
    required int hour,
    required int minute,
  }) async {
    final notificationDate = fechaCorte.subtract(const Duration(days: 1));
    await _tryZonedSchedule(
      id: id,
      title: 'Pocket Plan',
      body:
          'Â¡AtenciÃ³n! MaÃ±ana es la fecha de corte de tu tarjeta de crÃ©dito en $banco.\nPropietario: $nombrePropietario.\nRecuerda que tu saldo se actualizarÃ¡.',
      scheduledDate: _nextInstanceOfDate(hour, minute, notificationDate),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'tarjeta_credito_corte',
          'Corte Tarjeta de CrÃ©dito',
          channelDescription: 'Recordatorio de corte de tarjeta de crÃ©dito',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
          priority: Priority.high,
        ),
      ),
      payload: 'tarjeta_credito:$tarjetaId:$userId:corte_manana',
    );
  }

  Future<void> scheduleCreditCardCorteToday({
    required int idBase,
    required int tarjetaId,
    required int userId,
    required String banco,
    required String propietario,
    required DateTime fechaCorte,
    required int hour,
    required int minute,
    int extra = 0,
  }) async {
    await _tryZonedSchedule(
      id: idBase + 10000 + extra,
      title: 'Pocket Plan',
      body:
          'Â¡Hoy es tu fecha de corte de la tarjeta "$banco" ($propietario)! Se actualizarÃ¡ tu saldo, asegÃºrate de estar solvente.',
      scheduledDate: _nextInstanceOfDate(hour, minute, fechaCorte),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'tarjeta_credito_corte',
          'Corte de Tarjeta de CrÃ©dito',
          channelDescription:
              'Recordatorio de fecha de corte de tarjeta de crÃ©dito',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
          priority: Priority.high,
        ),
      ),
      payload: 'tarjeta_credito:$tarjetaId:$userId:corte_hoy',
    );
  }

  Future<void> scheduleCardExpirationReminder({
    required int id,
    required int tarjetaId,
    required int userId,
    required String tipoTarjeta,
    required String banco,
    required String nombrePropietario,
    required DateTime fechaExpiracion,
    required int hour,
    required int minute,
  }) async {
    final notificationDate = fechaExpiracion.subtract(const Duration(days: 1));
    await _tryZonedSchedule(
      id: id,
      title: 'Pocket Plan',
      body:
          'Â¡Importante! MaÃ±ana es la fecha de expiraciÃ³n de tu tarjeta $tipoTarjeta en $banco.\nPropietario: $nombrePropietario. Considera renovarla para seguir usando tus servicios.',
      scheduledDate: _nextInstanceOfDate(hour, minute, notificationDate),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiracion_tarjeta',
          'ExpiraciÃ³n de Tarjeta',
          channelDescription: 'Recordatorio de expiraciÃ³n de tarjetas',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
          priority: Priority.high,
        ),
      ),
      payload:
          tipoTarjeta.toLowerCase() == 'crÃ©dito'
              ? 'tarjeta_credito:$tarjetaId:$userId:expira_manana'
              : 'tarjeta_debito:$tarjetaId:$userId:expira_manana',
    );
  }

  Future<void> scheduleCardExpirationToday({
    required int idBase,
    required int tarjetaId,
    required int userId,
    required String tipo,
    required String banco,
    required String propietario,
    required DateTime fechaExpiracion,
    required int hour,
    required int minute,
    int extra = 0,
  }) async {
    await _tryZonedSchedule(
      id: idBase + 10000 + extra,
      title: 'Pocket Plan',
      body:
          'Â¡Hoy es la fecha de expiraciÃ³n de tu tarjeta $tipo "$banco" ($propietario)! Recuerda renovarla para seguir usÃ¡ndola.',
      scheduledDate: _nextInstanceOfDate(hour, minute, fechaExpiracion),
      details: NotificationDetails(
        android: AndroidNotificationDetails(
          tipo.toLowerCase() == 'crÃ©dito'
              ? 'tarjeta_credito_expiracion'
              : 'tarjeta_debito_expiracion',
          tipo.toLowerCase() == 'crÃ©dito'
              ? 'ExpiraciÃ³n de Tarjeta de CrÃ©dito'
              : 'ExpiraciÃ³n de Tarjeta de DÃ©bito',
          channelDescription: 'Recordatorio de expiraciÃ³n de tarjeta',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
          priority: Priority.high,
        ),
      ),
      payload:
          tipo.toLowerCase() == 'crÃ©dito'
              ? 'tarjeta_credito:$tarjetaId:$userId:expira_hoy'
              : 'tarjeta_debito:$tarjetaId:$userId:expira_hoy',
    );
  }

  // --------- 5. Tarjeta de DÃ©bito ---------
  Future<void> scheduleDebitCardNotifications(
    DebitCard tarjeta,
    int userId,
  ) async {
    final int expBase = (tarjeta.id ?? 80000 + userId) * 10;
    DateTime fechaExpiracion = parseExpirationDate(tarjeta.expiracion);

    if (_estaDentroDeRango(fechaExpiracion)) {
      await scheduleCardExpirationReminder(
        id: expBase + 1,
        tarjetaId: tarjeta.id!,
        userId: userId,
        tipoTarjeta: 'DÃ©bito',
        banco: tarjeta.banco,
        nombrePropietario: tarjeta.alias,
        fechaExpiracion: fechaExpiracion,
        hour: 8,
        minute: 0,
      );
      await scheduleCardExpirationToday(
        idBase: expBase + 1,
        tarjetaId: tarjeta.id!,
        userId: userId,
        tipo: 'DÃ©bito',
        banco: tarjeta.banco,
        propietario: tarjeta.alias,
        fechaExpiracion: fechaExpiracion,
        hour: 8,
        minute: 0,
      );
    } else {
      print(
        '[Notificaciones][SKIP] Fecha de expiraciÃ³n de tarjeta dÃ©bito $fechaExpiracion fuera de rango, no se programa.',
      );
    }
  }

  // ===================== UTILIDADES =====================

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

  DateTime _proximoDiaDelMes(int dia) {
    final now = DateTime.now();
    int mes = now.month;
    int anio = now.year;
    if (now.day >= dia) {
      mes++;
      if (mes > 12) {
        mes = 1;
        anio++;
      }
    }
    int ultimoDia = DateTime(anio, mes + 1, 0).day;
    if (dia > ultimoDia) dia = ultimoDia;
    return DateTime(anio, mes, dia);
  }

  DateTime? _fechaExpiracion(String exp) {
    try {
      final parts = exp.contains('-') ? exp.split('-') : exp.split('/');
      int mes, anio;
      if (parts[0].length == 4) {
        anio = int.parse(parts[0]);
        mes = int.parse(parts[1]);
      } else {
        mes = int.parse(parts[0]);
        anio = int.parse(parts[1]);
      }
      int ultimoDia = DateTime(anio, mes + 1, 0).day;
      return DateTime(anio, mes, ultimoDia);
    } catch (_) {
      return null;
    }
  }

  DateTime parseExpirationDate(String expiracion) {
    try {
      if (RegExp(r'^\d{2}/\d{2}$').hasMatch(expiracion)) {
        final parts = expiracion.split('/');
        final month = int.parse(parts[0]);
        final year = 2000 + int.parse(parts[1]);
        return DateTime(year, month + 1, 0);
      }
      if (RegExp(r'^\d{2}-\d{4}$').hasMatch(expiracion)) {
        final parts = expiracion.split('-');
        final month = int.parse(parts[0]);
        final year = int.parse(parts[1]);
        return DateTime(year, month + 1, 0);
      }
      if (RegExp(r'^\d{4}-\d{2}$').hasMatch(expiracion)) {
        final parts = expiracion.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        return DateTime(year, month + 1, 0);
      }
      if (RegExp(r'^\d{2}/\d{4}$').hasMatch(expiracion)) {
        final parts = expiracion.split('/');
        final month = int.parse(parts[0]);
        final year = int.parse(parts[1]);
        return DateTime(year, month + 1, 0);
      }
    } catch (_) {}
    throw FormatException(
      "Formato de expiraciÃ³n invÃ¡lido: $expiracion. Usa MM/yy, MM-yyyy, yyyy-MM, o MM/yyyy",
    );
  }

  // ===================== CANCELAR NOTIFICACIONES =====================
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelAhorroNotifications(int ahorroId, int userId) async {
    final int baseId = (ahorroId ?? 10000 + userId) * 10;
    await cancelNotification(baseId + 1); // un dÃ­a antes
    await cancelNotification(baseId + 1 + 10000); // Hoy 9am
    await cancelNotification(baseId + 1 + 10001); // Hoy 3pm
  }

  Future<void> cancelAhorroNotificationsForSimulador(
    SimuladorAhorro ahorro,
    int userId,
  ) async {
    if (ahorro.id == null) return;
    final int baseId = (ahorro.id ?? 10000 + userId) * 10;
    final int totalPagos = _calcularPagosTotales(ahorro);
    for (int i = 0; i < totalPagos; i++) {
      final int notifId = baseId + i + 1;
      await cancelNotification(notifId); // un dÃ­a antes
      await cancelNotification(notifId + 10000); // Hoy 9am
      await cancelNotification(notifId + 10001); // Hoy 3pm
    }
  }

  Future<void> cancelDeudaNotifications(int deudaId, int userId) async {
    final int baseId = (deudaId ?? 30000 + userId) * 10;
    // Un dÃ­a antes
    await cancelNotification(baseId + 1);

    // Mero dÃ­a (9am y 3pm, extra: 0 y extra: 1)
    await cancelNotification(baseId + 1 + 10000); // 9am
    await cancelNotification(baseId + 1 + 10001); // 3pm
  }

  Future<void> cancelDeudaNotificationsForSimulador(
    SimuladorDeuda deuda,
    int userId,
  ) async {
    if (deuda.id == null) return;
    final int baseId = (deuda.id ?? 30000 + userId) * 10;
    final int totalPagos = _calcularPagosTotalesDeuda(deuda);
    for (int i = 0; i < totalPagos; i++) {
      final int notifId = baseId + i + 1;
      await cancelNotification(notifId); // un dÃ­a antes
      await cancelNotification(notifId + 10000); // 9am
      await cancelNotification(notifId + 10001); // 3pm
    }
  }

  Future<void> cancelCreditCardNotifications(int tarjetaId, int userId) async {
    // Pago
    final int pagoBase = (tarjetaId ?? 50000 + userId) * 10;
    await cancelNotification(pagoBase + 1); // Un dÃ­a antes
    await cancelNotification(pagoBase + 1 + 10000); // Hoy 9am
    await cancelNotification(pagoBase + 1 + 10001); // Hoy 3pm

    // Corte
    final int corteBase = (tarjetaId ?? 60000 + userId) * 10;
    await cancelNotification(corteBase + 1); // Un dÃ­a antes
    await cancelNotification(corteBase + 1 + 10000); // Hoy 9am
    await cancelNotification(corteBase + 1 + 10001); // Hoy 3pm

    // ExpiraciÃ³n
    final int expBase = (tarjetaId ?? 70000 + userId) * 10;
    await cancelNotification(expBase + 1); // Un dÃ­a antes
    await cancelNotification(expBase + 1 + 10000); // Hoy 9am
    await cancelNotification(expBase + 1 + 10001); // Hoy 3pm
  }

  Future<void> cancelDebitCardNotifications(int tarjetaId, int userId) async {
    final int expBase = (tarjetaId ?? 80000 + userId) * 10;
    await cancelNotification(expBase + 1); // Un dÃ­a antes
    await cancelNotification(expBase + 1 + 10000); // Hoy 9am
    await cancelNotification(expBase + 1 + 10001); // Hoy 3pm
  }
}
