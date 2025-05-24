import 'package:flutter/material.dart';
import '../../data/models/repositories/usuario_repository.dart';
import '../../data/models/user_model.dart';

class UsuarioProvider extends ChangeNotifier {
  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  UserModel? _usuario;
  UserModel? get usuario => _usuario;

  /// Establece el usuario en sesión y lo notifica
  void setUsuario(UserModel usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  /// Intenta autenticar al usuario con username y password.
  /// Si el login es correcto, establece el usuario, retorna true. Si no, retorna false.
  Future<bool> login(String username, String password) async {
    final user = await _usuarioRepository.getUsuarioByUsername(username);
    if (user != null && user.password == password) {
      _usuario = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Crea un nuevo usuario y lo inicia sesión automáticamente.
  Future<bool> registrarYLogin(UserModel newUser) async {
    // Verificar disponibilidad de username
    final disponible = await _usuarioRepository.isUsernameAvailable(
      newUser.username,
    );
    if (!disponible) return false;
    // Insertar en la base de datos
    final id = await _usuarioRepository.insertUsuario(newUser);
    if (id > 0) {
      final usuarioCreado = newUser.copyWith(id: id);
      _usuario = usuarioCreado;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Carga el usuario desde la base de datos por ID (ejemplo para mantener sesión)
  Future<void> cargarUsuarioPorId(int id) async {
    final usuarios = await _usuarioRepository.getAllUsuarios();
    UserModel? user;
    try {
      user = usuarios.firstWhere((u) => u.id == id);
    } catch (_) {
      user = null;
    }
    if (user != null) {
      _usuario = user;
      notifyListeners();
    }
  }

  /// Actualiza el usuario actual en la base de datos y en el provider
  Future<void> actualizarUsuario(UserModel usuarioActualizado) async {
    await _usuarioRepository.updateUsuario(usuarioActualizado);
    _usuario = usuarioActualizado;
    notifyListeners();
  }

  /// Actualiza solo el presupuesto del usuario actual y lo guarda en la base de datos
  Future<void> actualizarPresupuestoUsuario(
    int userId,
    double nuevoPresupuesto,
  ) async {
    if (_usuario == null || _usuario!.id != userId) {
      // Si no es el usuario actual, carga y actualiza
      final usuarioBD = await _usuarioRepository.getUsuarioById(userId);
      if (usuarioBD != null) {
        final actualizado = usuarioBD.copyWith(presupuesto: nuevoPresupuesto);
        await _usuarioRepository.updateUsuario(actualizado);
        _usuario = actualizado;
        notifyListeners();
      }
    } else {
      // Actualiza el presupuesto del usuario actual
      final actualizado = _usuario!.copyWith(presupuesto: nuevoPresupuesto);
      await _usuarioRepository.updateUsuario(actualizado);
      _usuario = actualizado;
      notifyListeners();
    }
  }

  /// Cierra la sesión del usuario
  void cerrarSesion() {
    _usuario = null;
    notifyListeners();
  }
}
