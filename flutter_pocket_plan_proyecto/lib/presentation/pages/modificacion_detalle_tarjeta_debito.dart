import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/debit_card_model.dart';
import '../../data/models/repositories/tarjeta_debito_repository.dart';

import '../widgets/global_components.dart';
import 'history_cards_screen.dart';

class DebitCardColors {
  static const Color background = Color(0xFFF5FDF7);
  static const Color primary = Color(0xFF2E7D32);
  static const Color secondary = Color(0xFF4CAF50);
  static const Color accent = Color(0xFF00B0FF);
  static const Color error = Color(0xFFE53935);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Colors.white;
}

class ModificacionDetalleTarjetaDebitoScreen extends StatelessWidget {
  final DebitCard tarjeta;
  final bool modoEdicion;

  const ModificacionDetalleTarjetaDebitoScreen({
    super.key,
    required this.tarjeta,
    this.modoEdicion = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: modoEdicion ? 'Modificar Tarjeta' : 'Detalles de Tarjeta',
      body: _ModificacionDetalleTarjetaDebitoContent(
        tarjeta: tarjeta,
        modoEdicion: modoEdicion,
      ),
      mostrarDrawer: true,
      mostrarBotonHome: true,
      navIndex: 0,
    );
  }
}

class _ModificacionDetalleTarjetaDebitoContent extends StatefulWidget {
  final DebitCard tarjeta;
  final bool modoEdicion;

  const _ModificacionDetalleTarjetaDebitoContent({
    required this.tarjeta,
    required this.modoEdicion,
  });

  @override
  State<_ModificacionDetalleTarjetaDebitoContent> createState() =>
      _ModificacionDetalleTarjetaDebitoContentState();
}

