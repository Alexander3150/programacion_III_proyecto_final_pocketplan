import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/card_manager.dart';
import '../widgets/global_components.dart';
import 'history_cards_screen.dart';
import 'register_debit_card_screen.dart';

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

class RegisterCreditCardScreen extends StatelessWidget {
  const RegisterCreditCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: 'Registrar Tarjeta de Crédito',
      body: const _RegisterCreditCardContent(),
      mostrarDrawer: true,
      mostrarBotonHome: true,
      navIndex: 0,
    );
  }
}

class _RegisterCreditCardContent extends StatefulWidget {
  const _RegisterCreditCardContent();

  @override
  State<_RegisterCreditCardContent> createState() =>
      _RegisterCreditCardContentState();
}

class _RegisterCreditCardContentState
    extends State<_RegisterCreditCardContent> {
  final TextEditingController _bancoController = TextEditingController();
  final TextEditingController _numeroTarjetaController =
      TextEditingController();
  final TextEditingController _aliasController = TextEditingController();
  final TextEditingController _limiteController = TextEditingController();
  final TextEditingController _fechaExpiracionController =
      TextEditingController();
  final TextEditingController _fechaCorteController = TextEditingController();
  final TextEditingController _fechaPagoController = TextEditingController();

  // Variables de estado y validación
  String tipoSeleccionado = 'Crédito';
  String? _errorBanco;
  String? _errorNumeroTarjeta;
  String? _errorAlias;
  String? _errorLimite;
  String? _errorFechaExpiracion;
  String? _errorFechaCorte;
  String? _errorFechaPago;

  // FocusNodes para manejar el enfoque
  final FocusNode _bancoFocusNode = FocusNode();
  final FocusNode _numeroTarjetaFocusNode = FocusNode();
  final FocusNode _aliasFocusNode = FocusNode();
  final FocusNode _limiteFocusNode = FocusNode();
  final FocusNode _fechaExpiracionFocusNode = FocusNode();
  final FocusNode _fechaCorteFocusNode = FocusNode();
  final FocusNode _fechaPagoFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    _bancoFocusNode.addListener(() => setState(() {}));
    _numeroTarjetaFocusNode.addListener(() => setState(() {}));
    _aliasFocusNode.addListener(() => setState(() {}));
    _limiteFocusNode.addListener(() => setState(() {}));
    _fechaExpiracionFocusNode.addListener(() => setState(() {}));
    _fechaCorteFocusNode.addListener(() => setState(() {}));
    _fechaPagoFocusNode.addListener(() => setState(() {}));
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

    // Validar formato MM/AA
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      setState(() => _errorFechaExpiracion = 'Formato inválido (MM/AA)');
      return;
    }

    final parts = value.split('/');
    final mes = int.tryParse(parts[0]) ?? 0;
    final anio = int.tryParse(parts[1]) ?? 0;

    // Validar mes (1-12)
    if (mes < 1 || mes > 12) {
      setState(() => _errorFechaExpiracion = 'Mes inválido (1-12)');
      return;
    }

    // Validar año (no menor al actual)
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

    // Validar día (1-31)
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
      _errorBanco = _bancoController.text.isEmpty ? 'Ingrese el banco' : null;
      _errorNumeroTarjeta =
          _numeroTarjetaController.text.isEmpty ? 'Ingrese el número' : null;
      _errorAlias =
          _aliasController.text.isEmpty
              ? 'Ingrese el nombre del titular'
              : null;
      _errorLimite =
          _limiteController.text.isEmpty ? 'Ingrese el límite' : null;

      if (_fechaExpiracionController.text.isEmpty) {
        _errorFechaExpiracion = 'Ingrese la fecha de expiración';
      }

      if (_fechaCorteController.text.isEmpty) {
        _errorFechaCorte = 'Ingrese el día de corte';
      }

      if (_fechaPagoController.text.isEmpty) {
        _errorFechaPago = 'Ingrese el día de pago';
      }
    });
  }

  void _guardarTarjeta() {
    _validarCampos();

    if (_errorBanco == null &&
        _errorNumeroTarjeta == null &&
        _errorAlias == null &&
        _errorLimite == null &&
        _errorFechaExpiracion == null &&
        _errorFechaCorte == null &&
        _errorFechaPago == null) {
      final nuevaTarjeta = CreditCard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        banco: _bancoController.text,
        numero: _numeroTarjetaController.text,
        alias: _aliasController.text,
        limite: double.tryParse(_limiteController.text) ?? 0.0,
        expiracion: _fechaExpiracionController.text,
        corte: _fechaCorteController.text,
        pago: _fechaPagoController.text,
      );

      CardManager().addCreditCard(nuevaTarjeta);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tarjeta de crédito guardada con éxito'),
          backgroundColor: CardColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      _limpiarCampos(); // Opcional: limpia los campos tras guardar
      // Navegar al historial
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HistoryCardsScreen()),
      );
    }
  }

  void _limpiarCampos() {
    _bancoController.clear();
    _numeroTarjetaController.clear();
    _aliasController.clear();
    _limiteController.clear();
    _fechaExpiracionController.clear();
    _fechaCorteController.clear();
    _fechaPagoController.clear();
    setState(() {
      _errorBanco = null;
      _errorNumeroTarjeta = null;
      _errorAlias = null;
      _errorLimite = null;
      _errorFechaExpiracion = null;
      _errorFechaCorte = null;
      _errorFechaPago = null;
    });
  }

  void _navegarAPantallaDebito() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterDebitCardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
                  child: const Icon(
                    Icons.credit_card,
                    color: Color(0xFF00B0FF),
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Selector de tipo de tarjeta (navegación entre crédito/débito)
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ToggleButtons(
                    isSelected: [
                      true,
                      false,
                    ], // Crédito seleccionado por defecto
                    onPressed: (index) {
                      if (index == 1) _navegarAPantallaDebito();
                    },
                    borderRadius: BorderRadius.circular(30),
                    selectedColor: Colors.white,
                    fillColor: CardColors.secondary,
                    color: CardColors.textDark,
                    constraints: BoxConstraints(
                      minWidth: size.width * 0.3,
                      minHeight: 45,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.credit_card, size: 20),
                            SizedBox(width: 8),
                            Text('Crédito'),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.account_balance_wallet, size: 20),
                            SizedBox(width: 8),
                            Text('Débito'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Campos del formulario
              _buildTextFieldWithIcon(
                controller: _bancoController,
                label: 'Banco',
                hint: 'Ej. Banco Industrial',
                icon: Icons.account_balance,
                errorText: _errorBanco,
                focusNode: _bancoFocusNode,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),

              _buildTextFieldWithIcon(
                controller: _numeroTarjetaController,
                label: 'Número de tarjeta',
                hint: 'Ingrese los últimos 4 dígitos',
                icon: Icons.credit_card,
                errorText: _errorNumeroTarjeta,
                focusNode: _numeroTarjetaFocusNode,
                keyboardType: TextInputType.number,
                maxLength: 4,
                helperText:
                    'Por temas de seguridad, solo ingrese los últimos 4 dígitos de su tarjeta. Esto ayuda a proteger sus datos.',
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),

              _buildTextFieldWithIcon(
                controller: _aliasController,
                label: 'Nombre del titular ',
                hint: 'Ej. Pocket Plan',
                icon: Icons.label,
                errorText: _errorAlias,
                focusNode: _aliasFocusNode,
                keyboardType: TextInputType.text,
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
                      focusNode: _limiteFocusNode,
                      keyboardType: TextInputType.number,
                      helperText:
                          'Ingrese el monto límite que su banco ha asignado a esta tarjeta de crédito.',
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildExpirationDateField()),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildDayField(
                      controller: _fechaCorteController,
                      label: 'Día de corte',
                      hint: 'Ej. 15',
                      errorText: _errorFechaCorte,
                      focusNode: _fechaCorteFocusNode,
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
                      focusNode: _fechaPagoFocusNode,
                      helperText:
                          'Ingrese el día del mes en que debe realizar el pago de su tarjeta.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Botón de guardar
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
                        onPressed: _guardarTarjeta,
                        backgroundColor: CardColors.secondary,
                        elevation: 0,
                        child: const Icon(Icons.save, size: 30),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'GUARDAR TARJETA',
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

  Widget _buildTextFieldWithIcon({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? errorText,
    required FocusNode focusNode,
    required TextInputType keyboardType,
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
            if (helperText != null) ...[
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
            style: TextStyle(color: CardColors.textDark),
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon:
                  label.contains('Límite')
                      ? const Icon(Icons.monetization_on, color: Colors.green)
                      : Icon(
                        icon,
                        color:
                            focusNode.hasFocus
                                ? CardColors.secondary
                                : Colors.grey,
                      ),
              hintText: hint,
              errorText: errorText,
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
                borderSide: BorderSide(color: CardColors.secondary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: CardColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: CardColors.error, width: 2),
              ),
            ),
            onChanged:
                (_) => setState(() {
                  if (label.contains('Banco')) _errorBanco = null;
                  if (label.contains('Número')) _errorNumeroTarjeta = null;
                  if (label.contains('Alias')) _errorAlias = null;
                  if (label.contains('Límite')) _errorLimite = null;
                }),
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
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
              hintText: 'MM/AA',
              errorText: _errorFechaExpiracion,
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
                borderSide: BorderSide(color: CardColors.secondary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: CardColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: CardColors.error, width: 2),
              ),
            ),
            onChanged: (value) {
              _validarFechaExpiracion(value);
              if (value.isEmpty) {
                setState(() => _errorFechaExpiracion = null);
              }
            },
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
    required FocusNode focusNode,
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
            if (helperText != null) ...[
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
            keyboardType: TextInputType.number,
            maxLength: 2,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
              hintText: hint,
              errorText: errorText,
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
                borderSide: BorderSide(color: CardColors.secondary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: CardColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: CardColors.error, width: 2),
              ),
            ),
            onChanged: (value) {
              if (label.contains('corte')) {
                _validarDia(value, 'corte');
              } else {
                _validarDia(value, 'pago');
              }
            },
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

    // Eliminar todos los caracteres no numéricos
    newText = newText.replaceAll(RegExp(r'[^0-9]'), '');

    // Insertar la barra después de los primeros 2 dígitos
    if (newText.length >= 2) {
      newText = '${newText.substring(0, 2)}/${newText.substring(2)}';
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
