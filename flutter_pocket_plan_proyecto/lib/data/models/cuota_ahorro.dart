// models/cuota_ahorro.dart

class CuotaAhorro {
  final int? id;
  final int userId;
  final int simuladorId;
  final double monto;
  final DateTime fecha;

  CuotaAhorro({
    this.id,
    required this.userId,
    required this.simuladorId,
    required this.monto,
    required this.fecha,
  });

  factory CuotaAhorro.fromMap(Map<String, dynamic> map) {
    double castToDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is int) return v.toDouble();
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return CuotaAhorro(
      id: map['id'] as int?,
      userId: map['user_id'],
      simuladorId: map['simulador_id'],
      monto: castToDouble(map['monto']),
      fecha: DateTime.parse(map['fecha']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'simulador_id': simuladorId,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
    };
  }

  CuotaAhorro copyWith({
    int? id,
    int? userId,
    int? simuladorId,
    double? monto,
    DateTime? fecha,
  }) {
    return CuotaAhorro(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      simuladorId: simuladorId ?? this.simuladorId,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
    );
  }
}
