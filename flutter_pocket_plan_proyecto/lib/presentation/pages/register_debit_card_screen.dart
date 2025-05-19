import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/card_manager.dart';
import '../widgets/global_components.dart';
import 'history_cards_screen.dart';
import 'register_credi_cart_screen.dart';

class DebitCardColors {
  // Paleta de colores verdosos para débito
  static const Color background = Color(0xFFF5FDF7);
  static const Color primary = Color(0xFF2E7D32);
  static const Color secondary = Color(0xFF4CAF50);
  static const Color accent = Color(0xFF00B0FF);
  static const Color error = Color(0xFFE53935);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Colors.white;
}

class RegisterDebitCardScreen extends StatelessWidget {
  const RegisterDebitCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: 'Registrar Tarjeta de Débito',
      body: const _RegisterDebitCardContent(),
      mostrarDrawer: true,
      mostrarBotonHome: true,
      navIndex: 0,
    );
  }
}

class _RegisterDebitCardContent extends StatefulWidget {
  const _RegisterDebitCardContent();

  @override
  State<_RegisterDebitCardContent> createState() =>
      _RegisterDebitCardContentState();
}

class _RegisterDebitCardContentState extends State<_RegisterDebitCardContent> {
  final TextEditingController _bancoController = TextEditingController();
  final TextEditingController _numeroTarjetaController =
      TextEditingController();
  final TextEditingController _aliasController = TextEditingController();
  final TextEditingController _fechaExpiracionController =
      TextEditingController();

  // Variables de estado y validación
  String tipoSeleccionado = 'Débito';
  String? _errorBanco;
  String? _errorNumeroTarjeta;
  String? _errorAlias;
  String? _errorFechaExpiracion;

  // FocusNodes para manejar el enfoque
  final FocusNode _bancoFocusNode = FocusNode();
  final FocusNode _numeroTarjetaFocusNode = FocusNode();
  final FocusNode _aliasFocusNode = FocusNode();
  final FocusNode _fechaExpiracionFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _setupFocusListeners();
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
    super.dispose();
  }

  void _validarFechaExpiracion(String value) {
    if (value.isEmpty) {
      setState(() => _errorFechaExpiracion = 'Ingrese la fecha de expiración');
      return;
    }

    // Validar formato MM/AA (2 dígitos para el año)
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

    // Validar año (no menor al actual - solo últimos 2 dígitos)
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
      _errorBanco = _bancoController.text.isEmpty ? 'Ingrese el banco' : null;
      _errorNumeroTarjeta =
          _numeroTarjetaController.text.isEmpty ? 'Ingrese el número' : null;
      _errorAlias =
          _aliasController.text.isEmpty
              ? 'Ingrese el nombre del titular'
              : null;

      if (_fechaExpiracionController.text.isEmpty) {
        _errorFechaExpiracion = 'Ingrese la fecha de expiración';
      }
    });
  }

  void _guardarTarjeta() {
    _validarCampos();

    if (_errorBanco == null &&
        _errorNumeroTarjeta == null &&
        _errorAlias == null &&
        _errorFechaExpiracion == null) {
      final nuevaTarjeta = DebitCard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        banco: _bancoController.text,
        numero: _numeroTarjetaController.text,
        alias: _aliasController.text,
        expiracion: _fechaExpiracionController.text,
      );

      CardManager().addDebitCard(nuevaTarjeta);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tarjeta de débito guardada con éxito'),
          backgroundColor: DebitCardColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      _limpiarCampos();
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
    _fechaExpiracionController.clear();
    setState(() {
      _errorBanco = null;
      _errorNumeroTarjeta = null;
      _errorAlias = null;
      _errorFechaExpiracion = null;
    });
  }

  void _navegarAPantallaCredito() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterCreditCardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Color(0xFF4CAF50),
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Selector de tipo de tarjeta
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
                    isSelected: [true, false],
                    onPressed: (index) {
                      if (index == 1) _navegarAPantallaCredito();
                    },
                    borderRadius: BorderRadius.circular(30),
                    selectedColor: Colors.white,
                    fillColor: DebitCardColors.secondary,
                    color: DebitCardColors.textDark,
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
                            Icon(Icons.account_balance_wallet, size: 20),
                            SizedBox(width: 8),
                            Text('Débito'),
                          ],
                        ),
                      ),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Campo de banco
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

              // Campo de número de tarjeta con tooltip
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

              // Campo de alias
              _buildTextFieldWithIcon(
                controller: _aliasController,
                label: 'Nombre del titular',
                hint: 'Ej. Pocket Plan',
                icon: Icons.label,
                errorText: _errorAlias,
                focusNode: _aliasFocusNode,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),

              // Campo de fecha de expiración con tooltip y entrada manual
              _buildExpirationDateField(),
              const SizedBox(height: 32),

              // Botón de guardar
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
                        onPressed: _guardarTarjeta,
                        backgroundColor: DebitCardColors.secondary,
                        elevation: 0,
                        child: const Icon(Icons.save, size: 30),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'GUARDAR TARJETA',
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
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(
                icon,
                color:
                    focusNode.hasFocus
                        ? DebitCardColors.secondary
                        : Colors.grey,
              ),
              hintText: hint,
              errorText: errorText,
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
                  color: DebitCardColors.secondary,
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
                (_) => setState(() {
                  if (label.contains('Banco')) _errorBanco = null;
                  if (label.contains('Número')) _errorNumeroTarjeta = null;
                  if (label.contains('Alias')) _errorAlias = null;
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
                  color: DebitCardColors.textDark,
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
                  color: DebitCardColors.secondary,
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
