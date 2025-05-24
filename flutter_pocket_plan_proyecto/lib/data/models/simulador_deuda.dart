class SimuladorDeuda {
  final int? id;
  final int userId;
  final String motivo;
  final String periodo;
  final double monto;
  final double montoCancelado;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final double progreso;
  final double pagoSugerido;
  final int totalPagos; // NUEVO

  SimuladorDeuda({
    this.id,
    required this.userId,
    required this.motivo,
    required this.periodo,
    required this.monto,
    required this.montoCancelado,
    required this.fechaInicio,
    required this.fechaFin,
    this.progreso = 0.0,
    this.pagoSugerido = 0.0,
    required this.totalPagos, // NUEVO
  });

  factory SimuladorDeuda.fromMap(Map<String, dynamic> map) {
    double castToDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is int) return v.toDouble();
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return SimuladorDeuda(
      id: map['id'],
      userId: map['user_id'],
      motivo: map['motivo'],
      periodo: map['periodo'],
      monto: castToDouble(map['monto']),
      montoCancelado: castToDouble(map['monto_cancelado']),
      fechaInicio: DateTime.parse(map['fecha_inicio']),
      fechaFin: DateTime.parse(map['fecha_fin']),
      progreso: castToDouble(map['progreso']),
      pagoSugerido: castToDouble(map['pago_sugerido']),
      totalPagos: map['total_pagos'] ?? 0, // NUEVO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'motivo': motivo,
      'periodo': periodo,
      'monto': monto,
      'monto_cancelado': montoCancelado,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin.toIso8601String(),
      'progreso': progreso,
      'pago_sugerido': pagoSugerido,
      'total_pagos': totalPagos, // NUEVO
    };
  }

  SimuladorDeuda copyWith({
    int? id,
    int? userId,
    String? motivo,
    String? periodo,
    double? monto,
    double? montoCancelado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    double? progreso,
    double? pagoSugerido,
    int? totalPagos, // NUEVO
  }) {
    return SimuladorDeuda(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      motivo: motivo ?? this.motivo,
      periodo: periodo ?? this.periodo,
      monto: monto ?? this.monto,
      montoCancelado: montoCancelado ?? this.montoCancelado,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      progreso: progreso ?? this.progreso,
      pagoSugerido: pagoSugerido ?? this.pagoSugerido,
      totalPagos: totalPagos ?? this.totalPagos, // NUEVO
    );
  }
}
