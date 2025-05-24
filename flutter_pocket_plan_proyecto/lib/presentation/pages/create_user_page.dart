import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/repositories/usuario_repository.dart';
import '../../data/models/user_model.dart';

/// Paleta de colores verde moderno para la interfaz
class AppColors {
  static const Color primary = Color(0xFF2E7D32); // Verde oscuro principal
  static const Color secondary = Color(0xFF66BB6A); // Verde claro secundario
  static const Color accent = Color(0xFF81C784); // Verde acento suave
  static const Color background = Color(0xFFE8F5E9); // Fondo verde muy claro
  static const Color textDark = Color(0xFF1B5E20); // Texto verde oscuro
  static const Color textLight = Colors.white; // Texto para fondos oscuros
  static const Color error = Color(0xFFE57373); // Rojo suave para errores
  static const Color success = Color(
    0xFF4CAF50,
  ); // Verde para mensajes de éxito
  static const Color textField = Colors.white; // Fondo de campos de texto
  static const Color buttonShadow = Color(0x552E7D32); // Sombra para botones
  static const Color link = Color(0xFF1E88E5); // Color para enlaces
}

class CrearUsuarioScreen extends StatefulWidget {
  const CrearUsuarioScreen({super.key});

  @override
  State<CrearUsuarioScreen> createState() => _CrearUsuarioScreenState();
}

class _CrearUsuarioScreenState extends State<CrearUsuarioScreen> {
  // Controladores para los campos de texto
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  // Variables para manejar errores de validación
  String? _emailError;
  String? _userError;
  String? _passError;
  String? _confirmPassError;

  // Variables para controlar la visibilidad de las contraseñas
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;

  // FocusNodes para manejar el enfoque de los campos
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _userFocusNode = FocusNode();
  final FocusNode _passFocusNode = FocusNode();
  final FocusNode _confirmPassFocusNode = FocusNode();

  // Colores de borde dinámicos
  Color _emailBorderColor = Colors.grey.shade400;
  Color _userBorderColor = Colors.grey.shade400;
  Color _passBorderColor = Colors.grey.shade400;
  Color _confirmPassBorderColor = Colors.grey.shade400;

  // Estado para el efecto 3D del botón
  bool _isButtonPressed = false;

  // Estado para bloquear UI durante el proceso de creación
  bool _isProcessing = false;

  // Variable del repositorio para el usuario
  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  @override
  void initState() {
    super.initState();
    _setupFocusListeners();
    _setupTextListeners();
  }

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

  void _setupTextListeners() {
    _emailController.addListener(_validateEmailInRealTime);
    _userController.addListener(() {
      _validateUserInRealTime();
      _checkUsernameInUse();
    });
    _passController.addListener(_validatePassInRealTime);
    _confirmPassController.addListener(_validateConfirmPassInRealTime);
  }

  Future<void> _checkUsernameInUse() async {
    final isAvailable = await _usuarioRepository.isUsernameAvailable(
      _userController.text.trim(),
    );
    if (!isAvailable) {
      setState(() {
        _userError = 'Nombre de usuario ya está en uso';
      });
    }
  }

