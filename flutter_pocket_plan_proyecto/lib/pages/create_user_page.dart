import 'package:flutter/material.dart';

/// Paleta de colores verde
class AppColors {
  static const Color primary = Color(0xFF2E7D32); // Verde oscuro principal
  static const Color secondary = Color(0xFF66BB6A); // Verde claro secundario
  static const Color accent = Color(0xFF81C784); // Verde acento suave
  static const Color background = Color(0xFFE8F5E9); // Fondo verde muy claro
  static const Color textDark = Color(0xFF1B5E20); // Texto verde oscuro
  static const Color textLight = Colors.white; // Texto para fondos oscuros
  static const Color error = Color(0xFFE57373); // Rojo suave para errores
  static const Color success = Color(0xFF4CAF50); // Verde éxito
  static const Color textField = Colors.white; // Fondo campos de texto
}

class CrearUsuarioScreen extends StatefulWidget {
  const CrearUsuarioScreen({super.key});

  @override
  State<CrearUsuarioScreen> createState() => _CrearUsuarioScreenState();
}

class _CrearUsuarioScreenState extends State<CrearUsuarioScreen> {
  // Controladores para manejar el texto ingresado en cada campo
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  // Variables para almacenar mensajes de error de validación
  String? _emailError;
  String? _userError;
  String? _passError;
  String? _confirmPassError;

  // Estado para controlar visibilidad de contraseñas
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;

  // FocusNodes para manejar el enfoque de cada campo
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _userFocusNode = FocusNode();
  final FocusNode _passFocusNode = FocusNode();
  final FocusNode _confirmPassFocusNode = FocusNode();

  // Variables para colores de borde dinámicos (cambian al enfocar)
  Color _emailBorderColor = Colors.grey.shade400;
  Color _userBorderColor = Colors.grey.shade400;
  Color _passBorderColor = Colors.grey.shade400;
  Color _confirmPassBorderColor = Colors.grey.shade400;

  @override
  void initState() {
    super.initState();

    // Configuración de listeners para cambiar bordes al enfocar/desenfocar
    _setupFocusListeners();

    // Agregar listeners para validación en tiempo real
    _emailController.addListener(_validateEmailInRealTime);
    _userController.addListener(_validateUserInRealTime);
    _passController.addListener(_validatePassInRealTime);
    _confirmPassController.addListener(_validateConfirmPassInRealTime);
  }

  /// Configura los listeners para cambiar colores de borde al enfocar campos
  void _setupFocusListeners() {
    _emailFocusNode.addListener(() {
      setState(() {
        _emailBorderColor =
            _emailFocusNode.hasFocus ? AppColors.primary : Colors.grey.shade400;
      });
    });

    _userFocusNode.addListener(() {
      setState(() {
        _userBorderColor =
            _userFocusNode.hasFocus ? AppColors.primary : Colors.grey.shade400;
      });
    });

    _passFocusNode.addListener(() {
      setState(() {
        _passBorderColor =
            _passFocusNode.hasFocus ? AppColors.primary : Colors.grey.shade400;
      });
    });

    _confirmPassFocusNode.addListener(() {
      setState(() {
        _confirmPassBorderColor =
            _confirmPassFocusNode.hasFocus
                ? AppColors.primary
                : Colors.grey.shade400;
      });
    });
  }

  @override
  void dispose() {
    // Limpieza de todos los controladores y focus nodes para evitar memory leaks
    _emailController.removeListener(_validateEmailInRealTime);
    _userController.removeListener(_validateUserInRealTime);
    _passController.removeListener(_validatePassInRealTime);
    _confirmPassController.removeListener(_validateConfirmPassInRealTime);

    _emailController.dispose();
    _userController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _emailFocusNode.dispose();
    _userFocusNode.dispose();
    _passFocusNode.dispose();
    _confirmPassFocusNode.dispose();
    super.dispose();
  }

  /// Valida si un email tiene formato válido usando expresión regular
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Valida que la contraseña cumpla con requisitos mínimos
  bool _isValidPassword(String password) {
    return password.length >= 8; // Mínimo 8 caracteres
  }

  /// Validación en tiempo real para email
  void _validateEmailInRealTime() {
    if (_emailController.text.isEmpty) {
      setState(() => _emailError = null);
      return;
    }
    setState(() {
      _emailError =
          !_isValidEmail(_emailController.text)
              ? 'Ingrese un correo válido'
              : null;
    });
  }

  /// Validación en tiempo real para usuario
  void _validateUserInRealTime() {
    if (_userController.text.isEmpty) {
      setState(() => _userError = null);
      return;
    }
    // Agregar más validaciones para el usuario si es necesario
  }

  /// Validación en tiempo real para contraseña
  void _validatePassInRealTime() {
    if (_passController.text.isEmpty) {
      setState(() => _passError = null);
      return;
    }
    setState(() {
      _passError =
          !_isValidPassword(_passController.text)
              ? 'Mínimo 8 caracteres'
              : null;
    });
  }

