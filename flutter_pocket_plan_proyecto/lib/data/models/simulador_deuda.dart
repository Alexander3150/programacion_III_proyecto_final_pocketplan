class SimuladorDeuda {
  String motivo;
  String periodo;
  double monto;
  double montoCancelado;
  DateTime fechaInicio;
  DateTime fechaFin;
  double progreso;

  SimuladorDeuda({
    required this.motivo,
    required this.periodo,
    required this.monto,
    required this.montoCancelado,
    required this.fechaInicio,
    required this.fechaFin,
    this.progreso = 0.0,
  });
}
