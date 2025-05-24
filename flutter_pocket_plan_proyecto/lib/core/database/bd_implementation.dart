import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

// Importa tus modelos aquí

import '../../data/models/user_model.dart';
import '../../data/models/credit_card_model.dart';
import '../../data/models/debit_card_model.dart';
import '../../data/models/simulador_ahorro.dart';
import '../../data/models/simulador_deuda.dart';
import '../../data/models/cuota_ahorro.dart';
import '../../data/models/cuota_pago.dart';
import '../../data/models/movimiento_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  final int _version = 8; // ¡Aumenta la versión si cambias estructura!

  // Nombres de tablas
  static const String userTable = 'users';
  static const String creditCardTable = 'credit_cards';
  static const String debitCardTable = 'debit_cards';
  static const String simuladorAhorroTable = 'simulador_ahorro';
  static const String simuladorDeudaTable = 'simulador_deuda';
  static const String movimientoTable = 'movimientos';
  static const String cuotaAhorroTable = 'cuotas_ahorro';
  static const String cuotaPagoTable = 'cuotas_pago';

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'pocket_plan.db');
    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // --- Creación de tablas ---
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $userTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        recovery_code TEXT,
        code_expiration TEXT,
        presupuesto REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
  CREATE TABLE $creditCardTable (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    banco TEXT NOT NULL,
    numero TEXT NOT NULL,
    alias TEXT NOT NULL,
    limite REAL NOT NULL,
    saldo REAL NOT NULL,
    expiracion TEXT NOT NULL,
    corte TEXT NOT NULL,
    pago TEXT NOT NULL,
    ultima_actualizacion_saldo TEXT,  -- <--- NUEVA COLUMNA
    FOREIGN KEY (user_id) REFERENCES $userTable(id) ON DELETE CASCADE
  )
