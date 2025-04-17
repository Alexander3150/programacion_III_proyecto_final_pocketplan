import 'package:flutter/material.dart';
import 'package:flutter_pocket_plan_proyecto/pages/login_page.dart';

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
}

class NuevaContrasenaPage extends StatefulWidget {
  @override
  _NuevaContrasenaPageState createState() => _NuevaContrasenaPageState();
}

/// Estado de la pantalla de nueva contraseña
///
/// Maneja la lógica de:
/// - Validación de campos
/// - Visibilidad de contraseñas
/// - Feedback visual al usuario
/// - Navegación después de éxito
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

  @override
  void initState() {
    super.initState();

    // Listeners para cambiar el color del borde cuando el campo recibe enfoque
    _contrasenaFocusNode.addListener(() {
      setState(() {
        _contrasenaBorderColor =
            _contrasenaFocusNode.hasFocus
                ? PasswordColors
                    .primary // Color primario cuando tiene foco
                : Colors.grey.shade400; // Gris cuando no tiene foco
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

  bool _isValidPassword(String password) {
    return password.length >= 8;
  }

  /// Valida todos los campos del formulario
  ///
  /// Actualiza los mensajes de error según las validaciones:
  /// - Contraseña no vacía y con mínimo 8 caracteres
  /// - Confirmación no vacía y que coincida con la contraseña
  void _validarCampos() {
    setState(() {
      // Validación para campo de nueva contraseña
      if (_contrasenaController.text.isEmpty) {
        _errorTextoContrasena = 'Por favor, ingrese la contraseña';
      } else if (!_isValidPassword(_contrasenaController.text)) {
        _errorTextoContrasena = 'Mínimo 8 caracteres';
      } else {
        _errorTextoContrasena = null;
      }

      // Validación para campo de confirmación
      if (_confirmarContrasenaController.text.isEmpty) {
        _errorTextoConfirmarContrasena = 'Confirme la contraseña';
      } else if (_contrasenaController.text !=
          _confirmarContrasenaController.text) {
        _errorTextoConfirmarContrasena = 'Las contraseñas no coinciden';
      } else {
        _errorTextoConfirmarContrasena = null;
      }
    });
  }

  void _guardarContrasena() {
    _validarCampos();

    // Solo proceder si no hay errores
    if (_errorTextoContrasena == null &&
        _errorTextoConfirmarContrasena == null) {
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
    final isSmallScreen = size.width < 400; // Flag para pantallas pequeñas

    return Scaffold(
      backgroundColor: PasswordColors.background,
      appBar: AppBar(
        title: Text(
          'Nueva contraseña',
          style: TextStyle(
            color: PasswordColors.textLight,
            fontSize: isSmallScreen ? 22 : 20, // Tamaño responsivo
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5, // Espaciado para mejor legibilidad
          ),
        ),
        centerTitle: true,
        backgroundColor: PasswordColors.primary,
        elevation: 0, // Sin sombra para diseño plano moderno
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
        // Cerrar teclado al tocar fuera de los campos
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SingleChildScrollView(
          // Padding responsivo según tamaño de pantalla
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
                  size: isSmallScreen ? 70 : 90, // Tamaño responsivo
                ),
              ),

              SizedBox(height: isSmallScreen ? 30 : 40), // Espaciado responsivo
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
              ),

              SizedBox(height: isSmallScreen ? 40 : 60),

              // Botón principal con efecto de elevación y gradiente
              SizedBox(
                width:
                    isSmallScreen
                        ? size.width * 0.8
                        : size.width * 0.6, // Ancho responsivo
                child: Material(
                  elevation: 6, // Sombra pronunciada
                  borderRadius: BorderRadius.circular(30),
                  shadowColor: PasswordColors.primary.withOpacity(0.4),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        colors: [
                          PasswordColors.primary,
                          PasswordColors.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors
                                .transparent, // Fondo transparente para mostrar el gradiente
                        shadowColor: Colors.transparent, // Sin sombra propia
                        padding: EdgeInsets.symmetric(
                          vertical:
                              isSmallScreen ? 16 : 18, // Padding responsivo
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _guardarContrasena,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'GUARDAR CONTRASEÑA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  isSmallScreen ? 16 : 16, // Tamaño responsivo
                              fontWeight: FontWeight.bold,
                              letterSpacing:
                                  1.1, // Espaciado para mejor legibilidad
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: isSmallScreen ? 30 : 40),

              // Botón secundario para volver al inicio
              TextButton(
                onPressed:
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IniciarSesion(),
                      ),
                    ),
                style: TextButton.styleFrom(
                  foregroundColor: PasswordColors.primary,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      color: PasswordColors.primary,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'VOLVER AL INICIO',
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
            ],
          ),
        ),
      ),
    );
  }

  /// Widget personalizado para campos de contraseña
  ///
  /// Parámetros:
  /// - controller: Controlador para manejar el texto
  /// - label: Texto descriptivo del campo
  /// - errorText: Mensaje de error a mostrar
  /// - focusNode: Para manejar el enfoque
  /// - borderColor: Color del borde según estado
  /// - obscureText: Si el texto debe estar oculto
  /// - onToggleVisibility: Función para cambiar visibilidad
  /// - isSmallScreen: Flag para ajustes responsivos
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String? errorText,
    required FocusNode focusNode,
    required Color borderColor,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    bool isSmallScreen = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label del campo
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

        // Campo de texto con Material para efecto de elevación
        Material(
          elevation: 2, // Sombra sutil
          borderRadius: BorderRadius.circular(12),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            style: TextStyle(
              color: PasswordColors.textDark,
              fontSize: isSmallScreen ? 16 : 18,
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isSmallScreen ? 16 : 18,
              ),
              filled: true,
              fillColor: PasswordColors.textField,
              prefixIcon: Icon(
                Icons.lock_outline,
                color: borderColor, // Color cambia según enfoque
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
              errorText: errorText, // Mensaje de error interno
              errorStyle: TextStyle(
                color: PasswordColors.error,
                fontSize: isSmallScreen ? 14 : 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none, // Sin borde por defecto
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: borderColor,
                  width: 2,
                ), // Borde más grueso al enfocar
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
            onChanged: (_) => _validarCampos(), // Validar en cada cambio
          ),
        ),
      ],
    );
  }
}