  @override
  void dispose() {
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

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidUsername(String username) {
    return username.length >= 2 && username.length <= 40;
  }

  bool _isValidPassword(String password) {
    if (password.length < 8 || password.length > 20) return false;
    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumbers = RegExp(r'[0-9]').hasMatch(password);
    return hasUpperCase && hasLowerCase && hasNumbers;
  }

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

  void _validateUserInRealTime() {
    if (_userController.text.isEmpty) {
      setState(() => _userError = null);
      return;
    }
    if (_userController.text.length > 40) {
      setState(() => _userError = 'Máximo 40 caracteres');
      return;
    }
    setState(() {
      _userError =
          !_isValidUsername(_userController.text)
              ? 'Debe tener entre 2 y 40 caracteres'
              : null;
    });
  }

  void _validatePassInRealTime() {
    if (_passController.text.isEmpty) {
      setState(() => _passError = null);
      return;
    }
    if (_passController.text.length > 20) {
      setState(() => _passError = 'Máximo 20 caracteres');
      return;
    }
    setState(() {
      _passError =
          !_isValidPassword(_passController.text)
              ? 'Mínimo 8 y máximo 20 caracteres, con mayúsculas, minúsculas y números'
              : null;
    });
  }

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

  Future<void> _validateFields() async {
    if (_isProcessing) return;

    String? emailError;
    String? userError;
    String? passError;
    String? confirmPassError;

    if (_emailController.text.isEmpty) {
      emailError = 'Ingrese su correo electrónico';
    } else if (!_isValidEmail(_emailController.text)) {
      emailError = 'Ingrese un correo válido';
    }

    if (_userController.text.isEmpty) {
      userError = 'Ingrese un nombre de usuario';
    } else if (_userController.text.length > 40) {
      userError = 'El nombre no debe tener más de 40 caracteres';
    } else if (!_isValidUsername(_userController.text)) {
      userError = 'Debe tener entre 2 y 40 caracteres';
    }

    if (_passController.text.isEmpty) {
      passError = 'Ingrese una contraseña';
    } else if (_passController.text.length > 20) {
      passError = 'La contraseña no debe tener más de 20 caracteres';
    } else if (!_isValidPassword(_passController.text)) {
      passError =
          'Mínimo 8 y máximo 20 caracteres, con mayúsculas, minúsculas y números';
    }

    if (_confirmPassController.text.isEmpty) {
      confirmPassError = 'Confirme su contraseña';
    } else if (_passController.text != _confirmPassController.text) {
      confirmPassError = 'Las contraseñas no coinciden';
    }

    setState(() {
      _emailError = emailError;
      _userError = userError;
      _passError = passError;
      _confirmPassError = confirmPassError;
    });

    if (emailError != null ||
        userError != null ||
        passError != null ||
        confirmPassError != null) {
      return;
    }

    final isAvailable = await _usuarioRepository.isUsernameAvailable(
      _userController.text.trim(),
    );
    if (!isAvailable) {
      setState(() {
        _userError = 'Nombre de usuario ya está en uso';
      });
      return;
    }

    setState(() => _isProcessing = true); // Bloquea UI
    await _crearUsuario();
    setState(() => _isProcessing = false); // Desbloquea después
  }

  Future<void> _crearUsuario() async {
    final newUser = UserModel(
      email: _emailController.text.trim(),
      username: _userController.text.trim(),
      password: _passController.text,
    );
    final id = await _usuarioRepository.insertUsuario(newUser);

    if (id > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Usuario creado exitosamente'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo crear el usuario'),
          backgroundColor: AppColors.error,
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
        if (_isProcessing) {
          // Bloquea la navegación
          return false;
        } else {
          // Navega a login y previene el pop por defecto
          Navigator.pushReplacementNamed(context, '/login');
          return false;
        }
      },
      child: AbsorbPointer(
        absorbing: _isProcessing,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              'CREAR NUEVO USUARIO',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            centerTitle: true,
            backgroundColor: AppColors.primary,
            elevation: 4,
            iconTheme: IconThemeData(
              color: AppColors.textLight,
              // Bloquea botón de retroceso de la AppBar (icono flecha) si procesando
              opacity: _isProcessing ? 0.2 : 1,
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed:
                  _isProcessing
                      ? null
                      : () {
                        Navigator.pop(context);
                      },
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
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
                  // Icono moderno de usuario
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.accent.withOpacity(0.3),
                          AppColors.background.withOpacity(0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person_add_alt_1,
                      size: isSmallScreen ? 80 : 100,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 30),

                  // Campo de email con Tooltip
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Correo Electrónico',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 5),
                          Tooltip(
                            message:
                                'El correo electrónico asignado debe ser válido y funcional',
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: TextStyle(
                              color: AppColors.textLight,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                            triggerMode: TooltipTriggerMode.tap,
                            child: Icon(
                              Icons.help_outline,
                              size: isSmallScreen ? 18 : 20,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      _buildTextField(
                        controller: _emailController,
                        label: '',
                        hintText: 'ejemplo@PocketPlan.com',
                        icon: Icons.email_outlined,
                        focusNode: _emailFocusNode,
                        borderColor: _emailBorderColor,
                        errorText: _emailError,
                        keyboardType: TextInputType.emailAddress,
                        isSmallScreen: isSmallScreen,
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 30),

                  // Campo de nombre de usuario con Tooltip
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Nombre de Usuario',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 5),
                          Tooltip(
                            message:
                                'Ingresa un nombre de usuario de 2 a 40 caracteres. Este nombre no podrá ser modificado después.',
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: TextStyle(
                              color: AppColors.textLight,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                            triggerMode: TooltipTriggerMode.tap,
                            child: Icon(
                              Icons.help_outline,
                              size: isSmallScreen ? 18 : 20,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      _buildTextField(
                        controller: _userController,
                        label: '',
                        hintText: 'Ingrese su nombre de usuario',
                        icon: Icons.person_outline,
                        focusNode: _userFocusNode,
                        borderColor: _userBorderColor,
                        errorText: _userError,
                        isSmallScreen: isSmallScreen,
                        maxLength: 40, // Límite físico
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 30),

                  // Campo de contraseña con Tooltip
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Contraseña',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 5),
                          Tooltip(
                            message:
                                'La contraseña debe tener entre 8 y 20 caracteres, incluyendo al menos una mayúscula, una minúscula y un número.',
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: TextStyle(
                              color: AppColors.textLight,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                            triggerMode: TooltipTriggerMode.tap,
                            child: Icon(
                              Icons.help_outline,
                              size: isSmallScreen ? 18 : 20,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      _buildPasswordField(
                        controller: _passController,
                        label: '',
                        hintText: 'Ingrese su contraseña',
                        focusNode: _passFocusNode,
                        borderColor: _passBorderColor,
                        errorText: _passError,
                        obscureText: _obscurePass,
                        onToggleVisibility: () {
                          setState(() => _obscurePass = !_obscurePass);
                        },
                        isSmallScreen: isSmallScreen,
                        maxLength: 20, // Límite físico
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 30),

                  // Campo de confirmación de contraseña
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirmar Contraseña',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      _buildPasswordField(
                        controller: _confirmPassController,
                        label: '',
                        hintText: 'Repita su contraseña',
                        focusNode: _confirmPassFocusNode,
                        borderColor: _confirmPassBorderColor,
                        errorText: _confirmPassError,
                        obscureText: _obscureConfirmPass,
                        onToggleVisibility: () {
                          setState(
                            () => _obscureConfirmPass = !_obscureConfirmPass,
                          );
                        },
                        isSmallScreen: isSmallScreen,
                        maxLength: 20, // Límite físico
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 30 : 50),

                  // Botón de crear usuario con efecto 3D
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _isButtonPressed = true),
                    onExit: (_) => setState(() => _isButtonPressed = false),
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _isButtonPressed = true),
                      onTapUp: (_) => setState(() => _isButtonPressed = false),
                      onTapCancel:
                          () => setState(() => _isButtonPressed = false),
                      onTap: _isProcessing ? null : _validateFields,
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
                            colors: [AppColors.primary, AppColors.secondary],
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
                          color:
                              _isProcessing
                                  ? Colors.grey.withOpacity(0.4)
                                  : null, // Bloquea visual si está procesando
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 16 : 20,
                          ),
                          child: Center(
                            child: Text(
                              'CREAR USUARIO',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight.withOpacity(
                                  _isProcessing ? 0.5 : 1,
                                ), // Bloquea visual
                                letterSpacing: 1.1,
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
                  SizedBox(height: isSmallScreen ? 20 : 30),

                  // Enlace para ir a inicio de sesión
                  TextButton(
                    onPressed:
                        _isProcessing
                            ? null
                            : () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color.fromARGB(255, 84, 148, 71),
                    ),
                    child: Text(
                      '¿Ya tienes una cuenta? Inicia sesión',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        color:
                            _isProcessing
                                ? Colors.grey.withOpacity(0.4)
                                : const Color.fromARGB(255, 84, 148, 71),
                      ),
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

  /// Widget para campos de texto normales
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
    int? maxLength,
  }) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      shadowColor: Colors.black.withOpacity(0.1),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters:
            maxLength != null
                ? [LengthLimitingTextInputFormatter(maxLength)]
                : null,
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
    );
  }

  /// Widget para campos de contraseña con toggle de visibilidad
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
    int? maxLength,
  }) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      shadowColor: Colors.black.withOpacity(0.1),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        maxLength: maxLength,
        inputFormatters:
            maxLength != null
                ? [LengthLimitingTextInputFormatter(maxLength)]
                : null,
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
    );
  }
}
