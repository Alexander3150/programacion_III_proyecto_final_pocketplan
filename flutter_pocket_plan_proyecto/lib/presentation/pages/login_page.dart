import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/repositories/usuario_repository.dart';
import '../providers/user_provider.dart';
import 'create_user_page.dart';
import 'recover_password_page.dart';
import 'resumen_page.dart';
import 'transition_page.dart';

/// Paleta de colores de la aplicación
class AppColors {
  static const Color primary = Color(0xFF2C3E50); // Azul oscuro principal
  static const Color secondary = Color(0xFF18BC9C); // Verde azulado secundario
  static const Color accent = Color(0xFF3498DB); // Azul brillante para acentos
  static const Color background = Color(0xFFECF0F1); // Color de fondo claro
  static const Color textDark = Color(0xFF2C3E50); // Texto oscuro
  static const Color textLight = Colors.white; // Texto claro
  static const Color error = Color(0xFFE74C3C); // Rojo para mensajes de error
  static const Color buttonShadow = Color(0x6618BC9C); // Sombra para botones
}

/// Pantalla de inicio de sesión con validaciones y animaciones
class IniciarSesion extends StatefulWidget {
  const IniciarSesion({super.key});

  @override
  State<IniciarSesion> createState() => _IniciarSesionState();
}

