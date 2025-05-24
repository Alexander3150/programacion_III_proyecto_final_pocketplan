import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/credit_card_model.dart';
import '../../data/models/repositories/tarjeta_credito_repository.dart';
import '../providers/user_provider.dart';
import '../widgets/global_components.dart';
import 'history_cards_screen.dart';

// ------------ FUNCIÓN UTILIDAD PARA OBTENER ID DE USUARIO ACTUAL -------------
int getCurrentUserId(BuildContext context) {
  final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
  return usuarioProvider.usuario?.id ?? 0;
}

// ---------------------------------------------------------------------------
class CardColors {
  // Paleta de colores azulados para crédito
  static const Color background = Color(0xFFF5F9FD);
  static const Color primary = Color(0xFF2C3E50);
  static const Color secondary = Color(0xFF00B0FF);
  static const Color accent = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Colors.white;
}

class ModificacionDetalleTarjetaCreditoScreen extends StatelessWidget {
  final CreditCard tarjeta;
  final bool modoEdicion;

  const ModificacionDetalleTarjetaCreditoScreen({
    super.key,
    required this.tarjeta,
    this.modoEdicion = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: modoEdicion ? 'Modificar Tarjeta' : 'Detalles de Tarjeta',
      body: _ModificacionDetalleTarjetaCreditoContent(
        tarjeta: tarjeta,
        modoEdicion: modoEdicion,
      ),
      mostrarDrawer: true,
      mostrarBotonHome: true,
      navIndex: 0,
    );
  }
}

class _ModificacionDetalleTarjetaCreditoContent extends StatefulWidget {
  final CreditCard tarjeta;
  final bool modoEdicion;

  const _ModificacionDetalleTarjetaCreditoContent({
    required this.tarjeta,
    required this.modoEdicion,
  });

  @override
  State<_ModificacionDetalleTarjetaCreditoContent> createState() =>
      _ModificacionDetalleTarjetaCreditoContentState();
}

