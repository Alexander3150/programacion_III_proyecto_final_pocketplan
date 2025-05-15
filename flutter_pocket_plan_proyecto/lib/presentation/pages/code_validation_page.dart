import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/user_model.dart';
import 'login_page.dart';
import 'new_password_page.dart';

/// Paleta de colores modernizada con fondo claro
class RecoveryColors {
  static const Color background = Color(0xFFF5F5F5); // Fondo gris claro
  static const Color primary = Color(0xFF4A8BDF); // Azul moderno
  static const Color secondary = Color(0xFF6D9DB1); // Azul verdoso claro
  static const Color accent = Color(0xFF94B8B5); // Verde azulado claro
  static const Color textDark = Color(0xFF333333); // Texto oscuro
  static const Color textLight = Colors.white; // Texto claro
  static const Color error = Color(0xFFE57373); // Rojo suave para errores
  static const Color success = Color(0xFF81C784); // Verde suave para éxito
  static const Color textField = Colors.white; // Fondo de campos de texto
  static const Color tooltipBackground = Color(
    0xFF616161,
  ); // Fondo para tooltips
}

class CodeValidationPage extends StatefulWidget {
  final String email;
  final String username;

  const CodeValidationPage({
    super.key,
    required this.email,
    required this.username,
  });

  @override
  State<CodeValidationPage> createState() => _CodeValidationPageState();
}

/// Clase que maneja el estado de la página de validación de código
/// Contiene la lógica para validar el código de verificación
class _CodeValidationPageState extends State<CodeValidationPage> {
  // Controlador para el campo de código
  final _codeController = TextEditingController();

  // Variables para manejar errores de validación
  bool _showEmptyError = false;
  bool _showLengthError = false;

  // FocusNode para manejar el enfoque y efectos visuales
  final FocusNode _codeFocusNode = FocusNode();
  Color _codeBorderColor = Colors.grey.shade400;

  // Variables para efectos 3D en botones
  bool _isValidatePressed = false;
  bool _isBackPressed = false;

  @override
  void initState() {
    super.initState();

    // Listener para cambiar el color del borde al enfocar
    _codeFocusNode.addListener(() {
      setState(() {
        _codeBorderColor =
            _codeFocusNode.hasFocus
                ? RecoveryColors.primary
                : Colors.grey.shade400;
      });
    });

    // Listener para validación en tiempo real
    _codeController.addListener(_validateCodeLength);
  }

