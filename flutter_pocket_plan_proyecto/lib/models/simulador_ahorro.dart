class SimuladorAhorro {
  String objetivo;
  String periodo;
  double monto;
  double montoInicial;
  DateTime fechaInicio;
  DateTime fechaFin;
  double progreso; // Nuevo campo

  SimuladorAhorro({
    required this.objetivo,
    required this.periodo,
    required this.monto,
    required this.montoInicial,
    required this.fechaInicio,
    required this.fechaFin,
    this.progreso = 0.0,
  });
}
