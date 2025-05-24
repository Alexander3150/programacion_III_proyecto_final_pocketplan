import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/repositories/usuario_repository.dart';

class PasswordColors {
  static const Color background = Color(0xFFF5F5F5);
  static const Color primary = Color(0xFF4A8BDF);
  static const Color secondary = Color(0xFF6D9DB1);
  static const Color accent = Color(0xFF94B8B5);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Colors.white;
  static const Color error = Color(0xFFE57373);
  static const Color success = Color(0xFF81C784);
  static const Color textField = Colors.white;
  static const Color buttonShadow = Color(0x554A8BDF);
}

class NuevaContrasenaPage extends StatefulWidget {
  final String email;
  final String username;

  const NuevaContrasenaPage({
    super.key,
    required this.email,
    required this.username,
  });

  @override
  _NuevaContrasenaPageState createState() => _NuevaContrasenaPageState();
}

class _NuevaContrasenaPageState extends State<NuevaContrasenaPage> {
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _confirmarContrasenaController =
      TextEditingController();

  bool _obscureContrasena = true;
  bool _obscureConfirmarContrasena = true;

  String? _errorTextoContrasena;
  String? _errorTextoConfirmarContrasena;

  final FocusNode _contrasenaFocusNode = FocusNode();
  final FocusNode _confirmarContrasenaFocusNode = FocusNode();

  Color _contrasenaBorderColor = Colors.grey.shade400;
  Color _confirmarContrasenaBorderColor = Colors.grey.shade400;

  bool _isSavePressed = false;
  bool _isBackPressed = false;
  bool _isProcessing = false;
  bool _successShown = false;

  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  @override
  void initState() {
    super.initState();
    _contrasenaFocusNode.addListener(() {
      setState(() {
        _contrasenaBorderColor =
            _contrasenaFocusNode.hasFocus
                ? PasswordColors.primary
                : Colors.grey.shade400;
      });
    });

    _confirmarContrasenaFocusNode.addListener(() {
      setState(() {
        _confirmarContrasenaBorderColor =
            _confirmarContrasenaFocusNode.hasFocus
                ? PasswordColors.primary
                : Colors.grey.shade400;
      });
    });

    _contrasenaController.addListener(_validatePassword);
    _confirmarContrasenaController.addListener(_validatePasswordConfirmation);
  }

  @override
  void dispose() {
    _contrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    _contrasenaFocusNode.dispose();
    _confirmarContrasenaFocusNode.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = _contrasenaController.text;
    setState(() {
      if (password.isEmpty) {
        _errorTextoContrasena = 'Por favor, ingrese la contraseña';
      } else if (password.length < 8) {
        _errorTextoContrasena = 'Mínimo 8 caracteres';
      } else if (password.length > 20) {
        _errorTextoContrasena = 'Máximo 20 caracteres';
      } else {
        _errorTextoContrasena = null;
      }
    });
    _validatePasswordConfirmation();
  }

  void _validatePasswordConfirmation() {
    final password = _contrasenaController.text;
    final confirmation = _confirmarContrasenaController.text;
    setState(() {
      if (confirmation.isEmpty) {
        _errorTextoConfirmarContrasena = 'Confirme la contraseña';
      } else if (confirmation.length > 20) {
        _errorTextoConfirmarContrasena = 'Máximo 20 caracteres';
      } else if (password != confirmation) {
        _errorTextoConfirmarContrasena = 'Las contraseñas no coinciden';
      } else {
        _errorTextoConfirmarContrasena = null;
      }
    });
  }

  Future<void> _updatePassword() async {
    _validatePassword();
    _validatePasswordConfirmation();
    if (_errorTextoContrasena == null &&
        _errorTextoConfirmarContrasena == null) {
      setState(() {
        _isProcessing = true;
      });
      await _guardarNuevaContrasena();
    }
  }

  Future<void> _guardarNuevaContrasena() async {
    final user = await _usuarioRepository.getUsuarioByUsername(widget.username);
    if (user == null) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario no encontrado'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final updatedUser = user.copyWith(
      password: _confirmarContrasenaController.text,
      recoveryCode: null,
      codeExpiration: null,
    );
    await _usuarioRepository.updateUsuario(updatedUser);

