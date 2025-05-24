class Movimiento {
  final int? id; // autoincremental
  final int userId; // usuario dueño del movimiento
  final String tipo; // 'ingreso' o 'egreso'
  final DateTime fecha;
  final double monto;
  final String concepto;
  final String etiqueta;
  final String? metodoPago; // solo para egresos
  final int? tarjetaId; // id int de tarjeta asociada (nullable)
  final String? tipoTarjeta; // 'Débito' o 'Crédito'
  final String? opcionPago; // 'Al contado' o 'A cuotas', solo crédito
  final int? cuotas; // solo si opcionPago == 'A cuotas'
  final DateTime? createdAt;

  Movimiento({
    this.id,
    required this.userId,
    required this.tipo,
    required this.fecha,
    required this.monto,
    required this.concepto,
    required this.etiqueta,
    this.metodoPago,
    this.tarjetaId,
    this.tipoTarjeta,
    this.opcionPago,
    this.cuotas,
    this.createdAt,
  });

  /// Permite crear una copia del objeto cambiando solo los campos deseados.
  Movimiento copyWith({
    int? id,
    int? userId,
    String? tipo,
    DateTime? fecha,
    double? monto,
    String? concepto,
    String? etiqueta,
    String? metodoPago,
    int? tarjetaId,
    String? tipoTarjeta,
    String? opcionPago,
    int? cuotas,
    DateTime? createdAt,
  }) {
    return Movimiento(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tipo: tipo ?? this.tipo,
      fecha: fecha ?? this.fecha,
      monto: monto ?? this.monto,
      concepto: concepto ?? this.concepto,
      etiqueta: etiqueta ?? this.etiqueta,
      metodoPago: metodoPago ?? this.metodoPago,
      tarjetaId: tarjetaId ?? this.tarjetaId,
      tipoTarjeta: tipoTarjeta ?? this.tipoTarjeta,
      opcionPago: opcionPago ?? this.opcionPago,
      cuotas: cuotas ?? this.cuotas,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'tipo': tipo.toLowerCase(), // Fuerza a minúsculas al guardar
      'fecha': fecha.toIso8601String(),
      'monto': monto,
      'concepto': concepto,
      'etiqueta': etiqueta,
      'metodo_pago': metodoPago,
      'tarjeta_id': tarjetaId,
      'tipo_tarjeta': tipoTarjeta,
      'opcion_pago': opcionPago,
      'cuotas': cuotas,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Movimiento.fromMap(Map<String, dynamic> map) {
    return Movimiento(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      tipo: map['tipo'] as String,
      fecha: DateTime.parse(map['fecha']),
      monto: (map['monto'] as num).toDouble(),
      concepto: map['concepto'] as String,
      etiqueta: map['etiqueta'] as String,
      metodoPago: map['metodo_pago'] as String?,
      tarjetaId: map['tarjeta_id'] as int?,
      tipoTarjeta: map['tipo_tarjeta'] as String?,
      opcionPago: map['opcion_pago'] as String?,
      cuotas: map['cuotas'] as int?,
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }
}
