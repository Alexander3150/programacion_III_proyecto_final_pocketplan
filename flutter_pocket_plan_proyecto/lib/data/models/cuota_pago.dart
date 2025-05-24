class CuotaPago {
  final int? id;
  final int userId; // <-- Añadido aquí
  final int simuladorId;
  final double monto;
  final DateTime fecha;

  CuotaPago({
    this.id,
    required this.userId, // <-- Añadido aquí
    required this.simuladorId,
    required this.monto,
    required this.fecha,
  });

  factory CuotaPago.fromMap(Map<String, dynamic> map) {
    return CuotaPago(
      id: map['id'] as int?,
      userId: map['user_id'], // <-- Añadido aquí
      simuladorId: map['simulador_id'] as int,
      monto:
          (map['monto'] is int)
              ? (map['monto'] as int).toDouble()
              : (map['monto'] as num).toDouble(),
      fecha: DateTime.parse(map['fecha']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId, // <-- Añadido aquí
      'simulador_id': simuladorId,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
    };
  }

  CuotaPago copyWith({
    int? id,
    int? userId, // <-- Añadido aquí
    int? simuladorId,
    double? monto,
    DateTime? fecha,
  }) {
    return CuotaPago(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      simuladorId: simuladorId ?? this.simuladorId,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
    );
  }
}