class _ModificacionDetalleTarjetaCreditoContentState
    extends State<_ModificacionDetalleTarjetaCreditoContent> {
  late TextEditingController _bancoController;
  late TextEditingController _numeroTarjetaController;
  late TextEditingController _aliasController;
  late TextEditingController _limiteController;
  late TextEditingController _fechaExpiracionController;
  late TextEditingController _fechaCorteController;
  late TextEditingController _fechaPagoController;

  String? _errorBanco;
  String? _errorNumeroTarjeta;
  String? _errorAlias;
  String? _errorLimite;
  String? _errorFechaExpiracion;
  String? _errorFechaCorte;
  String? _errorFechaPago;

  late final TarjetaCreditoRepository _creditoRepository;
  double saldoActual = 0;

  @override
  void initState() {
    super.initState();
    _bancoController = TextEditingController(text: widget.tarjeta.banco);
    _numeroTarjetaController = TextEditingController(
      text: widget.tarjeta.numero,
    );
    _aliasController = TextEditingController(text: widget.tarjeta.alias);
    _limiteController = TextEditingController(
      text: widget.tarjeta.limite.toString(),
    );
    _fechaExpiracionController = TextEditingController(
      text: widget.tarjeta.expiracion,
    );
    _fechaCorteController = TextEditingController(text: widget.tarjeta.corte);
    _fechaPagoController = TextEditingController(text: widget.tarjeta.pago);

    _creditoRepository = TarjetaCreditoRepository();
    saldoActual = widget.tarjeta.saldo;
    _actualizarDatosDeTarjeta();
  }

  // Cargar la tarjeta desde BD para tener el saldo actualizado en todo momento
  Future<void> _actualizarDatosDeTarjeta() async {
    final userId = getCurrentUserId(context);
    final tarjetaActualizada = await _creditoRepository.getTarjetaCreditoById(
      widget.tarjeta.id!,
      userId,
    );
    if (tarjetaActualizada != null) {
      setState(() {
        saldoActual = tarjetaActualizada.saldo;
      });
    }
  }

  @override
  void dispose() {
    _bancoController.dispose();
    _numeroTarjetaController.dispose();
    _aliasController.dispose();
    _limiteController.dispose();
    _fechaExpiracionController.dispose();
    _fechaCorteController.dispose();
    _fechaPagoController.dispose();
    super.dispose();
  }

  void _validarFechaExpiracion(String value) {
    if (value.isEmpty) {
      setState(() => _errorFechaExpiracion = 'Ingrese la fecha de expiración');
      return;
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      setState(() => _errorFechaExpiracion = 'Formato inválido (MM/AA)');
      return;
    }
    final parts = value.split('/');
    final mes = int.tryParse(parts[0]) ?? 0;
    final anio = int.tryParse(parts[1]) ?? 0;
    if (mes < 1 || mes > 12) {
      setState(() => _errorFechaExpiracion = 'Mes inválido (1-12)');
      return;
    }
    final currentYear = DateTime.now().year % 100;
    if (anio < currentYear) {
      setState(
        () => _errorFechaExpiracion = 'Año no puede ser anterior al actual',
      );
      return;
    }
    setState(() => _errorFechaExpiracion = null);
  }

  void _validarDia(String value, String campo) {
    if (value.isEmpty) {
      if (campo == 'corte') {
        setState(() => _errorFechaCorte = 'Ingrese el día de corte');
      } else {
        setState(() => _errorFechaPago = 'Ingrese el día de pago');
      }
      return;
    }
    final dia = int.tryParse(value) ?? 0;
    if (dia < 1 || dia > 31) {
      if (campo == 'corte') {
        setState(() => _errorFechaCorte = 'Día inválido (1-31)');
      } else {
        setState(() => _errorFechaPago = 'Día inválido (1-31)');
      }
      return;
    }
    if (campo == 'corte') {
      setState(() => _errorFechaCorte = null);
    } else {
      setState(() => _errorFechaPago = null);
    }
  }

  void _validarCampos() {
    setState(() {
      // Banco: requerido y máximo 50 caracteres
      if (_bancoController.text.isEmpty) {
        _errorBanco = 'Ingrese el banco';
      } else if (_bancoController.text.length > 50) {
        _errorBanco = 'Máx. 50 caracteres';
      } else {
        _errorBanco = null;
      }

      // Número de tarjeta: requerido y exactamente 4 dígitos
      if (_numeroTarjetaController.text.isEmpty) {
        _errorNumeroTarjeta = 'Ingrese el número';
      } else if (_numeroTarjetaController.text.length != 4) {
        _errorNumeroTarjeta = 'Debe tener 4 dígitos';
      } else {
        _errorNumeroTarjeta = null;
      }

      // Nombre del titular: requerido y máximo 50 caracteres
      if (_aliasController.text.isEmpty) {
        _errorAlias = 'Ingrese el nombre del titular';
      } else if (_aliasController.text.length > 50) {
        _errorAlias = 'Máx. 50 caracteres';
      } else {
        _errorAlias = null;
      }

      // Límite: requerido
      _errorLimite =
          _limiteController.text.isEmpty ? 'Ingrese el límite' : null;

      // Fecha de expiración: requerido y formato
      if (_fechaExpiracionController.text.isEmpty) {
        _errorFechaExpiracion = 'Ingrese la fecha de expiración';
      } else {
        _validarFechaExpiracion(_fechaExpiracionController.text);
      }

      // Día de corte: requerido
      _errorFechaCorte =
          _fechaCorteController.text.isEmpty ? 'Ingrese el día de corte' : null;

      // Día de pago: requerido
      _errorFechaPago =
          _fechaPagoController.text.isEmpty ? 'Ingrese el día de pago' : null;
    });
  }

  /// ACTUALIZA la tarjeta en la base de datos y también el saldo si el límite fue cambiado
  Future<void> _actualizarTarjeta() async {
    if (!widget.modoEdicion) return;
    _validarCampos();

    final userId = getCurrentUserId(context);

    if (_errorBanco == null &&
        _errorNumeroTarjeta == null &&
        _errorAlias == null &&
        _errorLimite == null &&
        _errorFechaExpiracion == null &&
        _errorFechaCorte == null &&
        _errorFechaPago == null) {
      final nuevoLimite = double.tryParse(_limiteController.text) ?? 0.0;
      final limiteAnterior = widget.tarjeta.limite;
      double nuevoSaldo = saldoActual;

      // Lógica robusta para manejar límite en 0
      if (limiteAnterior == 0 && nuevoLimite > 0) {
        // Si el límite anterior era 0 y se sube, solo suma la diferencia hasta máximo el nuevo límite
        // Pero si hubo gastos, el saldo debería ser: limiteNuevo - (limiteAnterior - saldoActual)
        // Pero como limiteAnterior es 0, saldoActual es 0, así que saldo debe ser igual a la diferencia (nuevoLimite)
        nuevoSaldo = nuevoLimite;
      } else if (nuevoLimite == 0) {
        // Si el límite nuevo es 0, el saldo debería ser 0
        nuevoSaldo = 0;
      } else if (nuevoLimite != limiteAnterior) {
        // Si hay un cambio normal
        final diferencia = nuevoLimite - limiteAnterior;
        nuevoSaldo += diferencia;

        // Reglas para no pasarse ni quedarse negativo
        if (nuevoSaldo > nuevoLimite) nuevoSaldo = nuevoLimite;
        if (nuevoSaldo < 0) nuevoSaldo = 0;
      }

      final tarjetaActualizada = CreditCard(
        id: widget.tarjeta.id,
        userId: userId,
        banco: _bancoController.text,
        numero: _numeroTarjetaController.text,
        alias: _aliasController.text,
        limite: nuevoLimite,
        saldo: nuevoSaldo,
        expiracion: _fechaExpiracionController.text,
        corte: _fechaCorteController.text,
        pago: _fechaPagoController.text,
      );

      final result = await _creditoRepository.updateTarjetaCredito(
        tarjetaActualizada,
      );

      if (result > 0) {
        setState(() {
          saldoActual = nuevoSaldo;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tarjeta actualizada con éxito'),
            backgroundColor: CardColors.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HistoryCardsScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo actualizar la tarjeta'),
            backgroundColor: CardColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        color: CardColors.background,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono de tarjeta de crédito
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: CardColors.secondary.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 3,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.credit_card,
                    color: CardColors.secondary,
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Banco (máx 50 caracteres)
              _buildTextFieldWithIcon(
                controller: _bancoController,
                label: 'Banco',
                hint: 'Ej. Banco Industrial',
                icon: Icons.account_balance,
                errorText: _errorBanco,
                editable: widget.modoEdicion,
                maxLength: 50,
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
              ),
              const SizedBox(height: 16),

              // Número de tarjeta (exactamente 4)
              _buildTextFieldWithIcon(
                controller: _numeroTarjetaController,
                label: 'Número de tarjeta',
                hint: 'Ingrese los últimos 4 dígitos',
                icon: Icons.credit_card,
                errorText: _errorNumeroTarjeta,
                editable: widget.modoEdicion,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                helperText:
                    'Por temas de seguridad, solo ingrese los últimos 4 dígitos de su tarjeta. Esto ayuda a proteger sus datos.',
              ),
              const SizedBox(height: 16),

              // Nombre del titular (máx 40 caracteres)
              _buildTextFieldWithIcon(
                controller: _aliasController,
                label: 'Nombre del titular',
                hint: 'Ej. Pocket Plan',
                icon: Icons.label,
                errorText: _errorAlias,
                editable: widget.modoEdicion,
                maxLength: 40,
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextFieldWithIcon(
                      controller: _limiteController,
                      label: 'Límite de crédito',
                      hint: 'Ej. 5000',
                      icon: Icons.monetization_on,
                      errorText: _errorLimite,
                      editable: widget.modoEdicion,
                      keyboardType: TextInputType.number,
                      maxLength: 9, // máximo 9 dígitos (ajústalo si necesitas)
                      helperText:
                          'Ingrese el monto límite que su banco ha asignado a esta tarjeta de crédito.',
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(
                          9,
                        ), // <- límite de caracteres
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildExpirationDateField()),
                ],
              ),
              const SizedBox(height: 16),

              // --------- CAMPO DE SALDO SOLO EN DETALLE (NO EDITABLE) -----------
              if (!widget.modoEdicion) ...[
                _buildSaldoField(saldoActual),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  Expanded(
                    child: _buildDayField(
                      controller: _fechaCorteController,
                      label: 'Día de corte',
                      hint: 'Ej. 15',
                      errorText: _errorFechaCorte,
                      editable: widget.modoEdicion,
                      helperText:
                          'Ingrese el día del mes en que se genera el estado de cuenta de su tarjeta.',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDayField(
                      controller: _fechaPagoController,
                      label: 'Día de pago',
                      hint: 'Ej. 25',
                      errorText: _errorFechaPago,
                      editable: widget.modoEdicion,
                      helperText:
                          'Ingrese el día del mes en que debe realizar el pago de su tarjeta.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Botón de actualizar (solo en modo edición)
              if (widget.modoEdicion)
                Center(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: CardColors.secondary.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: FloatingActionButton(
                          onPressed: _actualizarTarjeta,
                          backgroundColor: CardColors.secondary,
                          elevation: 0,
                          child: const Icon(Icons.save, size: 30),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ACTUALIZAR TARJETA',
                        style: TextStyle(
                          color: CardColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaldoField(double saldo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Saldo actual',
            style: TextStyle(
              color: CardColors.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: TextField(
            enabled: false,
            controller: TextEditingController(
              text: 'Q${saldo.toStringAsFixed(2)}',
            ),
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.account_balance_wallet,
                color: Colors.grey,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              filled: true,
              fillColor: Colors.grey.shade200,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFieldWithIcon({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? errorText,
    required bool editable,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? helperText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                label,
                style: TextStyle(
                  color: CardColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            if (helperText != null && editable) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: helperText,
                triggerMode: TooltipTriggerMode.tap,
                child: const Icon(
                  Icons.help_outline,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(color: CardColors.textDark),
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            // ¡AGREGA ESTA PROPIEDAD PARA OCULTAR EL CONTADOR!
            buildCounter:
                (
                  BuildContext context, {
                  required int currentLength,
                  required bool isFocused,
                  int? maxLength,
                }) => null,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              filled: true,
              fillColor: editable ? Colors.white : Colors.grey.shade200,
              prefixIcon: Icon(
                icon,
                color: editable ? CardColors.secondary : Colors.grey,
              ),
              hintText: hint,
              errorText: editable ? errorText : null,
              errorStyle: TextStyle(color: CardColors.error),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: editable ? CardColors.secondary : Colors.grey,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: CardColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: CardColors.error, width: 2),
              ),
              enabled: editable,
            ),
            onChanged:
                editable
                    ? (_) {
                      setState(() {
                        if (label.contains('Banco')) _errorBanco = null;
                        if (label.contains('Número'))
                          _errorNumeroTarjeta = null;
                        if (label.contains('Alias')) _errorAlias = null;
                        if (label.contains('Límite')) _errorLimite = null;
                      });
                    }
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _buildExpirationDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                'Fecha de expiración',
                style: TextStyle(
                  color: CardColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            if (widget.modoEdicion) ...[
              const SizedBox(width: 8),
              Tooltip(
                message:
                    'Ingrese el mes y año de expiración de su tarjeta en formato MM/AA. Ej: 12/25',
                triggerMode: TooltipTriggerMode.tap,
                child: const Icon(
                  Icons.help_outline,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: TextField(
            controller: _fechaExpiracionController,
            keyboardType: TextInputType.number,
            maxLength: 5,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _ExpirationDateFormatter(),
            ],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              filled: true,
              fillColor:
                  widget.modoEdicion ? Colors.white : Colors.grey.shade200,
              prefixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
              hintText: 'MM/AA',
              errorText: widget.modoEdicion ? _errorFechaExpiracion : null,
              errorStyle: TextStyle(color: CardColors.error),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      widget.modoEdicion ? CardColors.secondary : Colors.grey,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: CardColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: CardColors.error, width: 2),
              ),
              enabled: widget.modoEdicion,
            ),
            onChanged:
                widget.modoEdicion
                    ? (value) {
                      _validarFechaExpiracion(value);
                      if (value.isEmpty) {
                        setState(() => _errorFechaExpiracion = null);
                      }
                    }
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDayField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? errorText,
    required bool editable,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                label,
                style: TextStyle(
                  color: CardColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            if (helperText != null && editable) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: helperText,
                triggerMode: TooltipTriggerMode.tap,
                child: const Icon(
                  Icons.help_outline,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 2,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              filled: true,
              fillColor: editable ? Colors.white : Colors.grey.shade200,
              prefixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
              hintText: hint,
              errorText: editable ? errorText : null,
              errorStyle: TextStyle(color: CardColors.error),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: editable ? CardColors.secondary : Colors.grey,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: CardColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: CardColors.error, width: 2),
              ),
              enabled: editable,
            ),
            onChanged:
                editable
                    ? (value) {
                      if (label.contains('corte')) {
                        _validarDia(value, 'corte');
                      } else {
                        _validarDia(value, 'pago');
                      }
                    }
                    : null,
          ),
        ),
      ],
    );
  }
}

// Formateador personalizado para fecha de expiración MM/AA
class _ExpirationDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var newText = newValue.text;
    if (newText.length > 5) {
      return oldValue;
    }
    newText = newText.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.length >= 2) {
      newText = '${newText.substring(0, 2)}/${newText.substring(2)}';
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
