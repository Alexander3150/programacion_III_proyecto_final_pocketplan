import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paleta de colores modernizados con fondo claro
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
}

class RecoverPasswordPage extends StatefulWidget {
  const RecoverPasswordPage({super.key});

  @override
  State<RecoverPasswordPage> createState() => _RecoverPasswordPageState();
}

/// Clase que maneja el estado de la página de recuperación de contraseña
/// Contiene la lógica para validar los campos de entrada y manejar el formulario
class _RecoverPasswordPageState extends State<RecoverPasswordPage> {
  // Clave global para identificar y controlar el estado del formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos de texto
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();

  // Variables para manejar errores de validación
  String? _emailError;
  bool _showUsernameError = false;

  // FocusNodes para manejar el enfoque y efectos visuales
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _usernameFocusNode = FocusNode();
  Color _emailBorderColor = Colors.grey.shade400;
  Color _usernameBorderColor = Colors.grey.shade400;

  @override
  void initState() {
    super.initState();
    // Agrega un listener para validación en tiempo real del email
    _emailController.addListener(_validateEmailInRealTime);

    // Listeners para cambiar el color del borde al enfocar
    _emailFocusNode.addListener(() {
      setState(() {
        _emailBorderColor =
            _emailFocusNode.hasFocus
                ? RecoveryColors.primary
                : Colors.grey.shade400;
      });
    });

    _usernameFocusNode.addListener(() {
      setState(() {
        _usernameBorderColor =
            _usernameFocusNode.hasFocus
                ? RecoveryColors.primary
                : Colors.grey.shade400;
      });
    });
  }

  @override
  void dispose() {
    // Limpieza: remueve listeners y libera recursos de los controladores
    _emailController.removeListener(_validateEmailInRealTime);
    _emailController.dispose();
    _usernameController.dispose();
    _emailFocusNode.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  /// Valida si un email tiene formato válido usando una expresión regular
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Valida el email en tiempo real mientras el usuario escribe
  void _validateEmailInRealTime() {
    if (_emailController.text.isEmpty) {
      setState(() => _emailError = null);
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      setState(() => _emailError = 'Ingrese un correo válido');
    } else {
      setState(() => _emailError = null);
    }
  }

  /// Valida todos los campos del formulario cuando se presiona el botón de enviar
  void _validateFields() {
    setState(() {
      // Validar email
      if (_emailController.text.isEmpty) {
        _emailError = 'Por favor ingrese su correo electrónico';
      } else if (!_isValidEmail(_emailController.text)) {
        _emailError = 'Ingrese un correo electrónico válido';
      }

      // Validar nombre de usuario
      _showUsernameError = _usernameController.text.isEmpty;
    });

    // Si no hay errores, proceder con el envío
    if (_emailError == null && !_showUsernameError) {
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Código enviado correctamente'),
          backgroundColor: RecoveryColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Navegar a la pantalla de validación de código después de 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        // Codigo para navegar a la pantalla para validar el codigo de recuperación
      });
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
          'Recuperar contraseña',
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono con efecto moderno
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
                    Icons.lock_reset,
                    color: RecoveryColors.primary,
                    size: isSmallScreen ? 70 : 90,
                  ),
                ),

                SizedBox(height: isSmallScreen ? 30 : 40),

                // Campo de email con efectos modernos
                _buildTextField(
                  controller: _emailController,
                  label: 'Correo Electrónico',
                  hintText: 'ejemplo@pocketplan.com',
                  errorText: _emailError,
                  errorColor: RecoveryColors.error,
                  textColor: RecoveryColors.textDark,
                  icon: Icons.email_outlined,
                  iconColor: _emailBorderColor,
                  focusNode: _emailFocusNode,
                  borderColor: _emailBorderColor,
                  isEmail: true,
                  isSmallScreen: isSmallScreen,
                ),

                SizedBox(height: isSmallScreen ? 20 : 30),

                // Campo de nombre de usuario con efectos modernos
                _buildTextField(
                  controller: _usernameController,
                  label: 'Nombre de Usuario',
                  errorText:
                      _showUsernameError
                          ? 'Por favor complete este campo'
                          : null,
                  errorColor: RecoveryColors.error,
                  textColor: RecoveryColors.textDark,
                  icon: Icons.person_outline,
                  iconColor: _usernameBorderColor,
                  focusNode: _usernameFocusNode,
                  borderColor: _usernameBorderColor,
                  isSmallScreen: isSmallScreen,
                ),

                SizedBox(height: isSmallScreen ? 40 : 60),

                // Botón moderno con efecto de elevación
                SizedBox(
                  width: isSmallScreen ? size.width * 0.8 : size.width * 0.6,
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(30),
                    shadowColor: RecoveryColors.primary.withOpacity(0.4),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          colors: [
                            RecoveryColors.primary,
                            RecoveryColors.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 16 : 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _validateFields,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, color: Colors.white, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'ENVIAR CÓDIGO',
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

                SizedBox(height: isSmallScreen ? 30 : 40),

                // Enlace de regreso con estilo moderno
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: RecoveryColors.primary,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_rounded,
                        color: RecoveryColors.primary,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'VOLVER AL INICIO',
                        style: TextStyle(
                          color: RecoveryColors.primary,
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          fontStyle:
                              FontStyle.italic, // Esto añade el estilo cursiva
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
      ),
    );
  }

  /// Widget personalizado para campos de texto con efectos modernos

  ///  Añadidos errorBorder y focusedErrorBorder para resaltar el campo cuando hay error
  ///  Configurado errorStyle para el texto de error interno
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    required String? errorText,
    required Color errorColor,
    required Color textColor,
    required IconData icon,
    required Color iconColor,
    required FocusNode focusNode,
    required Color borderColor,
    bool isEmail = false,
    bool isSmallScreen = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Text(
            label,
            style: TextStyle(
              color: RecoveryColors.textDark,
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
            style: TextStyle(
              color: RecoveryColors.textDark,
              fontSize: isSmallScreen ? 16 : 18,
            ),
            keyboardType:
                isEmail ? TextInputType.emailAddress : TextInputType.text,
            inputFormatters:
                isEmail
                    ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))]
                    : null,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isSmallScreen ? 16 : 18,
              ),
              filled: true,
              fillColor: RecoveryColors.textField,
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: isSmallScreen ? 14 : 16,
              ),
              prefixIcon: Icon(
                icon,
                color: iconColor,
                size: isSmallScreen ? 22 : 24,
              ),
              suffixIcon:
                  errorText != null
                      ? Icon(
                        Icons.error_outline_rounded,
                        color: errorColor,
                        size: isSmallScreen ? 22 : 24,
                      )
                      : null,
              errorText:
                  errorText, // Mensaje de error que aparece dentro del campo
              errorStyle: TextStyle(
                color: errorColor,
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
              // Bordes especiales para estado de error
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: errorColor, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: errorColor, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
