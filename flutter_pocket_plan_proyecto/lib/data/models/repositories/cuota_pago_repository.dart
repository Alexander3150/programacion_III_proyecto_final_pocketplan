import 'package:sqflite/sqflite.dart';

import '../../../core/database/bd_implementation.dart';
import '../cuota_pago.dart';


class CuotaPagoRepository {
  final dbHelper = DatabaseHelper();

  /// Inserta una nueva cuota de pago para un usuario específico.
  Future<int> insertCuotaPago(CuotaPago cuota, int userId) async {
    final db = await dbHelper.database;
    final map = cuota.toMap()..['user_id'] = userId; // Añade el user_id al mapa
    return await db.insert(
      DatabaseHelper.cuotaPagoTable,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene todas las cuotas de pago por simuladorId y usuario.
  Future<List<CuotaPago>> getCuotasPorSimuladorId(
    int simuladorId,
    int userId,
  ) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.cuotaPagoTable,
      where: 'simulador_id = ? AND user_id = ?',
      whereArgs: [simuladorId, userId],
      orderBy: 'fecha DESC',
    );
    return maps.map((map) => CuotaPago.fromMap(map)).toList();
  }

  /// Actualiza una cuota de pago específica (requiere el userId).
  Future<int> updateCuotaPago(CuotaPago cuota, int userId) async {
    final db = await dbHelper.database;
    return await db.update(
      DatabaseHelper.cuotaPagoTable,
      cuota.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [cuota.id, userId],
    );
  }

  /// Elimina una cuota de pago específica por ID y usuario.
  Future<int> deleteCuotaPago(int id, int userId) async {
    final db = await dbHelper.database;
    return await db.delete(
      DatabaseHelper.cuotaPagoTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }
}
