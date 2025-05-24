/// Incluye métodos para serializar, deserializar y manejar la persistencia en SQLite.
class UserModel {
  final int? id;
  final String email;
  final String username;
  final String password;
  final String? recoveryCode;
  final String? codeExpiration;
  final double? presupuesto;

  UserModel({
    this.id,
    required this.email,
    required this.username,
    required this.password,
    this.recoveryCode,
    this.codeExpiration,
    this.presupuesto,
  });

  /// Crea un objeto desde un Map (para la base de datos)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'],
      username: map['username'],
      password: map['password'],
      recoveryCode: map['recovery_code'],
      codeExpiration: map['code_expiration'],
      presupuesto:
          map['presupuesto'] != null
              ? (map['presupuesto'] as num).toDouble()
              : null,
    );
  }

  /// Convierte el objeto a Map (para guardar en la base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'password': password,
      'recovery_code': recoveryCode,
      'code_expiration': codeExpiration,
      'presupuesto': presupuesto,
    };
  }

  /// Crea una copia del usuario con parámetros opcionales
  UserModel copyWith({
    int? id,
    String? email,
    String? username,
    String? password,
    String? recoveryCode,
    String? codeExpiration,
    double? presupuesto, // Añadido aquí
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      password: password ?? this.password,
      recoveryCode: recoveryCode ?? this.recoveryCode,
      codeExpiration: codeExpiration ?? this.codeExpiration,
      presupuesto: presupuesto ?? this.presupuesto,
    );
  }

  ///  Devuelve el DateTime de expiración si es válido
  DateTime? get codeExpirationDateTime {
    if (codeExpiration == null) return null;
    return DateTime.tryParse(codeExpiration!);
  }
}
