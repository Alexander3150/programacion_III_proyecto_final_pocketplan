class SimuladorAhorro {
  final int? id;
  final int userId;
  final String objetivo;
  final String periodo;
  final double monto;
  final double montoInicial;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final double progreso;
  final double cuotaSugerida;
  final int totalPagos; // NUEVO

  SimuladorAhorro({
    this.id,
    required this.userId,
    required this.objetivo,
    required this.periodo,
    required this.monto,
    required this.montoInicial,
    required this.fechaInicio,
    required this.fechaFin,
    this.progreso = 0.0,
    this.cuotaSugerida = 0.0,
    required this.totalPagos, // NUEVO
  });

  factory SimuladorAhorro.fromMap(Map<String, dynamic> map) {
    double castToDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is int) return v.toDouble();
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return SimuladorAhorro(
      id: map['id'] as int?,
      userId: map['user_id'],
      objetivo: map['objetivo'] ?? '',
      periodo: map['periodo'] ?? '',
      monto: castToDouble(map['monto']),
      montoInicial: castToDouble(map['monto_inicial']),
      fechaInicio: DateTime.parse(map['fecha_inicio']),
      fechaFin: DateTime.parse(map['fecha_fin']),
      progreso: castToDouble(map['progreso']),
      cuotaSugerida: castToDouble(map['cuota_sugerida']),
      totalPagos: map['total_pagos'] ?? 0, // NUEVO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'objetivo': objetivo,
      'periodo': periodo,
      'monto': monto,
      'monto_inicial': montoInicial,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin.toIso8601String(),
      'progreso': progreso,
      'cuota_sugerida': cuotaSugerida,
      'total_pagos': totalPagos, // NUEVO
    };
  }

  SimuladorAhorro copyWith({
    int? id,
    int? userId,
    String? objetivo,
    String? periodo,
    double? monto,
    double? montoInicial,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    double? progreso,
    double? cuotaSugerida,
    int? totalPagos, // NUEVO
  }) {
    return SimuladorAhorro(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      objetivo: objetivo ?? this.objetivo,
      periodo: periodo ?? this.periodo,
      monto: monto ?? this.monto,
      montoInicial: montoInicial ?? this.montoInicial,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      progreso: progreso ?? this.progreso,
      cuotaSugerida: cuotaSugerida ?? this.cuotaSugerida,
      totalPagos: totalPagos ?? this.totalPagos, // NUEVO
    );
  }
}
