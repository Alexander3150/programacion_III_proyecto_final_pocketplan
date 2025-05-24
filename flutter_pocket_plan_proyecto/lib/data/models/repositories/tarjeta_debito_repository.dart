import 'package:sqflite/sqflite.dart';

import '../../../core/database/bd_implementation.dart';
import '../debit_card_model.dart';

class TarjetaDebitoRepository {
  final dbHelper = DatabaseHelper();

  Future<int> insertTarjetaDebito(DebitCard card) async {
    final db = await dbHelper.database;
    return await db.insert(
      DatabaseHelper.debitCardTable,
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DebitCard>> getTarjetasDebitoByUser(int userId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.debitCardTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => DebitCard.fromMap(maps[i]));
  }

  Future<DebitCard?> getTarjetaDebitoById(int id, int userId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.debitCardTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    if (maps.isNotEmpty) return DebitCard.fromMap(maps.first);
    return null;
  }

  Future<int> updateTarjetaDebito(DebitCard card) async {
    final db = await dbHelper.database;
    return await db.update(
      DatabaseHelper.debitCardTable,
      card.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [card.id, card.userId],
    );
  }

  Future<int> deleteTarjetaDebito(int id, int userId) async {
    final db = await dbHelper.database;
    return await db.delete(
      DatabaseHelper.debitCardTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }
}
