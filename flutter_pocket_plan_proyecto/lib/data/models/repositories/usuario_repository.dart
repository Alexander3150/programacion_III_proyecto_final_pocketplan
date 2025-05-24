import 'package:sqflite/sqflite.dart';
import '../../../core/database/bd_implementation.dart';
import '../user_model.dart';

/// Repositorio para gestionar operaciones CRUD de usuarios en la base de datos.
class UsuarioRepository {
  final dbHelper = DatabaseHelper();

  /// Insertar un usuario dentro de la base de datos.
  Future<int> insertUsuario(UserModel usuario) async {
    final db = await dbHelper.database;
    return await db.insert(
      DatabaseHelper.userTable,
      usuario.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtener todos los usuarios.
  Future<List<UserModel>> getAllUsuarios() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.userTable,
    );
    return List.generate(maps.length, (i) => UserModel.fromMap(maps[i]));
  }

  /// Obtener un usuario por nombre de usuario.
  Future<UserModel?> getUsuarioByUsername(String username) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.userTable,
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) return UserModel.fromMap(maps.first);
    return null;
  }

  /// Obtener un usuario por ID.
  Future<UserModel?> getUsuarioById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.userTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return UserModel.fromMap(maps.first);
    return null;
  }

  /// Modificar un usuario existente.
  Future<int> updateUsuario(UserModel usuario) async {
    final db = await dbHelper.database;
    return await db.update(
      DatabaseHelper.userTable,
      usuario.toMap(),
      where: 'id = ?',
      whereArgs: [usuario.id],
    );
  }

  /// Eliminar un usuario por ID.
  Future<int> deleteUsuario(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      DatabaseHelper.userTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Verificar si el nombre de usuario está disponible.
  Future<bool> isUsernameAvailable(String username) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.userTable,
      where: 'LOWER(username) = ?',
      whereArgs: [username.toLowerCase()],
    );
    return maps.isEmpty;
  }
}
