// movimiento_repository.dart

import 'movimiento_model.dart';

class MovimientoRepository {
  // Singleton
  MovimientoRepository._privateConstructor();
  static final MovimientoRepository _instance = MovimientoRepository._privateConstructor();
  factory MovimientoRepository() => _instance;

  final List<Movimiento> _movimientos = [];
  double _presupuesto = 0.0;

  List<Movimiento> get movimientos => List.unmodifiable(_movimientos);

  void agregarMovimiento(Movimiento movimiento) {
    _movimientos.add(movimiento);
  }

  void limpiarMovimientos() {
    _movimientos.clear();
  }

  // Presupuesto
  double get presupuesto => _presupuesto;
  set presupuesto(double value) => _presupuesto = value;
}
