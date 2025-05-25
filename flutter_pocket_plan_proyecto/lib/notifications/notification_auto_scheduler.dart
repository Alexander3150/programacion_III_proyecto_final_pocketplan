import '../../notifications/notification_service.dart';
import '../data/models/repositories/simulador_ahorro_repository.dart';
import '../data/models/repositories/simulador_deuda_repository.dart';
import '../data/models/repositories/tarjeta_credito_repository.dart';
import '../data/models/repositories/tarjeta_debito_repository.dart';

class NotificationAutoScheduler {
  final SimuladorAhorroRepository ahorroRepo;
  final SimuladorDeudaRepository deudaRepo;
  final TarjetaCreditoRepository creditoRepo;
  final TarjetaDebitoRepository debitoRepo;

  NotificationAutoScheduler({
    required this.ahorroRepo,
    required this.deudaRepo,
    required this.creditoRepo,
    required this.debitoRepo,
  });

  /// Programa todas las notificaciones relevantes para el usuario.
  Future<void> programarNotificacionesDeUsuario(int userId) async {
    // Siempre inicializa el servicio antes de usarlo (idempotente)
    await NotificationService().init();

    // Cancela todas las notificaciones antes para evitar duplicados
    await NotificationService().cancelAll();

    // 1. Recordatorio diario de ingresos/egresos (10:00 AM y 4:00 PM)
    await NotificationService().scheduleDailyTransactionReminder(
      hour: 10,
      minute: 0,
      notificationId: 101,
    );
    await NotificationService().scheduleDailyTransactionReminder(
      hour: 16,
      minute: 0,
      notificationId: 102,
    );

    // 2. Simuladores de Ahorro
    final ahorros = await ahorroRepo.getSimuladoresAhorroByUser(userId);
    for (final ahorro in ahorros) {
      try {
        await NotificationService().scheduleAhorroNotifications(ahorro, userId);
      } catch (e, st) {
        print('Error programando notificaciones de ahorro: $e\n$st');
      }
    }

    // 3. Simuladores de Deuda
    final deudas = await deudaRepo.getSimuladoresDeudaByUser(userId);
    for (final deuda in deudas) {
      try {
        await NotificationService().scheduleDeudaNotifications(deuda, userId);
      } catch (e, st) {
        print('Error programando notificaciones de deuda: $e\n$st');
      }
    }

    // 4. Tarjetas de Crédito
    final tarjetasCredito = await creditoRepo.getTarjetasCreditoByUser(userId);
    for (final tarjeta in tarjetasCredito) {
      try {
        await NotificationService().scheduleCreditCardNotifications(
          tarjeta,
          userId,
        );
      } catch (e, st) {
        print('Error programando notificaciones de tarjeta crédito: $e\n$st');
      }
    }

    // 5. Tarjetas de Débito
    final tarjetasDebito = await debitoRepo.getTarjetasDebitoByUser(userId);
    for (final tarjeta in tarjetasDebito) {
      try {
        await NotificationService().scheduleDebitCardNotifications(
          tarjeta,
          userId,
        );
      } catch (e, st) {
        print('Error programando notificaciones de tarjeta débito: $e\n$st');
      }
    }
  }
}
