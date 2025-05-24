import 'package:flutter_pocket_plan_proyecto/data/models/credit_card_model.dart'
    show CreditCard;
import 'package:sqflite/sqflite.dart';

import '../../../core/database/bd_implementation.dart';

class TarjetaCreditoRepository {
  final dbHelper = DatabaseHelper();

  Future<int> insertTarjetaCredito(CreditCard card) async {
    final db = await dbHelper.database;
    return await db.insert(
      DatabaseHelper.creditCardTable,
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CreditCard>> getTarjetasCreditoByUser(int userId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.creditCardTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => CreditCard.fromMap(maps[i]));
  }

  Future<CreditCard?> getTarjetaCreditoById(int id, int userId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.creditCardTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    if (maps.isNotEmpty) return CreditCard.fromMap(maps.first);
    return null;
  }

  Future<int> updateTarjetaCredito(CreditCard card) async {
    final db = await dbHelper.database;
    return await db.update(
      DatabaseHelper.creditCardTable,
      card.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [card.id, card.userId],
    );
  }

  Future<int> deleteTarjetaCredito(int id, int userId) async {
    final db = await dbHelper.database;
    return await db.delete(
      DatabaseHelper.creditCardTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<int> actualizarSaldoTarjeta(int id, double saldo, int userId) async {
    final db = await dbHelper.database;
    return await db.update(
      DatabaseHelper.creditCardTable,
      {'saldo': saldo},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  /// Método para actualizar automáticamente el saldo de todas las tarjetas de crédito
  /// según la fecha de corte (solo si hoy es el día de corte Y no se ha actualizado ese día).
  Future<void> actualizarSaldosPorFechaCorte(int userId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.creditCardTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    final hoy = DateTime.now();
    final diaHoy = hoy.day;
    final hoyStr =
        "${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}";

    for (final map in maps) {
      final tarjeta = CreditCard.fromMap(map);

      // Asegúra de que la fecha de corte sea un entero válido
      final corteDia = int.tryParse(tarjeta.corte) ?? 0;

      // Compara si ya se actualizó hoy
      final yaActualizadoHoy = tarjeta.ultimaActualizacionSaldo == hoyStr;

      // Solo actualiza si es el día de corte, no se ha actualizado hoy y el saldo < límite
      if (corteDia == diaHoy &&
          !yaActualizadoHoy &&
          tarjeta.saldo != tarjeta.limite) {
        await db.update(
          DatabaseHelper.creditCardTable,
          {
            'saldo': tarjeta.limite,
            'ultima_actualizacion_saldo':
                hoyStr, // Marca la actualización de hoy
          },
          where: 'id = ? AND user_id = ?',
          whereArgs: [tarjeta.id, tarjeta.userId],
        );
      }
    }
  }
}
