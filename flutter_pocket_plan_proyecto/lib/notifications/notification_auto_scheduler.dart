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

  /// Programa solo la notificación diaria
  Future<void> programarNotificacionDiaria(int userId) async {
    print(
      '📆 [Notificaciones][DIARIA] Iniciando programación de notificaciones diarias...',
    );
    try {
      await NotificationService().scheduleDailyTransactionReminder(
        hour: 10,
        minute: 0,
        notificationId: 101,
      );
      print(
        '✅ [Notificaciones][DIARIA] Notificación diaria 1 (10:00 AM) programada.',
      );
      await NotificationService().scheduleDailyTransactionReminder(
        hour: 15,
        minute: 30,
        notificationId: 102,
      );
      print(
        '✅ [Notificaciones][DIARIA] Notificación diaria 2 (3:30 PM) programada.',
      );
    } catch (e, st) {
      print(
        '❌ [Notificaciones][DIARIA] Error programando notificaciones diarias: $e',
      );
      print('🔎 [Notificaciones][DIARIA] StackTrace:\n$st');
    }
  }

  /// Programa todas las notificaciones de simuladores de ahorro
  Future<void> programarNotificacionesAhorro(int userId) async {
    print(
      '💰 [Notificaciones][AHORRO] Iniciando programación de notificaciones de ahorro...',
    );
    try {
      final ahorros = await ahorroRepo.getSimuladoresAhorroByUser(userId);
      if (ahorros.isEmpty) {
        print(
          '⚠️ [Notificaciones][AHORRO] No hay simuladores de ahorro para este usuario.',
        );
      }
      for (final ahorro in ahorros) {
        try {
          await NotificationService().scheduleAhorroNotifications(
            ahorro,
            userId,
          );
          print(
            '✅ [Notificaciones][AHORRO] Notificaciones programadas para ahorro: ${ahorro.objetivo}',
          );
        } catch (e, st) {
          print(
            '❌ [Notificaciones][AHORRO] Error programando notificaciones para "${ahorro.objetivo}": $e',
          );
          print('🔎 [Notificaciones][AHORRO] StackTrace:\n$st');
        }
      }
    } catch (e, st) {
      print(
        '❌ [Notificaciones][AHORRO] Error general programando notificaciones de ahorro: $e',
      );
      print('🔎 [Notificaciones][AHORRO] StackTrace:\n$st');
    }
  }

  /// Programa todas las notificaciones de simuladores de deuda
  Future<void> programarNotificacionesDeuda(int userId) async {
    print(
      '💸 [Notificaciones][DEUDA] Iniciando programación de notificaciones de deuda...',
    );
    try {
      final deudas = await deudaRepo.getSimuladoresDeudaByUser(userId);
      if (deudas.isEmpty) {
        print(
          '⚠️ [Notificaciones][DEUDA] No hay simuladores de deuda para este usuario.',
        );
      }
      for (final deuda in deudas) {
        try {
          await NotificationService().scheduleDeudaNotifications(deuda, userId);
          print(
            '✅ [Notificaciones][DEUDA] Notificaciones programadas para deuda: ${deuda.motivo}',
          );
        } catch (e, st) {
          print(
            '❌ [Notificaciones][DEUDA] Error programando notificaciones para "${deuda.motivo}": $e',
          );
          print('🔎 [Notificaciones][DEUDA] StackTrace:\n$st');
        }
      }
    } catch (e, st) {
      print(
        '❌ [Notificaciones][DEUDA] Error general programando notificaciones de deuda: $e',
      );
      print('🔎 [Notificaciones][DEUDA] StackTrace:\n$st');
    }
  }

  /// Programa todas las notificaciones de tarjetas (crédito y débito)
  Future<void> programarNotificacionesTarjetas(int userId) async {
    // CRÉDITO
    print(
      '💳 [Notificaciones][TARJETAS] Iniciando programación de notificaciones de tarjetas de CRÉDITO...',
    );
    try {
      final tarjetasCredito = await creditoRepo.getTarjetasCreditoByUser(
        userId,
      );
      if (tarjetasCredito.isEmpty) {
        print(
          '⚠️ [Notificaciones][TARJETAS] No hay tarjetas de crédito para este usuario.',
        );
      }
      for (final tarjeta in tarjetasCredito) {
        try {
          await NotificationService().scheduleCreditCardNotifications(
            tarjeta,
            userId,
          );
          print(
            '✅ [Notificaciones][TARJETAS] Notificaciones programadas para tarjeta crédito: ${tarjeta.alias}',
          );
        } catch (e, st) {
          print(
            '❌ [Notificaciones][TARJETAS] Error programando notificaciones para crédito "${tarjeta.alias}": $e',
          );
          print('🔎 [Notificaciones][TARJETAS][CRÉDITO] StackTrace:\n$st');
        }
      }
    } catch (e, st) {
      print(
        '❌ [Notificaciones][TARJETAS] Error general programando notificaciones de tarjetas de crédito: $e',
      );
      print('🔎 [Notificaciones][TARJETAS][CRÉDITO] StackTrace:\n$st');
    }

    // DÉBITO
    print(
      '💳 [Notificaciones][TARJETAS] Iniciando programación de notificaciones de tarjetas de DÉBITO...',
    );
    try {
      final tarjetasDebito = await debitoRepo.getTarjetasDebitoByUser(userId);
      if (tarjetasDebito.isEmpty) {
        print(
          '⚠️ [Notificaciones][TARJETAS] No hay tarjetas de débito para este usuario.',
        );
      }
      for (final tarjeta in tarjetasDebito) {
        try {
          await NotificationService().scheduleDebitCardNotifications(
            tarjeta,
            userId,
          );
          print(
            '✅ [Notificaciones][TARJETAS] Notificaciones programadas para tarjeta débito: ${tarjeta.alias}',
          );
        } catch (e, st) {
          print(
            '❌ [Notificaciones][TARJETAS] Error programando notificaciones para débito "${tarjeta.alias}": $e',
          );
          print('🔎 [Notificaciones][TARJETAS][DÉBITO] StackTrace:\n$st');
        }
      }
    } catch (e, st) {
      print(
        '❌ [Notificaciones][TARJETAS] Error general programando notificaciones de tarjetas de débito: $e',
      );
      print('🔎 [Notificaciones][TARJETAS][DÉBITO] StackTrace:\n$st');
    }
  }

  /// Programa todas las notificaciones relevantes para el usuario (centralizado)
  Future<void> programarNotificacionesDeUsuario(int userId) async {
    await NotificationService().cancelAll(); // Limpia antes de reprogramar

    await programarNotificacionDiaria(userId);
    await programarNotificacionesAhorro(userId);
    await programarNotificacionesDeuda(userId);
    await programarNotificacionesTarjetas(userId);
  }
}
