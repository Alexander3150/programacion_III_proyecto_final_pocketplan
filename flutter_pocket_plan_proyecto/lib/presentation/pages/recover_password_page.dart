import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/email_service.dart';
import '../../data/models/user_model.dart';
import 'code_validation_page.dart';

/// Paleta de colores con fondo claro
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

class RecoverPasswordPage extends StatefulWidget {
  const RecoverPasswordPage({super.key});

  @override
  State<RecoverPasswordPage> createState() => _RecoverPasswordPageState();
}

class _RecoverPasswordPageState extends State<RecoverPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();

  String? _emailError;
  String? _usernameError;
  bool _showUsernameError = false;
  String? _mismatchError;

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _usernameFocusNode = FocusNode();
  Color _emailBorderColor = Colors.grey.shade400;
  Color _usernameBorderColor = Colors.grey.shade400;

  bool _isButtonPressed = false;
  bool _isTextButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmailInRealTime);
    _usernameController.addListener(_validateUsernameInRealTime);

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
    _emailController.removeListener(_validateEmailInRealTime);
    _usernameController.removeListener(_validateUsernameInRealTime);
    _emailController.dispose();
    _usernameController.dispose();
    _emailFocusNode.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

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

  void _validateUsernameInRealTime() {
    if (_usernameController.text.isEmpty) {
      setState(() {
        _usernameError = null;
        _showUsernameError = false;
      });
      return;
    }

    if (_usernameController.text.length < 2) {
      setState(() {
        _usernameError = 'Mínimo 2 caracteres';
        _showUsernameError = true;
      });
    } else if (_usernameController.text.length > 40) {
      setState(() {
        _usernameError = 'Máximo 40 caracteres';
        _showUsernameError = true;
      });
    } else {
      setState(() {
        _usernameError = null;
        _showUsernameError = false;
      });
    }
  }

  /// Verifica coincidencia de credenciales
  bool _credentialsMatch() {
    final users = UserModel.userList;
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();

    return users.any(
      (user) =>
          user.email.toLowerCase() == email.toLowerCase() &&
          user.username.toLowerCase() == username.toLowerCase(),
    );
  }

  void _validateFields() {
    setState(() {
      _mismatchError = null;

      // Validar email
      if (_emailController.text.isEmpty) {
        _emailError = 'Por favor ingrese su correo electrónico';
      } else if (!_isValidEmail(_emailController.text)) {
        _emailError = 'Ingrese un correo electrónico válido';
      } else {
        _emailError = null;
      }

      // Validar nombre de usuario
      if (_usernameController.text.isEmpty) {
        _usernameError = 'Por favor ingrese su nombre de usuario';
        _showUsernameError = true;
      } else if (_usernameController.text.length < 2) {
        _usernameError = 'Mínimo 2 caracteres';
        _showUsernameError = true;
      } else if (_usernameController.text.length > 40) {
        _usernameError = 'Máximo 40 caracteres';
        _showUsernameError = true;
      } else {
        _usernameError = null;
        _showUsernameError = false;
      }

      if (_emailError != null || _showUsernameError) return;

      if (!_credentialsMatch()) {
        _mismatchError =
            'No se encontró una coincidencia entre el nombre de usuario y el correo electrónico. Por favor, inténtelo de nuevo.';
        return;
      }

      _showSuccessAndNavigate();
    });
  }

  void _showSuccessAndNavigate() async {
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final code = UserModel.generateRecoveryCode(email, username);

    final enviado = await EmailJSService.sendRecoveryEmail(
      email: email,
      code: code,
    );

    if (enviado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código enviado correctamente'),
          backgroundColor: RecoveryColors.success,
          duration: Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    CodeValidationPage(email: email, username: username),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al enviar el correo'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          ),
        ),
        centerTitle: true,
        backgroundColor: RecoveryColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: RecoveryColors.accent.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.lock_reset,
                    color: RecoveryColors.primary,
                    size: isSmallScreen ? 70 : 90,
                  ),
                ),

                SizedBox(height: isSmallScreen ? 30 : 40),

                if (_mismatchError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _mismatchError!,
                      style: TextStyle(
                        color: RecoveryColors.error,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                  ),
                //Estructura de toiltip
                _buildTextFieldWithTooltip(
                  controller: _emailController,
                  label: 'Correo Electrónico',
                  tooltipMessage:
                      'Por favor, ingrese el correo electrónico con el que se registró en su cuenta.',
                  hintText: 'ejemplo@pocketplan.com',
                  errorText: _emailError,
                  isSmallScreen: isSmallScreen,
                  focusNode: _emailFocusNode,
                  borderColor: _emailBorderColor,
                  icon: Icons.email_outlined,
                ),

                SizedBox(height: isSmallScreen ? 20 : 30),

                _buildTextFieldWithTooltip(
                  controller: _usernameController,
                  label: 'Nombre de Usuario',
                  tooltipMessage:
                      'Introduzca su nombre de usuario tal y como lo configuró al crear su cuenta.',
                  errorText: _showUsernameError ? _usernameError : null,
                  isSmallScreen: isSmallScreen,
                  focusNode: _usernameFocusNode,
                  borderColor: _usernameBorderColor,
                  icon: Icons.person_outline,
                ),

                SizedBox(height: isSmallScreen ? 40 : 60),

                _build3DButton(
                  onPressed: _validateFields,
                  label: 'ENVIAR CÓDIGO',
                  icon: Icons.send,
                  isSmallScreen: isSmallScreen,
                  width: isSmallScreen ? size.width * 0.8 : size.width * 0.6,
                ),

                SizedBox(height: isSmallScreen ? 30 : 40),

                _build3DTextButton(
                  onPressed: () => Navigator.pop(context),
                  label: 'Volver a inicio de sesión',
                  icon: Icons.arrow_back_rounded,
                  isSmallScreen: isSmallScreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldWithTooltip({
    required TextEditingController controller,
    required String label,
    required String tooltipMessage,
    String? hintText,
    String? errorText,
    bool isSmallScreen = false,
    required FocusNode focusNode,
    required Color borderColor,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Builder(
              builder:
                  (iconContext) => GestureDetector(
                    onTap: () => _showTooltip(iconContext, tooltipMessage),
                    child: const Icon(
                      Icons.help_outline,
                      color: RecoveryColors.primary,
                      size: 20,
                    ),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
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
                color: borderColor,
                size: isSmallScreen ? 22 : 24,
              ),
              suffixIcon:
                  errorText != null
                      ? Icon(
                        Icons.error_outline_rounded,
                        color: RecoveryColors.error,
                        size: isSmallScreen ? 22 : 24,
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
                borderSide: BorderSide(color: borderColor, width: 2),
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

  void _showTooltip(BuildContext context, String message) {
    final overlay = Overlay.of(context);

    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            bottom: 377, // Ajusta según lo lejos  del borde inferior
            left: 20, // Margen izquierdo
            right: 20, // Margen derecho
            child: Material(
              color: const Color.fromARGB(0, 17, 188, 200),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(221, 25, 153, 199),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(
      const Duration(seconds: 3),
    ).then((_) => overlayEntry.remove());
  }

  Widget _build3DButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required bool isSmallScreen,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isButtonPressed = true),
        onTapUp: (_) => setState(() => _isButtonPressed = false),
        onTapCancel: () => setState(() => _isButtonPressed = false),
        onTap: onPressed,
        child: Transform(
          transform:
              Matrix4.identity()..translate(0.0, _isButtonPressed ? 2.0 : 0.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [RecoveryColors.primary, RecoveryColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow:
                  _isButtonPressed
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
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required bool isSmallScreen,
  }) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTextButtonPressed = true),
      onTapUp: (_) => setState(() => _isTextButtonPressed = false),
      onTapCancel: () => setState(() => _isTextButtonPressed = false),
      onTap: onPressed,
      child: Transform(
        transform:
            Matrix4.identity()
              ..translate(0.0, _isTextButtonPressed ? 1.0 : 0.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: RecoveryColors.background,
            boxShadow:
                _isTextButtonPressed
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
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