    setState(() {
      _successShown = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contraseña actualizada exitosamente'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isProcessing = false;
      });
      // Navega y limpia rutas previas
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return WillPopScope(
      onWillPop: () async {
        if (_isProcessing || _successShown) {
          // Bloquea el back físico mientras procesa o al mostrar éxito
          return false;
        } else {
          Navigator.pushReplacementNamed(context, '/login');
          return false;
        }
      },
      child: AbsorbPointer(
        absorbing: _isProcessing || _successShown,
        child: Scaffold(
          backgroundColor: PasswordColors.background,
          appBar: AppBar(
            automaticallyImplyLeading: false, // NO muestra el botón de regreso
            title: Text(
              'Nueva contraseña',
              style: TextStyle(
                color: PasswordColors.textLight,
                fontSize: isSmallScreen ? 22 : 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            centerTitle: true,
            backgroundColor: PasswordColors.primary,
            elevation: 0,
            iconTheme: IconThemeData(color: PasswordColors.textLight),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [PasswordColors.primary, PasswordColors.secondary],
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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PasswordColors.accent.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: PasswordColors.primary.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      color: PasswordColors.primary,
                      size: isSmallScreen ? 70 : 90,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 30 : 40),
                  _buildPasswordField(
                    controller: _contrasenaController,
                    label: 'Nueva Contraseña',
                    errorText: _errorTextoContrasena,
                    focusNode: _contrasenaFocusNode,
                    borderColor: _contrasenaBorderColor,
                    obscureText: _obscureContrasena,
                    onToggleVisibility: () {
                      setState(() {
                        _obscureContrasena = !_obscureContrasena;
                      });
                    },
                    isSmallScreen: isSmallScreen,
                    maxLength: 20,
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 30),
                  _buildPasswordField(
                    controller: _confirmarContrasenaController,
                    label: 'Confirmar Contraseña',
                    errorText: _errorTextoConfirmarContrasena,
                    focusNode: _confirmarContrasenaFocusNode,
                    borderColor: _confirmarContrasenaBorderColor,
                    obscureText: _obscureConfirmarContrasena,
                    onToggleVisibility: () {
                      setState(() {
                        _obscureConfirmarContrasena =
                            !_obscureConfirmarContrasena;
                      });
                    },
                    isSmallScreen: isSmallScreen,
                    maxLength: 20,
                  ),
                  SizedBox(height: isSmallScreen ? 40 : 60),
                  _build3DButton(
                    onPressed:
                        (_isProcessing || _successShown)
                            ? null
                            : _updatePassword,
                    label:
                        (_isProcessing || _successShown)
                            ? 'Guardando...'
                            : 'GUARDAR CONTRASEÑA',
                    icon: Icons.lock_outline,
                    isSmallScreen: isSmallScreen,
                    width: isSmallScreen ? size.width * 0.8 : size.width * 0.6,
                    isPressed: _isSavePressed,
                    onTapDown: () => setState(() => _isSavePressed = true),
                    onTapUp: () => setState(() => _isSavePressed = false),
                    disabled: _isProcessing || _successShown,
                  ),
                  SizedBox(height: isSmallScreen ? 30 : 40),
                  _build3DTextButton(
                    onPressed:
                        (_isProcessing || _successShown)
                            ? null
                            : () => Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            ),
                    label: 'VOLVER AL INICIO',
                    icon: Icons.arrow_back_rounded,
                    isSmallScreen: isSmallScreen,
                    isPressed: _isBackPressed,
                    onTapDown: () => setState(() => _isBackPressed = true),
                    onTapUp: () => setState(() => _isBackPressed = false),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String? errorText,
    required FocusNode focusNode,
    required Color borderColor,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required bool isSmallScreen,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Text(
            label,
            style: TextStyle(
              color: PasswordColors.textDark,
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            maxLength: maxLength,
            inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
            style: TextStyle(
              color: PasswordColors.textDark,
              fontSize: isSmallScreen ? 16 : 18,
            ),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isSmallScreen ? 16 : 18,
              ),
              filled: true,
              fillColor: PasswordColors.textField,
              prefixIcon: Icon(
                Icons.lock_outline,
                color: borderColor,
                size: isSmallScreen ? 22 : 24,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: borderColor,
                  size: isSmallScreen ? 22 : 24,
                ),
                onPressed: onToggleVisibility,
              ),
              errorText: errorText,
              errorStyle: TextStyle(
                color: PasswordColors.error,
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
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: PasswordColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: PasswordColors.error, width: 2),
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            transform:
                Matrix4.identity()
                  ..translate(0.0, isPressed && !disabled ? 4.0 : 0.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [PasswordColors.primary, PasswordColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow:
                  isPressed && !disabled
                      ? [
                        BoxShadow(
                          color: PasswordColors.buttonShadow,
                          offset: const Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ]
                      : [
                        BoxShadow(
                          color: PasswordColors.buttonShadow,
                          offset: const Offset(0, 8),
                          blurRadius: 12,
                          spreadRadius: 1,
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
                      fontSize: isSmallScreen ? 16 : 16,
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform:
              Matrix4.identity()
                ..translate(0.0, isPressed && !disabled ? 1.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: PasswordColors.background,
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
              Icon(icon, color: PasswordColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: PasswordColors.primary,
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