class _IniciarSesionState extends State<IniciarSesion>
    with SingleTickerProviderStateMixin {
  // Controladores para los campos de texto
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // Variables para manejar la visibilidad de la contraseña
  bool _obscureText = true;

  // Variables para manejar errores de validación
  String? _userError;
  String? _passError;

  // FocusNodes para manejar el enfoque de los campos
  final FocusNode _userFocusNode = FocusNode();
  final FocusNode _passFocusNode = FocusNode();

  // Colores de borde que cambian según el enfoque
  Color _userBorderColor = Colors.grey;
  Color _passBorderColor = Colors.grey;

  // Controlador y animación para el efecto del icono de usuario
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  // Estado para el efecto del botón de inicio de sesión
  bool _isButtonPressed = false;
  // Variable para el usuario final para toda la app
  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  @override
  void initState() {
    super.initState();

    /// Configuración de la animación para el icono de usuario:
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    )..addStatusListener((status) {
      // Lógica para hacer la animación continua (ping-pong)
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });

    // Inicia la animación
    _animationController.forward();

    /// Listeners para cambiar el color del borde cuando el campo recibe foco
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
    /// Limpieza de recursos para evitar memory leaks:
    _animationController.dispose();
    _userController.dispose();
    _passController.dispose();
    _userFocusNode.dispose();
    _passFocusNode.dispose();
    super.dispose();
  }

  void _limpiarCampos() {
    _userController.clear();
    _passController.clear();
    setState(() {
      _userError = null;
      _passError = null;
    });
  }

  /// Valida los campos del formulario según los requisitos:
  void _validateFields() {
    setState(() {
      // Validación para el campo de usuario
      if (_userController.text.isEmpty) {
        _userError = 'Por favor ingrese su usuario';
      } else if (_userController.text.length < 2) {
        _userError = 'El usuario debe tener al menos 2 caracteres';
      } else if (_userController.text.length > 40) {
        _userError = 'El usuario no puede exceder los 40 caracteres';
      } else {
        _userError = null;
      }

      // Validación para el campo de contraseña
      if (_passController.text.isEmpty) {
        _passError = 'Por favor ingrese su contraseña';
      } else if (_passController.text.length < 8) {
        _passError = 'La contraseña debe tener al menos 8 caracteres';
      } else if (_passController.text.length > 20) {
        _passError = 'La contraseña no puede exceder los 20 caracteres';
      } else {
        _passError = null;
      }
    });

    // Si no hay errores, proceder con el inicio de sesión
    if (_userError == null && _passError == null) {
      _loginUser();
    }
  }

  /// Verifica las credenciales del usuario contra la base de datos
  Future<void> _loginUser() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();

    // Buscar el usuario usando el repositorio y comparar contraseña
    final user = await _usuarioRepository.getUsuarioByUsername(username);
    if (user == null || user.password != password) {
      setState(() {
        _userError = null;
        _passError = 'Usuario o contraseña incorrectos';
      });
    } else {
      // Credenciales correctas - navegar a pantalla principal
      Provider.of<UsuarioProvider>(context, listen: false).setUsuario(user);
      _showSuccessAndNavigate();
    }
  }

  /// Muestra mensaje de éxito y navega a la pantalla principal
  void _showSuccessAndNavigate() {
    _limpiarCampos();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Inicio de sesión exitoso'),
        backgroundColor: AppColors.secondary,
        duration: const Duration(seconds: 2),
      ),
    );

    // Aquí deberías navegar a la pantalla principal del app

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => SplashScreen(
              destination:
                  ResumenScreen(), // Se debe colocar la pantalla home de los graficos te corresponde modificar esto José solo colocas el nombre de la clase e importas.
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/login');
        return false; // Evita el pop normal
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 20 : size.width * 0.1,
              vertical: 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Título de la pantalla
                Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 28 : 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 20 : 40),

                /// Icono de usuario con animación de escala y efectos visuales
                ScaleTransition(
                  scale: _animation,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.secondary.withOpacity(0.2),
                          AppColors.secondary.withOpacity(0.05),
                        ],
                        stops: const [0.1, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person,
                      size: isSmallScreen ? 120 : 150,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 30 : 50),

                /// Campo de texto para el usuario con validación
                _buildTextField(
                  controller: _userController,
                  label: 'Usuario',
                  hintText: 'Ingrese su usuario ',
                  prefixIcon: Icons.person_outline,
                  focusNode: _userFocusNode,
                  borderColor: _userBorderColor,
                  errorText: _userError,
                  isSmallScreen: isSmallScreen,
                  minLength: 2,
                  maxLength: 40,
                ),
                SizedBox(height: isSmallScreen ? 20 : 30),

                /// Campo de texto para la contraseña con toggle de visibilidad
                _buildPasswordField(
                  controller: _passController,
                  label: 'Contraseña',
                  hintText: 'Ingrese su contraseña ',
                  focusNode: _passFocusNode,
                  borderColor: _passBorderColor,
                  errorText: _passError,
                  isSmallScreen: isSmallScreen,
                  obscureText: _obscureText,
                  minLength: 8,
                  maxLength: 20,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
                SizedBox(height: isSmallScreen ? 30 : 50),

                /// Botón de inicio de sesión con efecto
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _isButtonPressed = true),
                    onTapUp: (_) => setState(() => _isButtonPressed = false),
                    onTapCancel: () => setState(() => _isButtonPressed = false),
                    onTap: _validateFields,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      transform:
                          Matrix4.identity()..translate(
                            0.0,
                            _isButtonPressed ? 2.0 : 0.0,
                            _isButtonPressed ? -2.0 : 0.0,
                          ),
                      width:
                          isSmallScreen ? size.width * 0.8 : size.width * 0.5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [AppColors.secondary, AppColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow:
                            _isButtonPressed
                                ? [
                                  BoxShadow(
                                    color: AppColors.buttonShadow,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                : [
                                  BoxShadow(
                                    color: AppColors.buttonShadow,
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 16 : 20,
                        ),
                        child: Center(
                          child: Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 2,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 30 : 40),

                /// Botones secundarios en una sola fila
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Botón para crear nuevo usuario
                    _buildTextButton(
                      icon: Icons.person_add_alt_1,
                      text: 'Crear Usuario',
                      isSmallScreen: isSmallScreen,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CrearUsuarioScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 5), // Espaciado entre botones
                    // Botón para recuperar contraseña
                    _buildTextButton(
                      icon: Icons.lock_reset,
                      text: 'Recuperar contraseña',
                      isSmallScreen: isSmallScreen,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecoverPasswordPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget personalizado para campos de texto con validación
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    required FocusNode focusNode,
    required Color borderColor,
    required String? errorText,
    required bool isSmallScreen,
    required int minLength,
    required int maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Etiqueta del campo
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
        // Campo de texto con decoración
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
            maxLength: maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            decoration: InputDecoration(
              counterText: '', // Oculta el contador de caracteres
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isSmallScreen ? 16 : 18,
              ),
              filled: true,
              fillColor: Colors.white,
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(prefixIcon, color: borderColor),
              errorText: errorText,
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
            // Validación en tiempo real
            onChanged: (value) {
              if (value.length < minLength || value.length > maxLength) {
                setState(() {
                  _userError =
                      'Debe tener entre $minLength y $maxLength caracteres';
                });
              } else {
                setState(() {
                  _userError = null;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  /// Widget personalizado para campo de contraseña con toggle de visibilidad
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
    required int minLength,
    required int maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Etiqueta del campo
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
        // Campo de contraseña con decoración
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
            maxLength: maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            decoration: InputDecoration(
              counterText: '', // Oculta el contador de caracteres
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
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: borderColor,
                ),
                onPressed: onToggleVisibility,
              ),
              errorText: errorText,
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
            // Validación en tiempo real
            onChanged: (value) {
              if (value.length < minLength || value.length > maxLength) {
                setState(() {
                  _passError =
                      'Debe tener entre $minLength y $maxLength caracteres';
                });
              } else {
                setState(() {
                  _passError = null;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  /// Widget personalizado para botones de texto con efecto hover
  Widget _buildTextButton({
    required IconData icon,
    required String text,
    required bool isSmallScreen,
    required VoidCallback onPressed,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.transparent,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: AppColors.primary,
                  size: isSmallScreen ? 22 : 26,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
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