class _ModificacionDetalleTarjetaDebitoContentState
    extends State<_ModificacionDetalleTarjetaDebitoContent> {
  late TextEditingController _bancoController;
  late TextEditingController _numeroTarjetaController;
  late TextEditingController _aliasController;
  late TextEditingController _fechaExpiracionController;

  String? _errorBanco;
  String? _errorNumeroTarjeta;
  String? _errorAlias;
  String? _errorFechaExpiracion;

  final FocusNode _bancoFocusNode = FocusNode();
  final FocusNode _numeroTarjetaFocusNode = FocusNode();
  final FocusNode _aliasFocusNode = FocusNode();
  final FocusNode _fechaExpiracionFocusNode = FocusNode();

  late final TarjetaDebitoRepository _debitCardRepository;

  @override
  void initState() {
    super.initState();
    _bancoController = TextEditingController(text: widget.tarjeta.banco);
    _numeroTarjetaController = TextEditingController(
      text: widget.tarjeta.numero,
    );
    _aliasController = TextEditingController(text: widget.tarjeta.alias);
    _fechaExpiracionController = TextEditingController(
      text: widget.tarjeta.expiracion,
    );

    _setupFocusListeners();
    _debitCardRepository = TarjetaDebitoRepository();
  }

  void _setupFocusListeners() {
    _bancoFocusNode.addListener(() => setState(() {}));
    _numeroTarjetaFocusNode.addListener(() => setState(() {}));
    _aliasFocusNode.addListener(() => setState(() {}));
    _fechaExpiracionFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _bancoController.dispose();
    _numeroTarjetaController.dispose();
    _aliasController.dispose();
    _fechaExpiracionController.dispose();

    _bancoFocusNode.dispose();
    _numeroTarjetaFocusNode.dispose();
    _aliasFocusNode.dispose();
    _fechaExpiracionFocusNode.dispose();
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

      // Fecha de expiración: requerido y con validación de formato
      if (_fechaExpiracionController.text.isEmpty) {
        _errorFechaExpiracion = 'Ingrese la fecha de expiración';
      } else {
        _validarFechaExpiracion(_fechaExpiracionController.text);
      }
    });
  }

  Future<void> _actualizarTarjeta() async {
    if (!widget.modoEdicion) return;
    _validarCampos();
    if (_errorBanco == null &&
        _errorNumeroTarjeta == null &&
        _errorAlias == null &&
        _errorFechaExpiracion == null) {
      final tarjetaActualizada = DebitCard(
        id: widget.tarjeta.id,
        userId: widget.tarjeta.userId, // <- ¡IMPORTANTE!
        banco: _bancoController.text,
        numero: _numeroTarjetaController.text,
        alias: _aliasController.text,
        expiracion: _fechaExpiracionController.text,
      );

      final result = await _debitCardRepository.updateTarjetaDebito(
        tarjetaActualizada,
      );

      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tarjeta actualizada con éxito'),
            backgroundColor: DebitCardColors.secondary,
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
            backgroundColor: DebitCardColors.error,
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
        color: DebitCardColors.background,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono de tarjeta de débito
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: DebitCardColors.secondary.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 3,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: DebitCardColors.secondary,
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Campos del formulario
              _buildTextFieldWithIcon(
                controller: _bancoController,
                label: 'Banco',
                hint: 'Ej. Banco Industrial',
                icon: Icons.account_balance,
                errorText: _errorBanco,
                editable: widget.modoEdicion,
                focusNode: _bancoFocusNode,
                maxLength: 50,
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
              ),

              const SizedBox(height: 16),

              // Campo de número de tarjeta con tooltip
              _buildTextFieldWithIcon(
                controller: _numeroTarjetaController,
                label: 'Número de tarjeta',
                hint: 'Ingrese los últimos 4 dígitos',
                icon: Icons.credit_card,
                errorText: _errorNumeroTarjeta,
                editable: widget.modoEdicion,
                focusNode: _numeroTarjetaFocusNode,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                helperText:
                    widget.modoEdicion
                        ? 'Por temas de seguridad, solo ingrese los últimos 4 dígitos de su tarjeta. Esto ayuda a proteger sus datos.'
                        : null,
              ),

              const SizedBox(height: 16),

              _buildTextFieldWithIcon(
                controller: _aliasController,
                label: 'Nombre del titular',
                hint: 'Ej. Pocket Plan',
                icon: Icons.label,
                errorText: _errorAlias,
                editable: widget.modoEdicion,
                focusNode: _aliasFocusNode,
                maxLength: 40,
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
              ),

              const SizedBox(height: 16),

              // Campo de fecha de expiración con formato MM/AA
              _buildExpirationDateField(),
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
                              color: DebitCardColors.secondary.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: FloatingActionButton(
                          onPressed: _actualizarTarjeta,
                          backgroundColor: DebitCardColors.secondary,
                          elevation: 0,
                          child: const Icon(Icons.save, size: 30),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ACTUALIZAR TARJETA',
                        style: TextStyle(
                          color: DebitCardColors.secondary,
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

  Widget _buildTextFieldWithIcon({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? errorText,
    required bool editable,
    required FocusNode focusNode,
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
                  color: DebitCardColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            if (helperText != null && label == 'Número de tarjeta') ...[
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
            focusNode: focusNode,
            keyboardType: keyboardType,
            style: TextStyle(color: DebitCardColors.textDark),
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            // Esto oculta el contador aunque haya maxLength:
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
                color:
                    editable
                        ? (focusNode.hasFocus
                            ? const Color.fromARGB(255, 94, 216, 105)
                            : DebitCardColors.secondary)
                        : Colors.grey,
              ),
              hintText: hint,
              errorText: editable ? errorText : null,
              errorStyle: TextStyle(color: DebitCardColors.error),
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
                  color: editable ? DebitCardColors.secondary : Colors.grey,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: DebitCardColors.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: DebitCardColors.error, width: 2),
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
                  color: DebitCardColors.textDark,
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
            focusNode: _fechaExpiracionFocusNode,
            keyboardType: TextInputType.number,
            maxLength: 5,
            enabled: widget.modoEdicion,
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
              prefixIcon: Icon(
                Icons.calendar_today,
                color:
                    _fechaExpiracionFocusNode.hasFocus
                        ? DebitCardColors.secondary
                        : Colors.grey,
              ),
              hintText: 'MM/AA',
              errorText: widget.modoEdicion ? _errorFechaExpiracion : null,
              errorStyle: TextStyle(color: DebitCardColors.error),
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
                      widget.modoEdicion
                          ? DebitCardColors.secondary
                          : Colors.grey,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: DebitCardColors.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: DebitCardColors.error, width: 2),
              ),
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
}

// Formateador personalizado para fecha de expiración MM/AA
class _ExpirationDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var newText = newValue.text;
    if (newText.length > 5) return oldValue;

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
