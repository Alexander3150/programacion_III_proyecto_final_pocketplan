import 'package:flutter/material.dart';

import '../../data/models/movimiento_model.dart';
import '../../data/models/repositories/movimiento_repository.dart';

class MovimientosTarjetaPage extends StatefulWidget {
  final int userId;
  final int tarjetaId;
  final String tipoTarjeta;
  final String titulo;

  const MovimientosTarjetaPage({
    super.key,
    required this.userId,
    required this.tarjetaId,
    required this.tipoTarjeta,
    required this.titulo,
  });

  @override
  State<MovimientosTarjetaPage> createState() => _MovimientosTarjetaPageState();
}

class _MovimientosTarjetaPageState extends State<MovimientosTarjetaPage> {
  final MovimientoRepository _repo = MovimientoRepository();
  bool _loading = true;
  List<Movimiento> _movimientos = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final movimientos = await _repo.getMovimientosByTarjeta(
      widget.userId,
      widget.tarjetaId,
      widget.tipoTarjeta,
    );
    if (!mounted) return;
    setState(() {
      _movimientos = movimientos;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        centerTitle: true,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _movimientos.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                itemCount: _movimientos.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final mov = _movimientos[index];
                  final isIngreso = mov.tipo.toLowerCase() == 'ingreso';
                  return ListTile(
                    leading: Icon(
                      isIngreso
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: isIngreso ? Colors.green : Colors.red,
                    ),
                    title: Text(mov.concepto),
                    subtitle: Text(
                      '${mov.fecha.day.toString().padLeft(2, '0')}/${mov.fecha.month.toString().padLeft(2, '0')}/${mov.fecha.year} - ${mov.etiqueta}',
                    ),
                    trailing: Text(
                      'Q${mov.monto.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isIngreso ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No hay movimientos asociados a esta tarjeta',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