''');

    await db.execute('''
      CREATE TABLE $debitCardTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        banco TEXT NOT NULL,
        numero TEXT NOT NULL,
        alias TEXT NOT NULL,
        expiracion TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $userTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $movimientoTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        fecha TEXT NOT NULL,
        monto REAL NOT NULL,
        concepto TEXT NOT NULL,
        etiqueta TEXT NOT NULL,
        metodo_pago TEXT,
        tarjeta_id INTEGER,
        tipo_tarjeta TEXT,
        opcion_pago TEXT,
        cuotas INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $userTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
         CREATE TABLE $simuladorAhorroTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        objetivo TEXT NOT NULL,
        periodo TEXT NOT NULL,
        monto REAL NOT NULL,
        monto_inicial REAL NOT NULL,
        fecha_inicio TEXT NOT NULL,
        fecha_fin TEXT NOT NULL,
        progreso REAL NOT NULL DEFAULT 0,
        cuota_sugerida REAL NOT NULL DEFAULT 0,
        total_pagos INTEGER NOT NULL DEFAULT 0,           -- NUEVO
        FOREIGN KEY (user_id) REFERENCES $userTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $simuladorDeudaTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        motivo TEXT NOT NULL,
        periodo TEXT NOT NULL,
        monto REAL NOT NULL,
        monto_cancelado REAL NOT NULL,
        fecha_inicio TEXT NOT NULL,
        fecha_fin TEXT NOT NULL,
        progreso REAL NOT NULL DEFAULT 0,
        pago_sugerido REAL NOT NULL DEFAULT 0,
        total_pagos INTEGER NOT NULL DEFAULT 0,           -- NUEVO
        FOREIGN KEY (user_id) REFERENCES $userTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $cuotaAhorroTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        simulador_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        FOREIGN KEY (simulador_id) REFERENCES $simuladorAhorroTable(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES $userTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $cuotaPagoTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        simulador_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        FOREIGN KEY(simulador_id) REFERENCES $simuladorDeudaTable(id) ON DELETE CASCADE,
        FOREIGN KEY(user_id) REFERENCES $userTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_movimiento_tipo ON $movimientoTable(tipo)',
    );
    await db.execute(
      'CREATE INDEX idx_movimiento_tarjeta ON $movimientoTable(tarjeta_id)',
    );
  }

  // --- Migraciones de versión ---
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $creditCardTable ADD COLUMN saldo REAL NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE $simuladorAhorroTable ADD COLUMN cuota_sugerida REAL NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE $simuladorDeudaTable ADD COLUMN pago_sugerido REAL NOT NULL DEFAULT 0',
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $cuotaPagoTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          simulador_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          monto REAL NOT NULL,
          fecha TEXT NOT NULL,
          FOREIGN KEY (simulador_id) REFERENCES $simuladorDeudaTable(id) ON DELETE CASCADE,
          FOREIGN KEY (user_id) REFERENCES $userTable(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE $userTable ADD COLUMN presupuesto REAL NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 5) {
      // Añadir columnas user_id a las tablas que faltaban
      await db.execute(
        'ALTER TABLE $simuladorAhorroTable ADD COLUMN user_id INTEGER NOT NULL DEFAULT 1',
      );
      await db.execute(
        'ALTER TABLE $simuladorDeudaTable ADD COLUMN user_id INTEGER NOT NULL DEFAULT 1',
      );
      await db.execute(
        'ALTER TABLE $cuotaAhorroTable ADD COLUMN user_id INTEGER NOT NULL DEFAULT 1',
      );
      await db.execute(
        'ALTER TABLE $cuotaPagoTable ADD COLUMN user_id INTEGER NOT NULL DEFAULT 1',
      );

      // NOTA: Si tienes datos previos y más de un usuario, deberías actualizar esos user_id luego.
    }
    if (oldVersion < 6) {
      // NUEVAS COLUMNAS
      await db.execute(
        'ALTER TABLE $simuladorAhorroTable ADD COLUMN total_pagos INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE $simuladorDeudaTable ADD COLUMN total_pagos INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 7) {
      await db.execute(
        'ALTER TABLE $creditCardTable ADD COLUMN ultima_actualizacion_saldo TEXT',
      );
    }
    if (oldVersion < 8) {
      await db.execute(
        'ALTER TABLE $creditCardTable ADD COLUMN ultima_actualizacion_saldo TEXT',
      );
    }
  }

  // ---------------------- CRUD POR MODELO ------------------------

  // ----------- USUARIO --------------------
  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert(userTable, user.toMap());
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query(
      userTable,
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) return UserModel.fromMap(maps.first);
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final maps = await db.query(userTable);
    return maps.map((map) => UserModel.fromMap(map)).toList();
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update(
      userTable,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(userTable, where: 'id = ?', whereArgs: [id]);
  }

   // ----------- MOVIMIENTOS ----------------
  Future<int> insertMovimiento(Movimiento movimiento) async {
    final db = await database;
    return await db.insert(movimientoTable, movimiento.toMap());
  }

  Future<List<Movimiento>> getMovimientosByUser(int userId) async {
    final db = await database;
    final maps = await db.query(
      movimientoTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'fecha DESC',
    );
    return maps.map((map) => Movimiento.fromMap(map)).toList();
  }

  Future<int> updateMovimiento(Movimiento movimiento) async {
    final db = await database;
    return await db.update(
      movimientoTable,
      movimiento.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [movimiento.id, movimiento.userId],
    );
  }

  Future<int> deleteMovimiento(int id, int userId) async {
    final db = await database;
    return await db.delete(
      movimientoTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }


  // ------------------- CREDIT CARD -----------------
  Future<int> insertCreditCard(CreditCard card) async {
    final db = await database;
    return await db.insert(creditCardTable, card.toMap());
  }

  Future<List<CreditCard>> getCreditCardsByUser(int userId) async {
    final db = await database;
    final maps = await db.query(
      creditCardTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => CreditCard.fromMap(map)).toList();
  }

  Future<int> updateCreditCard(CreditCard card) async {
    final db = await database;
    return await db.update(
      creditCardTable,
      card.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [card.id, card.userId],
    );
  }

  Future<int> deleteCreditCard(int id, int userId) async {
    final db = await database;
    return await db.delete(
      creditCardTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  // ------------------- DEBIT CARD -----------------
  Future<int> insertDebitCard(DebitCard card) async {
    final db = await database;
    return await db.insert(debitCardTable, card.toMap());
  }

  Future<List<DebitCard>> getDebitCardsByUser(int userId) async {
    final db = await database;
    final maps = await db.query(
      debitCardTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => DebitCard.fromMap(map)).toList();
  }

  Future<int> updateDebitCard(DebitCard card) async {
    final db = await database;
    return await db.update(
      debitCardTable,
      card.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [card.id, card.userId],
    );
  }

  Future<int> deleteDebitCard(int id, int userId) async {
    final db = await database;
    return await db.delete(
      debitCardTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  
  // ------------------- SIMULADOR AHORRO ------------
  Future<int> insertSimuladorAhorro(SimuladorAhorro sa) async {
    final db = await database;
    return await db.insert(simuladorAhorroTable, sa.toMap());
  }

  Future<List<SimuladorAhorro>> getSimuladoresAhorroByUser(int userId) async {
    final db = await database;
    final maps = await db.query(
      simuladorAhorroTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => SimuladorAhorro.fromMap(map)).toList();
  }

  Future<int> updateSimuladorAhorro(SimuladorAhorro sa) async {
    final db = await database;
    return await db.update(
      simuladorAhorroTable,
      sa.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [sa.id, sa.userId],
    );
  }

  Future<int> deleteSimuladorAhorro(int id, int userId) async {
    final db = await database;
    return await db.delete(
      simuladorAhorroTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  // ------------------- SIMULADOR DEUDA --------------
  Future<int> insertSimuladorDeuda(SimuladorDeuda sd) async {
    final db = await database;
    return await db.insert(simuladorDeudaTable, sd.toMap());
  }

  Future<List<SimuladorDeuda>> getSimuladoresDeudaByUser(int userId) async {
    final db = await database;
    final maps = await db.query(
      simuladorDeudaTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => SimuladorDeuda.fromMap(map)).toList();
  }

  Future<int> updateSimuladorDeuda(SimuladorDeuda sd) async {
    final db = await database;
    return await db.update(
      simuladorDeudaTable,
      sd.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [sd.id, sd.userId],
    );
  }

  Future<int> deleteSimuladorDeuda(int id, int userId) async {
    final db = await database;
    return await db.delete(
      simuladorDeudaTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  // ------------------- CUOTAS DE AHORRO ------------
  Future<int> insertCuotaAhorro(CuotaAhorro cuota) async {
    final db = await database;
    return await db.insert(cuotaAhorroTable, cuota.toMap());
  }

  Future<List<CuotaAhorro>> getCuotasAhorroByUser(
    int simuladorId,
    int userId,
  ) async {
    final db = await database;
    final result = await db.query(
      cuotaAhorroTable,
      where: 'simulador_id = ? AND user_id = ?',
      whereArgs: [simuladorId, userId],
      orderBy: 'fecha ASC',
    );
    return result.map((map) => CuotaAhorro.fromMap(map)).toList();
  }

  Future<int> deleteCuotaAhorro(int id, int userId) async {
    final db = await database;
    return await db.delete(
      cuotaAhorroTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<int> updateCuotaAhorro(CuotaAhorro cuota) async {
    final db = await database;
    return await db.update(
      cuotaAhorroTable,
      cuota.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [cuota.id, cuota.userId],
    );
  }

  // ------------------- CUOTAS DE PAGO DEUDA ------------
  Future<int> insertCuotaPago(CuotaPago cuota) async {
    final db = await database;
    return await db.insert(cuotaPagoTable, cuota.toMap());
  }

  Future<List<CuotaPago>> getCuotasPagoByUser(
    int simuladorId,
    int userId,
  ) async {
    final db = await database;
    final result = await db.query(
      cuotaPagoTable,
      where: 'simulador_id = ? AND user_id = ?',
      whereArgs: [simuladorId, userId],
      orderBy: 'fecha ASC',
    );
    return result.map((map) => CuotaPago.fromMap(map)).toList();
  }

  Future<int> deleteCuotaPago(int id, int userId) async {
    final db = await database;
    return await db.delete(
      cuotaPagoTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<int> updateCuotaPago(CuotaPago cuota) async {
    final db = await database;
    return await db.update(
      cuotaPagoTable,
      cuota.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [cuota.id, cuota.userId],
    );
  }


}
