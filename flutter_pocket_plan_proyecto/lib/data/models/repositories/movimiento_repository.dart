import 'package:sqflite/sqlite_api.dart';

import '../../../core/database/bd_implementation.dart';
import '../movimiento_model.dart';



class MovimientoRepository {
  final dbHelper = DatabaseHelper();

  Future<int> insertMovimiento(Movimiento movimiento) async {
    final db = await dbHelper.database;
    return await db.insert(
      DatabaseHelper.movimientoTable,
      movimiento.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Movimiento>> getMovimientosByUser(int userId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.movimientoTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'fecha DESC',
    );
    return List.generate(maps.length, (i) => Movimiento.fromMap(maps[i]));
  }

  Future<List<Movimiento>> getMovimientosByTipo(int userId, String tipo) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.movimientoTable,
      where: 'user_id = ? AND LOWER(tipo) = ?', // insensible a mayúsculas
      whereArgs: [userId, tipo.toLowerCase()], //  se asegura en minúsculas
      orderBy: 'fecha DESC',
    );
    return List.generate(maps.length, (i) => Movimiento.fromMap(maps[i]));
  }

  Future<int> updateMovimiento(Movimiento movimiento) async {
    final db = await dbHelper.database;
    return await db.update(
      DatabaseHelper.movimientoTable,
      movimiento.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [movimiento.id, movimiento.userId],
    );
  }

  Future<int> deleteMovimiento(int id, int userId) async {
    final db = await dbHelper.database;
    return await db.delete(
      DatabaseHelper.movimientoTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> limpiarMovimientosUsuario(int userId) async {
    final db = await dbHelper.database;
    await db.delete(
      DatabaseHelper.movimientoTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
