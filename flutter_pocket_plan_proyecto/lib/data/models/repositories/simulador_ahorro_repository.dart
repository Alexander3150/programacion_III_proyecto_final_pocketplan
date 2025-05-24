// repositories/simulador_ahorro_repository.dart

import 'package:sqflite/sqflite.dart';

import '../../../core/database/bd_implementation.dart';
import '../simulador_ahorro.dart';


class SimuladorAhorroRepository {
  final dbHelper = DatabaseHelper();

  /// Inserta un nuevo simulador de ahorro
  Future<int> insertSimuladorAhorro(SimuladorAhorro sa) async {
    final db = await dbHelper.database;
    return await db.insert(
      DatabaseHelper.simuladorAhorroTable,
      sa.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lista todos los simuladores de ahorro de un usuario
  Future<List<SimuladorAhorro>> getSimuladoresAhorroByUser(int userId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.simuladorAhorroTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => SimuladorAhorro.fromMap(maps[i]));
  }

  /// Obtiene un simulador de ahorro específico de un usuario
  Future<SimuladorAhorro?> getSimuladorAhorroById(int id, int userId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.simuladorAhorroTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    if (maps.isNotEmpty) return SimuladorAhorro.fromMap(maps.first);
    return null;
  }

  /// Actualiza un simulador de ahorro (requiere userId)
  Future<int> updateSimuladorAhorro(SimuladorAhorro sa, int userId) async {
    final db = await dbHelper.database;
    return await db.update(
      DatabaseHelper.simuladorAhorroTable,
      sa.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [sa.id, userId],
    );
  }

  /// Elimina un simulador de ahorro de un usuario
  Future<int> deleteSimuladorAhorro(int id, int userId) async {
    final db = await dbHelper.database;
    return await db.delete(
      DatabaseHelper.simuladorAhorroTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  /// Actualiza la cuota sugerida del simulador de ahorro
  Future<void> actualizarCuotaSugerida(
    SimuladorAhorro ahorro,
    double nuevaCuotaSugerida,
    int userId,
  ) async {
    final actualizado = ahorro.copyWith(cuotaSugerida: nuevaCuotaSugerida);
    await updateSimuladorAhorro(actualizado, userId);
  }

  /// Actualiza el progreso del simulador de ahorro
  Future<void> actualizarProgresoSimulador(
    SimuladorAhorro simulador,
    int userId,
  ) async {
    final db = await dbHelper.database;
    await db.update(
      DatabaseHelper.simuladorAhorroTable,
      simulador.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [simulador.id, userId],
    );
  }
}
