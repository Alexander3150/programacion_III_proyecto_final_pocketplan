import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pocket_plan_proyecto/pages/login_page.dart';
import 'package:flutter_pocket_plan_proyecto/pages/new_password_page.dart';

/// Paleta de colores modernizada con fondo claro
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

class CodeValidationPage extends StatefulWidget {
  const CodeValidationPage({super.key});

  @override
  State<CodeValidationPage> createState() => _CodeValidationPageState();
}

/// Clase que maneja el estado de la página de validación de código
/// Contiene la lógica para validar el código de verificación
class _CodeValidationPageState extends State<CodeValidationPage> {
  // Controlador para el campo de código
  final _codeController = TextEditingController();

  // Variable para manejar errores de validación
  bool _showError = false;

  // FocusNode para manejar el enfoque y efectos visuales
  final FocusNode _codeFocusNode = FocusNode();
  Color _codeBorderColor = Colors.grey.shade400;

  @override
  void initState() {
    super.initState();

    // Listener para cambiar el color del borde al enfocar
    _codeFocusNode.addListener(() {
      setState(() {
        _codeBorderColor =
            _codeFocusNode.hasFocus
                ? RecoveryColors.primary
                : Colors.grey.shade400;
      });
    });
  }

  @override
  void dispose() {
    // Limpieza: libera recursos del controlador y focus node
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  /// Valida el código ingresado por el usuario
  void _validateCode() {
    setState(() {
      _showError = _codeController.text.isEmpty;
    });

    if (!_showError) {
      // Mostrar mensaje de éxito
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

      // Navegar a la pantalla de nueva contraseña después de 1 segundo
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NuevaContrasenaPage()),
        );
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

              // Campo de código con efectos
              _buildCodeField(
                controller: _codeController,
                focusNode: _codeFocusNode,
                borderColor: _codeBorderColor,
                showError: _showError,
                isSmallScreen: isSmallScreen,
              ),

              SizedBox(height: isSmallScreen ? 40 : 60),

              // Botón  con efecto de elevación
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
                      onPressed: _validateCode,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'VALIDAR CÓDIGO',
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

  /// Widget personalizado para el campo de código con efectos
  ///  Configurada la propiedad errorText del InputDecoration para mostrar el error dentro del campo
  ///  Añadidos errorBorder y focusedErrorBorder para resaltar el campo cuando hay error
  ///  Configurado errorStyle para el texto de error interno
  Widget _buildCodeField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required Color borderColor,
    required bool showError,
    required bool isSmallScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 12),
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
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
                color: borderColor,
                size: isSmallScreen ? 24 : 28,
              ),
              suffixIcon:
                  showError
                      ? Icon(
                        Icons.error_outline_rounded,
                        color: RecoveryColors.error,
                        size: isSmallScreen ? 24 : 28,
                      )
                      : null,
              // Configuración para mostrar errores dentro del TextField
              errorText:
                  showError ? 'Por favor ingrese el código recibido' : null,
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
              // Bordes especiales para estado de error
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
}
