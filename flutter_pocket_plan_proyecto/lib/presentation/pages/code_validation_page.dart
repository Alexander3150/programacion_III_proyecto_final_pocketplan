import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/repositories/usuario_repository.dart';

import 'new_password_page.dart';

class RecoveryColors {
  static const Color background = Color(0xFFF5F5F5);
  static const Color primary = Color(0xFF4A8BDF);
  static const Color secondary = Color(0xFF6D9DB1);
  static const Color accent = Color(0xFF94B8B5);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Colors.white;
  static const Color error = Color(0xFFE57373);
  static const Color success = Color(0xFF81C784);
  static const Color textField = Colors.white;
  static const Color tooltipBackground = Color(0xFF616161);
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

class _CodeValidationPageState extends State<CodeValidationPage> {
  final _codeController = TextEditingController();

  bool _showEmptyError = false;
  bool _showLengthError = false;
  bool _isValidatePressed = false;
  bool _isResendPressed = false;
  bool _isProcessing = false;
  bool _successShown = false; // Bandera para bloquear todo al éxito

  final FocusNode _codeFocusNode = FocusNode();
  Color _codeBorderColor = Colors.grey.shade400;

  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  @override
  void initState() {
    super.initState();

    _codeFocusNode.addListener(() {
      setState(() {
        _codeBorderColor =
            _codeFocusNode.hasFocus
                ? RecoveryColors.primary
                : Colors.grey.shade400;
      });
    });

    _codeController.addListener(_validateCodeLength);
  }

  @override
  void dispose() {
    _codeController.removeListener(_validateCodeLength);
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  void _validateCodeLength() {
    if (!mounted) return;
    setState(() {
      _showLengthError =
          _codeController.text.isNotEmpty && _codeController.text.length < 6;
    });
  }

  Future<void> _validateCode() async {
    if (_isProcessing || _successShown) return;
    setState(() {
      _isProcessing = true;
      _showEmptyError = _codeController.text.isEmpty;
      _showLengthError =
          _codeController.text.isNotEmpty && _codeController.text.length < 6;
    });

    if (_showEmptyError || _showLengthError) {
      setState(() => _isProcessing = false);
      return;
    }

    final code = _codeController.text.trim();
    final email = widget.email;
    final username = widget.username;

    final user = await _usuarioRepository.getUsuarioByUsername(username);

    bool isValid = false;
    if (user != null &&
        user.email.toLowerCase() == email.toLowerCase() &&
        user.recoveryCode == code &&
        user.codeExpiration != null) {
      final expiration = DateTime.tryParse(user.codeExpiration!);

      if (expiration != null && DateTime.now().isBefore(expiration)) {
        isValid = true;
      }
    }

    if (isValid) {
      setState(() {
        _successShown = true; // Bloquea todo
      });
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    NuevaContrasenaPage(email: email, username: username),
          ),
        );
      });
    } else {
      setState(() {
        _isProcessing = false;
      });
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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return WillPopScope(
      onWillPop: () async {
        if (_isProcessing || _successShown) {
          // Bloquea el botón físico de atrás si está procesando o en éxito
          return false;
        } else {
          Navigator.pushReplacementNamed(context, '/login');
          return false;
        }
      },
      child: AbsorbPointer(
        absorbing:
            _isProcessing ||
            _successShown, // Bloquea toda la UI al procesar/exito
        child: Scaffold(
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed:
                  (_isProcessing || _successShown)
                      ? null
                      : () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
              tooltip: "Volver a inicio de sesión",
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
                  _buildCodeFieldWithTooltip(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 40 : 60),
                  _build3DButton(
                    onPressed:
                        (_isProcessing || _successShown) ? null : _validateCode,
                    label: 'VALIDAR CÓDIGO',
                    icon: Icons.verified,
                    isSmallScreen: isSmallScreen,
                    width: isSmallScreen ? size.width * 0.8 : size.width * 0.6,
                    isPressed: _isValidatePressed,
                    onTapDown: () => setState(() => _isValidatePressed = true),
                    onTapUp: () => setState(() => _isValidatePressed = false),
                    disabled: _isProcessing || _successShown,
                  ),
                  SizedBox(height: isSmallScreen ? 30 : 40),
                  _build3DTextButton(
                    onPressed:
                        (_isProcessing || _successShown)
                            ? null
                            : () {
                              Navigator.pushReplacementNamed(
                                context,
                                '/recover_password',
                              );
                            },
                    label: 'REENVIAR CÓDIGO',
                    icon: Icons.refresh_rounded,
                    isSmallScreen: isSmallScreen,
                    isPressed: _isResendPressed,
                    onTapDown: () => setState(() => _isResendPressed = true),
                    onTapUp: () => setState(() => _isResendPressed = false),
                    disabled: _isProcessing || _successShown,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
            Tooltip(
              message:
                  'Ingrese el código de verificación que se le envió a su correo electrónico. Es un código de 6 dígitos numéricos.',
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

  Widget _build3DButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    required bool isSmallScreen,
    required double width,
    required bool isPressed,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
    bool disabled = false,
  }) {
    return SizedBox(
      width: width,
      child: Opacity(
        opacity: disabled ? 0.6 : 1.0,
        child: GestureDetector(
          onTapDown: disabled ? null : (_) => onTapDown(),
          onTapUp: disabled ? null : (_) => onTapUp(),
          onTapCancel: disabled ? null : onTapUp,
          onTap: disabled ? null : onPressed,
          child: Transform(
            transform:
                Matrix4.identity()
                  ..translate(0.0, isPressed && !disabled ? 2.0 : 0.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [RecoveryColors.primary, RecoveryColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow:
                    isPressed && !disabled
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
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 16 : 18,
                ),
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
      ),
    );
  }

  Widget _build3DTextButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    required bool isSmallScreen,
    required bool isPressed,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
    bool disabled = false,
  }) {
    return Opacity(
      opacity: disabled ? 0.6 : 1.0,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => onTapDown(),
        onTapUp: disabled ? null : (_) => onTapUp(),
        onTapCancel: disabled ? null : onTapUp,
        onTap: disabled ? null : onPressed,
        child: Transform(
          transform:
              Matrix4.identity()
                ..translate(0.0, isPressed && !disabled ? 1.0 : 0.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: RecoveryColors.background,
              boxShadow:
                  isPressed && !disabled
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
      ),
    );
  }
}
