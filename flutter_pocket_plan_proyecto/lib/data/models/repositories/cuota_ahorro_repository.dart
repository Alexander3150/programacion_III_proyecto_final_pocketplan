// repositories/cuota_ahorro_repository.dart

import 'package:sqflite/sql.dart';

import '../../../core/database/bd_implementation.dart';
import '../cuota_ahorro.dart';


class CuotaAhorroRepository {
  final dbHelper = DatabaseHelper();

  /// Inserta una nueva cuota de ahorro para un usuario específico
  Future<int> insertCuotaAhorro(CuotaAhorro cuota) async {
    final db = await dbHelper.database;
    return await db.insert(
      DatabaseHelper.cuotaAhorroTable,
      cuota.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene todas las cuotas de ahorro de un simulador y usuario específico
  Future<List<CuotaAhorro>> getCuotasPorSimuladorId(
    int simuladorId,
    int userId,
  ) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.cuotaAhorroTable,
      where: 'simulador_id = ? AND user_id = ?',
      whereArgs: [simuladorId, userId],
      orderBy: 'fecha ASC',
    );
    return maps.map((map) => CuotaAhorro.fromMap(map)).toList();
  }

  /// Actualiza una cuota de ahorro específica (requiere el userId)
  Future<int> updateCuotaAhorro(CuotaAhorro cuota) async {
    final db = await dbHelper.database;
    return await db.update(
      DatabaseHelper.cuotaAhorroTable,
      cuota.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [cuota.id, cuota.userId],
    );
  }

  /// Elimina una cuota de ahorro específica por ID y usuario
  Future<int> deleteCuotaAhorro(int id, int userId) async {
    final db = await dbHelper.database;
    return await db.delete(
      DatabaseHelper.cuotaAhorroTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  //Para obtener la suma del  monto ya ahorrado
  Future<double> getTotalAhorradoPorSimulador(
    int simuladorId,
    int userId,
  ) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(monto) as total FROM cuotas_ahorro WHERE simulador_id = ? AND user_id = ?',
      [simuladorId, userId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
