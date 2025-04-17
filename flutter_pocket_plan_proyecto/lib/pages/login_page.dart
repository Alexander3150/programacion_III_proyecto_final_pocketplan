import 'package:flutter/material.dart';

/// Paleta de colores se trato de hacer un diseño moderno y elegante para la aplicación
class AppColors {
  static const Color primary = Color(0xFF2C3E50); // Azul oscuro elegante
  static const Color secondary = Color(0xFF18BC9C); // Verde azulado moderno
  static const Color accent = Color(0xFF3498DB); // Azul brillante
  static const Color background = Color(0xFFECF0F1); // Fondo claro
  static const Color textDark = Color(0xFF2C3E50); // Texto oscuro
  static const Color textLight = Colors.white; // Texto claro
  static const Color error = Color(0xFFE74C3C); // Rojo para errores
}

class IniciarSesion extends StatefulWidget {
  const IniciarSesion({super.key});

  @override
  State<IniciarSesion> createState() => _IniciarSesionState();
}

class _IniciarSesionState extends State<IniciarSesion> {
  // Variables para controlar la visibilidad de la contraseña
  bool _obscureText = true;

  // Controladores para los campos de texto
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // Variables para manejar errores de validación
  String? _userError;
  String? _passError;

  // FocusNodes para manejar el enfoque de los campos
  final FocusNode _userFocusNode = FocusNode();
  final FocusNode _passFocusNode = FocusNode();

  // Colores de borde que cambian según el enfoque
  Color _userBorderColor = Colors.grey;
  Color _passBorderColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    // Listeners para cambiar el color del borde cuando el campo está enfocado
    _userFocusNode.addListener(() {
      setState(() {
        _userBorderColor =
            _userFocusNode.hasFocus ? AppColors.secondary : Colors.grey;
      });
    });

    _passFocusNode.addListener(() {
      setState(() {
        _passBorderColor =
            _passFocusNode.hasFocus ? AppColors.secondary : Colors.grey;
      });
    });
  }

  @override
  void dispose() {
    // Limpieza de recursos para evitar memory leaks
    _userController.dispose();
    _passController.dispose();
    _userFocusNode.dispose();
    _passFocusNode.dispose();
    super.dispose();
  }

  /// Valida los campos del formulario
  void _validateFields() {
    setState(() {
      _userError =
          _userController.text.isEmpty ? 'Por favor ingrese su usuario' : null;
      _passError =
          _passController.text.isEmpty
              ? 'Por favor ingrese su contraseña'
              : null;
    });

    if (_userError == null && _passError == null) {
      //Ruta para la transición
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600; // Para diseño responsive

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          // Permite scroll en pantallas pequeñas
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20 : size.width * 0.1,
            vertical: 20,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Título con estilo moderno
              Text(
                'Iniciar Sesión',
                style: TextStyle(
                  fontSize: isSmallScreen ? 28 : 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: isSmallScreen ? 20 : 40),

              // Icono de usuario moderno con efecto
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_circle, // Icono moderno de usuario
                  size: isSmallScreen ? 120 : 150,
                  color: AppColors.secondary,
                ),
              ),
              SizedBox(height: isSmallScreen ? 30 : 50),

              // Campo de usuario con validación
              _buildTextField(
                controller: _userController,
                label: 'Usuario',
                hintText: 'Ingrese su usuario',
                prefixIcon: Icons.person_outline,
                focusNode: _userFocusNode,
                borderColor: _userBorderColor,
                errorText: _userError,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 20 : 30),

              // Campo de contraseña con validación
              _buildPasswordField(
                controller: _passController,
                label: 'Contraseña',
                hintText: 'Ingrese su contraseña',
                focusNode: _passFocusNode,
                borderColor: _passBorderColor,
                errorText: _passError,
                isSmallScreen: isSmallScreen,
                obscureText: _obscureText,
                onToggleVisibility: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
              SizedBox(height: isSmallScreen ? 30 : 50),

              // Botón de inicio de sesión con gradiente
              Container(
                width: isSmallScreen ? size.width * 0.8 : size.width * 0.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    colors: [AppColors.secondary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _validateFields,
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
                  child: Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 30 : 40),

              // Opciones adicionales
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botón para crear usuario
                  TextButton.icon(
                    onPressed: () {
                      //Ruta para Crear usuario
                    },
                    icon: Icon(
                      Icons.person_add,
                      color: AppColors.primary,
                      size: isSmallScreen ? 24 : 28,
                    ),
                    label: Text(
                      'Crear Usuario',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  // Botón para recuperar contraseña
                  TextButton.icon(
                    onPressed: () {
                      //Ruta para Recuperar contraseña
                    },
                    icon: Icon(
                      Icons.lock_reset,
                      color: AppColors.primary,
                      size: isSmallScreen ? 24 : 28,
                    ),
                    label: Text(
                      'Recuperar Contraseña',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget personalizado para campos de texto con estilo moderno y validación
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    required FocusNode focusNode,
    required Color borderColor,
    required String? errorText,
    required bool isSmallScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isSmallScreen ? 16 : 18,
              ),
              filled: true,
              fillColor: Colors.white,
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(prefixIcon, color: borderColor),
              errorText:
                  errorText, // Mensaje de error que aparece dentro del campo
              errorStyle: TextStyle(
                color: AppColors.error,
                fontSize: isSmallScreen ? 14 : 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: AppColors.error, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Widget personalizado para campo de contraseña con toggle de visibilidad y validación
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required FocusNode focusNode,
    required Color borderColor,
    required String? errorText,
    required bool isSmallScreen,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            focusNode: focusNode,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isSmallScreen ? 16 : 18,
              ),
              filled: true,
              fillColor: Colors.white,
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.lock_outline, color: borderColor),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: borderColor,
                ),
                onPressed: onToggleVisibility,
              ),
              errorText:
                  errorText, // Mensaje de error que aparece dentro del campo
              errorStyle: TextStyle(
                color: AppColors.error,
                fontSize: isSmallScreen ? 14 : 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: AppColors.error, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
