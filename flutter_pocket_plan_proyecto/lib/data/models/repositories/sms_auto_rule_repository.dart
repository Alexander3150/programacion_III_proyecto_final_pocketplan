import 'package:sqflite/sqflite.dart';

import '../../../core/database/bd_implementation.dart';
import '../sms_auto_rule.dart';

class SmsAutoRuleRepository {
  final dbHelper = DatabaseHelper();

  Future<int> insertRule(SmsAutoRule rule) async {
    final db = await dbHelper.database;
    return await db.insert(
      DatabaseHelper.smsAutoRuleTable,
      rule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateRule(SmsAutoRule rule) async {
    final db = await dbHelper.database;
    return await db.update(
      DatabaseHelper.smsAutoRuleTable,
      rule.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [rule.id, rule.userId],
    );
  }

  Future<int> deleteRule(int id, int userId) async {
    final db = await dbHelper.database;
    return await db.delete(
      DatabaseHelper.smsAutoRuleTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<int> deleteRuleByCard(
    int userId,
    int tarjetaId,
    String tipoTarjeta,
  ) async {
    final db = await dbHelper.database;
    return await db.delete(
      DatabaseHelper.smsAutoRuleTable,
      where: 'user_id = ? AND tarjeta_id = ? AND tipo_tarjeta = ?',
      whereArgs: [userId, tarjetaId, tipoTarjeta],
    );
  }

  Future<SmsAutoRule?> getRuleByCard(
    int userId,
    int tarjetaId,
    String tipoTarjeta,
  ) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.smsAutoRuleTable,
      where: 'user_id = ? AND tarjeta_id = ? AND tipo_tarjeta = ?',
      whereArgs: [userId, tarjetaId, tipoTarjeta],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SmsAutoRule.fromMap(maps.first);
  }

  Future<List<SmsAutoRule>> getEnabledRulesByUser(int userId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.smsAutoRuleTable,
      where: 'user_id = ? AND enabled = 1',
      whereArgs: [userId],
    );
    return maps.map((m) => SmsAutoRule.fromMap(m)).toList();
  }

  Future<SmsAutoRule?> findMatchingRule({
    required int userId,
    required String sender,
    required String prefix,
    required String identifier,
  }) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.smsAutoRuleTable,
      where:
          'user_id = ? AND enabled = 1 AND sender = ? AND prefix = ? AND identifier = ?',
      whereArgs: [userId, sender, prefix, identifier],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SmsAutoRule.fromMap(maps.first);
  }
}