  @override
  void dispose() {
    // Limpieza: libera recursos del controlador y focus node
    _codeController.removeListener(_validateCodeLength);
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  /// Valida la longitud del código en tiempo real
  void _validateCodeLength() {
    if (!mounted) return;

    setState(() {
      _showLengthError =
          _codeController.text.isNotEmpty && _codeController.text.length < 6;
    });
  }

  /// Valida el código ingresado por el usuario
  void _validateCode() {
    setState(() {
      _showEmptyError = _codeController.text.isEmpty;
      _showLengthError =
          _codeController.text.isNotEmpty && _codeController.text.length < 6;
    });

    if (_showEmptyError || _showLengthError) return;

    final code = _codeController.text.trim();
    final email = widget.email;
    final username = widget.username;

    final isValid = UserModel.verifyRecoveryCode(email, username, code);

    if (isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Código validado correctamente'),
          backgroundColor: RecoveryColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    NuevaContrasenaPage(email: email, username: username),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Código incorrecto o expirado'),
          backgroundColor: RecoveryColors.error,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener dimensiones de la pantalla para diseño responsivo
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return Scaffold(
      backgroundColor: RecoveryColors.background,
      appBar: AppBar(
        title: Text(
          'Validación de código',
          style: TextStyle(
            color: RecoveryColors.textLight,
            fontSize: isSmallScreen ? 22 : 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: RecoveryColors.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: RecoveryColors.textLight),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [RecoveryColors.primary, RecoveryColors.secondary],
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20 : size.width * 0.1,
            vertical: isSmallScreen ? 20 : 30,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono con efecto
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: RecoveryColors.accent.withOpacity(0.2),
                  boxShadow: [
                    BoxShadow(
                      color: RecoveryColors.primary.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: RecoveryColors.primary,
                  size: isSmallScreen ? 80 : 100,
                ),
              ),

              SizedBox(height: isSmallScreen ? 30 : 50),

              // Campo de código con tooltip mejorado
              _buildCodeFieldWithTooltip(isSmallScreen),

              SizedBox(height: isSmallScreen ? 40 : 60),

              // Botón de validar con efecto 3D
              _build3DButton(
                onPressed: _validateCode,
                label: 'VALIDAR CÓDIGO',
                icon: Icons.verified,
                isSmallScreen: isSmallScreen,
                width: isSmallScreen ? size.width * 0.8 : size.width * 0.6,
                isPressed: _isValidatePressed,
                onTapDown: () => setState(() => _isValidatePressed = true),
                onTapUp: () => setState(() => _isValidatePressed = false),
              ),

              SizedBox(height: isSmallScreen ? 30 : 40),

              // Botón de volver con efecto 3D
              _build3DTextButton(
                onPressed:
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IniciarSesion(),
                      ),
                    ),
                label: 'VOLVER AL INICIO',
                icon: Icons.arrow_back_rounded,
                isSmallScreen: isSmallScreen,
                isPressed: _isBackPressed,
                onTapDown: () => setState(() => _isBackPressed = true),
                onTapUp: () => setState(() => _isBackPressed = false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget personalizado para el campo de código con tooltip
  Widget _buildCodeFieldWithTooltip(bool isSmallScreen) {
    final errorText =
        _showEmptyError
            ? 'Por favor ingrese el código recibido'
            : _showLengthError
            ? 'El código debe tener 6 dígitos'
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text(
                'Ingrese el código de verificación',
                style: TextStyle(
                  color: RecoveryColors.textDark,
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Tooltip mejorado usando el widget nativo de Flutter
            Tooltip(
              message:
                  'Ingrese el código de verificación que se le envió a su correo electrónico. '
                  'Es un código de 6 dígitos numéricos.',
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 81, 167, 186),
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(color: Colors.white),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Icon(
                  Icons.help_outline,
                  color: RecoveryColors.primary,
                  size: isSmallScreen ? 20 : 22,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: TextField(
            controller: _codeController,
            focusNode: _codeFocusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RecoveryColors.textDark,
              fontSize: isSmallScreen ? 18 : 20,
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isSmallScreen ? 16 : 18,
              ),
              filled: true,
              fillColor: RecoveryColors.textField,
              hintText: 'Ej: 123456',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: isSmallScreen ? 16 : 18,
              ),
              prefixIcon: Icon(
                Icons.confirmation_number_outlined,
                color: _codeBorderColor,
                size: isSmallScreen ? 24 : 28,
              ),
              suffixIcon:
                  errorText != null
                      ? Icon(
                        Icons.error_outline_rounded,
                        color: RecoveryColors.error,
                        size: isSmallScreen ? 24 : 28,
                      )
                      : null,
              errorText: errorText,
              errorStyle: TextStyle(
                color: RecoveryColors.error,
                fontSize: isSmallScreen ? 14 : 15,
              ),
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
                borderSide: BorderSide(color: _codeBorderColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: RecoveryColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: RecoveryColors.error, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Widget para botón con efecto 3D
  Widget _build3DButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required bool isSmallScreen,
    required double width,
    required bool isPressed,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
  }) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTapDown: (_) => onTapDown(),
        onTapUp: (_) => onTapUp(),
        onTapCancel: onTapUp,
        onTap: onPressed,
        child: Transform(
          transform: Matrix4.identity()..translate(0.0, isPressed ? 2.0 : 0.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [RecoveryColors.primary, RecoveryColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow:
                  isPressed
                      ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ]
                      : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 6),
                          blurRadius: 8,
                        ),
                      ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 16 : 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget para botón de texto con efecto 3D
  Widget _build3DTextButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required bool isSmallScreen,
    required bool isPressed,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
  }) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
      onTap: onPressed,
      child: Transform(
        transform: Matrix4.identity()..translate(0.0, isPressed ? 1.0 : 0.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: RecoveryColors.background,
            boxShadow:
                isPressed
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(0, 3),
                        blurRadius: 4,
                      ),
                    ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: RecoveryColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: RecoveryColors.primary,
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  decoration: TextDecoration.underline,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
