import 'package:sqflite/sqflite.dart';
import '../../../core/database/bd_implementation.dart';
import '../cuota_pago.dart';
import '../simulador_deuda.dart';

class SimuladorDeudaRepository {
  final dbHelper = DatabaseHelper();

  /// Inserta una nueva DEUDA (SimuladorDeuda)
  Future<int> insertSimuladorDeuda(SimuladorDeuda deuda) async {
    final db = await dbHelper.database;
    return await db.insert(
      DatabaseHelper.simuladorDeudaTable,
      deuda.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Inserta una nueva cuota de pago para una deuda
  Future<int> insertCuotaPago(CuotaPago cuota) async {
    final db = await dbHelper.database;
    return await db.insert(
      DatabaseHelper.cuotaPagoTable,
      cuota.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lista todas las deudas de un usuario
  Future<List<SimuladorDeuda>> getSimuladoresDeudaByUser(int userId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.simuladorDeudaTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => SimuladorDeuda.fromMap(maps[i]));
  }

  /// Obtiene una deuda específica de un usuario
  Future<SimuladorDeuda?> getSimuladorDeudaById(int id, int userId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.simuladorDeudaTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    if (maps.isNotEmpty) return SimuladorDeuda.fromMap(maps.first);
    return null;
  }

  /// Actualiza una deuda específica (requiere userId)
  Future<int> updateSimuladorDeuda(SimuladorDeuda sd, int userId) async {
    final db = await dbHelper.database;
    return await db.update(
      DatabaseHelper.simuladorDeudaTable,
      sd.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [sd.id, userId],
    );
  }

  /// Elimina una deuda específica de un usuario
  Future<int> deleteSimuladorDeuda(int id, int userId) async {
    final db = await dbHelper.database;
    return await db.delete(
      DatabaseHelper.simuladorDeudaTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  /// Actualiza el pago sugerido de una deuda específica
  Future<void> actualizarPagoSugerido(
    SimuladorDeuda deuda,
    double nuevoPagoSugerido,
    int userId,
  ) async {
    final actualizado = deuda.copyWith(pagoSugerido: nuevoPagoSugerido);
    await updateSimuladorDeuda(actualizado, userId);
  }
}