  /// Validación en tiempo real para confirmación de contraseña
  void _validateConfirmPassInRealTime() {
    if (_confirmPassController.text.isEmpty) {
      setState(() => _confirmPassError = null);
      return;
    }
    setState(() {
      _confirmPassError =
          _passController.text != _confirmPassController.text
              ? 'Las contraseñas no coinciden'
              : null;
    });
  }

  /// Valida todos los campos del formulario y actualiza los mensajes de error
  void _validateFields() {
    setState(() {
      // Validación de email
      _emailError =
          _emailController.text.isEmpty
              ? 'Ingrese su correo electrónico'
              : !_isValidEmail(_emailController.text)
              ? 'Ingrese un correo válido'
              : null;

      // Validación de nombre de usuario
      _userError =
          _userController.text.isEmpty ? 'Ingrese un nombre de usuario' : null;

      // Validación de contraseña
      _passError =
          _passController.text.isEmpty
              ? 'Ingrese una contraseña'
              : !_isValidPassword(_passController.text)
              ? 'Mínimo 8 caracteres'
              : null;

      // Validación de confirmación de contraseña
      _confirmPassError =
          _confirmPassController.text.isEmpty
              ? 'Confirme su contraseña'
              : _passController.text != _confirmPassController.text
              ? 'Las contraseñas no coinciden'
              : null;
    });

    // Si no hay errores, proceder con creación de usuario
    if (_emailError == null &&
        _userError == null &&
        _passError == null &&
        _confirmPassError == null) {
      _crearUsuario();
    }
  }

  /// Simula el proceso de creación de usuario exitoso
  void _crearUsuario() {
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: const Text('Usuario creado exitosamente'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        )
        .closed
        .then(
          (_) => Navigator.pop(context),
        ); // Despues de que el usuario se creo bien, regresar al login
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos las dimensiones de la pantalla para diseño responsivo
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Crear nuevo usuario',
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: isSmallScreen ? 22 : 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textLight),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondary],
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
              // Icono decorativo con efecto
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withOpacity(0.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_add,
                  size: isSmallScreen ? 80 : 100,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: isSmallScreen ? 30 : 40),

              // Campo de email con validación en tiempo real
              _buildTextField(
                controller: _emailController,
                label: 'Correo Electrónico',
                hintText: 'ejemplo@dominio.com',
                icon: Icons.email_outlined,
                focusNode: _emailFocusNode,
                borderColor: _emailBorderColor,
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 20 : 30),

              // Campo de usuario con validación en tiempo real
              _buildTextField(
                controller: _userController,
                label: 'Nombre de Usuario',
                hintText: 'Ingrese su usuario',
                icon: Icons.person_outline,
                focusNode: _userFocusNode,
                borderColor: _userBorderColor,
                errorText: _userError,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 20 : 30),

              // Campo de contraseña con validación en tiempo real
              _buildPasswordField(
                controller: _passController,
                label: 'Contraseña',
                hintText: 'Ingrese su contraseña',
                focusNode: _passFocusNode,
                borderColor: _passBorderColor,
                errorText: _passError,
                obscureText: _obscurePass,
                onToggleVisibility: () {
                  setState(() => _obscurePass = !_obscurePass);
                },
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 20 : 30),

              // Campo de confirmación de contraseña con validación en tiempo real
              _buildPasswordField(
                controller: _confirmPassController,
                label: 'Confirmar Contraseña',
                hintText: 'Repita su contraseña',
                focusNode: _confirmPassFocusNode,
                borderColor: _confirmPassBorderColor,
                errorText: _confirmPassError,
                obscureText: _obscureConfirmPass,
                onToggleVisibility: () {
                  setState(() => _obscureConfirmPass = !_obscureConfirmPass);
                },
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 40 : 60),

              // Botón de crear usuario con diseño responsivo
              SizedBox(
                width: isSmallScreen ? size.width * 0.8 : size.width * 0.6,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(30),
                  shadowColor: AppColors.primary.withOpacity(0.4),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 16 : 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _validateFields,
                      child: Text(
                        'CREAR USUARIO',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 30 : 40),

              // Enlace para ir a inicio de sesión
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: Text(
                  '¿Ya tienes cuenta? Inicia Sesión',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget personalizado para campos de texto normales
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required FocusNode focusNode,
    required Color borderColor,
    required String? errorText,
    required bool isSmallScreen,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: isSmallScreen ? 16 : 18,
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isSmallScreen ? 16 : 18,
              ),
              filled: true,
              fillColor: AppColors.textField,
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: isSmallScreen ? 14 : 16,
              ),
              prefixIcon: Icon(
                icon,
                color: borderColor,
                size: isSmallScreen ? 22 : 24,
              ),
              errorText: errorText,
              errorStyle: TextStyle(
                color: AppColors.error,
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
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.error, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Widget personalizado para campos de contraseña con toggle de visibilidad
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required FocusNode focusNode,
    required Color borderColor,
    required String? errorText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required bool isSmallScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: isSmallScreen ? 16 : 18,
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isSmallScreen ? 16 : 18,
              ),
              filled: true,
              fillColor: AppColors.textField,
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: isSmallScreen ? 14 : 16,
              ),
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
                color: AppColors.error,
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
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.error, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
