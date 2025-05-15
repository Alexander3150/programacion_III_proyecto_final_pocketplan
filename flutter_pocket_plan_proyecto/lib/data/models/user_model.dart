import 'dart:math';

class UserModel {
  final int id;
  final String email;
  final String username;
  final String password;
  String? recoveryCode;
  DateTime? codeExpiration;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.password,
    this.recoveryCode,
    this.codeExpiration,
  });

  /// Método para actualizar propiedades
  UserModel copyWith({
    String? password,
    String? recoveryCode,
    DateTime? codeExpiration,
  }) {
    return UserModel(
      id: id,
      email: email,
      username: username,
      password: password ?? this.password,
      recoveryCode: recoveryCode ?? this.recoveryCode,
      codeExpiration: codeExpiration ?? this.codeExpiration,
    );
  }

  //Para el login
  static UserModel? authenticate(String username, String password) {
    try {
      return _userList.firstWhere(
        (u) =>
            u.username.trim().toLowerCase() == username.trim().toLowerCase() &&
            u.password.trim() == password.trim(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Genera y asigna un código de recuperación
  static String generateRecoveryCode(String email, String username) {
    final index = _userList.indexWhere(
      (u) => u.email == email && u.username == username,
    );

    if (index == -1) throw Exception('Usuario no encontrado');

    final code = _generateRandomCode();
    _userList[index] = _userList[index].copyWith(
      recoveryCode: code,
      codeExpiration: DateTime.now().add(const Duration(minutes: 15)),
    );

    return code;
  }

  /// Verifica si el código es válido
  static bool verifyRecoveryCode(String email, String username, String code) {
    try {
      final user = _userList.firstWhere(
        (u) => u.email == email && u.username == username,
      );

      return user.recoveryCode == code &&
          user.codeExpiration != null &&
          user.codeExpiration!.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// ACTUALIZA la contraseña de un usuario en la lista temporal
  static void updatePassword(
    String email,
    String username,
    String newPassword,
  ) {
    final index = _userList.indexWhere(
      (u) => u.email == email && u.username == username,
    );

    if (index != -1) {
      _userList[index] = _userList[index].copyWith(
        password: newPassword,
        recoveryCode: null,
        codeExpiration: null,
      );
      print('Contraseña actualizada para: $email / $username');
    } else {
      print('Usuario no encontrado para actualizar contraseña.');
    }
  }

  /// Genera un código aleatorio de 6 dígitos
  static String _generateRandomCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Lista temporal de usuarios almacenados en memoria
  static final List<UserModel> _userList = [];

  /// Obtiene la lista completa de usuarios
  static List<UserModel> get userList => _userList;

  /// Crea un nuevo usuario con ID único y lo agrega a la lista
  static UserModel createNew({
    required String email,
    required String username,
    required String password,
  }) {
    final newId = _generateUniqueId();
    final newUser = UserModel(
      id: newId,
      email: email,
      username: username,
      password: password,
    );
    _userList.add(newUser);
    return newUser;
  }

  /// Verifica si el nombre de usuario está disponible
  static bool isUsernameAvailable(String username) {
    return !_userList.any(
      (user) => user.username.toLowerCase() == username.toLowerCase(),
    );
  }

  /// Genera un ID único incremental
  static int _generateUniqueId() {
    if (_userList.isEmpty) return 1;
    return _userList.map((user) => user.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Elimina un usuario de la lista si la contraseña coincide
  static bool deleteUser({required String username, required String password}) {
    final index = _userList.indexWhere(
      (u) =>
          u.username.trim().toLowerCase() == username.trim().toLowerCase() &&
          u.password == password.trim(),
    );

    if (index != -1) {
      _userList.removeAt(index);
      print('Usuario eliminado: $username');
      return true;
    }

    return false; // Contraseña incorrecta o usuario no encontrado
  }
}
