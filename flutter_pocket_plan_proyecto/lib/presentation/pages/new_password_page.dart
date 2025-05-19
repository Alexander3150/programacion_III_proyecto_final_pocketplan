import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/user_model.dart';
import 'login_page.dart';

/// Paleta de colores Azul claro
class PasswordColors {
  static const Color background = Color(
    0xFFF5F5F5,
  ); // Fondo claro para mejor legibilidad
  static const Color primary = Color(
    0xFF4A8BDF,
  ); // Azul principal para botones y app bar
  static const Color secondary = Color(
    0xFF6D9DB1,
  ); // Azul secundario para gradientes
  static const Color accent = Color(
    0xFF94B8B5,
  ); // Color de acento para detalles
  static const Color textDark = Color(
    0xFF333333,
  ); // Texto oscuro para mejor contraste
  static const Color textLight =
      Colors.white; // Texto claro para fondos oscuros
  static const Color error = Color(
    0xFFE57373,
  ); // Rojo suave para mensajes de error
  static const Color success = Color(
    0xFF81C784,
  ); // Verde suave para mensajes de éxito
  static const Color textField =
      Colors.white; // Fondo blanco para campos de texto
  static const Color buttonShadow = Color(
    0x554A8BDF,
  ); // Color de sombra para botones
}

class NuevaContrasenaPage extends StatefulWidget {
  final String email; // Email del usuario que está cambiando la contraseña
  final String username; // Username del usuario

  const NuevaContrasenaPage({
    super.key,
    required this.email,
    required this.username,
  });

  @override
  _NuevaContrasenaPageState createState() => _NuevaContrasenaPageState();
}

/// Estado de la pantalla de nueva contraseña
///
/// Maneja la lógica de:
/// - Validación de campos en tiempo real
/// - Visibilidad de contraseñas
/// - Efectos 3D en botones
/// - Actualización del modelo de usuario
class _NuevaContrasenaPageState extends State<NuevaContrasenaPage> {
  // Controladores para manejar el texto ingresado en los campos
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _confirmarContrasenaController =
      TextEditingController();

  // Variables de estado para controlar la visibilidad de las contraseñas
  bool _obscureContrasena = true;
  bool _obscureConfirmarContrasena = true;

  // Mensajes de error para validación
  String? _errorTextoContrasena;
  String? _errorTextoConfirmarContrasena;

  // FocusNodes para manejar el enfoque y cambios visuales
  final FocusNode _contrasenaFocusNode = FocusNode();
  final FocusNode _confirmarContrasenaFocusNode = FocusNode();

  // Colores de borde que cambian según el enfoque
  Color _contrasenaBorderColor = Colors.grey.shade400;
  Color _confirmarContrasenaBorderColor = Colors.grey.shade400;

  // Variables para efectos 3D en botones
  bool _isSavePressed = false;
  bool _isBackPressed = false;

  @override
  void initState() {
    super.initState();

    // Listeners para cambiar el color del borde cuando el campo recibe enfoque
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

    // Validación en tiempo real
    _contrasenaController.addListener(_validatePassword);
    _confirmarContrasenaController.addListener(_validatePasswordConfirmation);
  }

  @override
  void dispose() {
    // Limpieza de recursos para evitar memory leaks
    _contrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    _contrasenaFocusNode.dispose();
    _confirmarContrasenaFocusNode.dispose();
    super.dispose();
  }

  /// Valida la contraseña en tiempo real
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

  /// Valida la confirmación de contraseña en tiempo real
  void _validatePasswordConfirmation() {
    final password = _contrasenaController.text;
    final confirmation = _confirmarContrasenaController.text;
    setState(() {
      if (confirmation.isEmpty) {
        _errorTextoConfirmarContrasena = 'Confirme la contraseña';
      } else if (password != confirmation) {
        _errorTextoConfirmarContrasena = 'Las contraseñas no coinciden';
      } else {
        _errorTextoConfirmarContrasena = null;
      }
    });
  }

  /// Actualiza la contraseña en el modelo de usuario
  void _updatePasswordInModel() {
    UserModel.updatePassword(
      widget.email,
      widget.username,
      _contrasenaController.text,
    );
  }

  void _guardarContrasena() {
    // Validamos una última vez antes de proceder
    _validatePassword();
    _validatePasswordConfirmation();

    // Solo proceder si no hay errores
    if (_errorTextoContrasena == null &&
        _errorTextoConfirmarContrasena == null) {
      // Actualizamos el modelo
      print('Intentando actualizar contraseña de:');
      print('Email: ${widget.email}');
      print('Username: ${widget.username}');
      _updatePasswordInModel();

      // Mostrar feedback de éxito al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Contraseña actualizada correctamente'),
          backgroundColor: PasswordColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Navegar después de mostrar el mensaje
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const IniciarSesion()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener dimensiones de pantalla para diseño responsivo
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return Scaffold(
      backgroundColor: PasswordColors.background,
      appBar: AppBar(
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
              // Icono decorativo con efecto visual
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

              // Campo para nueva contraseña
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
                maxLength: 20, // Longitud máxima de 20 caracteres
              ),

              SizedBox(height: isSmallScreen ? 20 : 30),

              // Campo para confirmar contraseña
              _buildPasswordField(
                controller: _confirmarContrasenaController,
                label: 'Confirmar Contraseña',
                errorText: _errorTextoConfirmarContrasena,
                focusNode: _confirmarContrasenaFocusNode,
                borderColor: _confirmarContrasenaBorderColor,
                obscureText: _obscureConfirmarContrasena,
                onToggleVisibility: () {
                  setState(() {
                    _obscureConfirmarContrasena = !_obscureConfirmarContrasena;
                  });
                },
                isSmallScreen: isSmallScreen,
                maxLength: 20, // Longitud máxima de 20 caracteres
              ),

              SizedBox(height: isSmallScreen ? 40 : 60),

              // Botón principal con efecto 3D mejorado
              _build3DButton(
                onPressed: _guardarContrasena,
                label: 'GUARDAR CONTRASEÑA',
                icon: Icons.lock_outline,
                isSmallScreen: isSmallScreen,
                width: isSmallScreen ? size.width * 0.8 : size.width * 0.6,
                isPressed: _isSavePressed,
                onTapDown: () => setState(() => _isSavePressed = true),
                onTapUp: () => setState(() => _isSavePressed = false),
              ),

              SizedBox(height: isSmallScreen ? 30 : 40),

              // Botón secundario con efecto 3D
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

  /// Widget personalizado para campos de contraseña con validación en tiempo real
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
              counterText: '', // Ocultamos el contador de caracteres
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

  /// Widget para botón con efecto 3D mejorado
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.identity()..translate(0.0, isPressed ? 4.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [PasswordColors.primary, PasswordColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow:
                isPressed
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.identity()..translate(0.0, isPressed ? 1.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: PasswordColors.background,
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
    );
  }
}
