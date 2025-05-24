/// Modelo de tarjeta de crédito.
class CreditCard {
  final int? id;
  final int userId;
  final String banco;
  final String numero;
  final String alias;
  final double limite;
  double saldo;
  final String expiracion;
  final String corte;
  final String pago;

  /// NUEVO: Fecha de la última actualización de saldo (YYYY-MM-DD)
  final String? ultimaActualizacionSaldo;

  CreditCard({
    this.id,
    required this.userId,
    required this.banco,
    required this.numero,
    required this.alias,
    required this.limite,
    required this.saldo,
    required this.expiracion,
    required this.corte,
    required this.pago,
    this.ultimaActualizacionSaldo,
  });

  /// Crea una tarjeta desde la base de datos
  factory CreditCard.fromMap(Map<String, dynamic> map) {
    return CreditCard(
      id: map['id'],
      userId: map['user_id'],
      banco: map['banco'],
      numero: map['numero'],
      alias: map['alias'],
      limite:
          (map['limite'] is int)
              ? (map['limite'] as int).toDouble()
              : map['limite'],
      saldo:
          (map['saldo'] is int)
              ? (map['saldo'] as int).toDouble()
              : map['saldo'],
      expiracion: map['expiracion'],
      corte: map['corte'],
      pago: map['pago'],
      ultimaActualizacionSaldo: map['ultima_actualizacion_saldo'], // NUEVO
    );
  }

  /// Convierte la tarjeta a un Map para guardar en la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'banco': banco,
      'numero': numero,
      'alias': alias,
      'limite': limite,
      'saldo': saldo,
      'expiracion': expiracion,
      'corte': corte,
      'pago': pago,
      'ultima_actualizacion_saldo': ultimaActualizacionSaldo, // NUEVO
    };
  }

  /// Copia la tarjeta permitiendo modificar campos específicos
  CreditCard copyWith({
    int? id,
    int? userId,
    String? banco,
    String? numero,
    String? alias,
    double? limite,
    double? saldo,
    String? expiracion,
    String? corte,
    String? pago,
    String? ultimaActualizacionSaldo, // NUEVO
  }) {
    return CreditCard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      banco: banco ?? this.banco,
      numero: numero ?? this.numero,
      alias: alias ?? this.alias,
      limite: limite ?? this.limite,
      saldo: saldo ?? this.saldo,
      expiracion: expiracion ?? this.expiracion,
      corte: corte ?? this.corte,
      pago: pago ?? this.pago,
      ultimaActualizacionSaldo:
          ultimaActualizacionSaldo ?? this.ultimaActualizacionSaldo,
    );
  }
}
