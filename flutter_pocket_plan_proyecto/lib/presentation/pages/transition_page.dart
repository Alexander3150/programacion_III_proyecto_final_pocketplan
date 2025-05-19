import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Asegúrate de importar provider
import '../providers/user_provider.dart';

/// Pantalla de transición con animaciones personalizadas que se muestra:
/// 1. Después de un inicio de sesión exitoso
/// 2. Antes de navegar a la pantalla principal
///
/// Parámetros requeridos:
/// [destination] - Widget al que se navegará después de la animación
class SplashScreen extends StatefulWidget {
  final Widget destination; // Destino despues de la transicion

  const SplashScreen({super.key, required this.destination});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controladores y animaciones:
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _textController;
  late Animation<double> _textScaleAnimation;
  late Animation<double> _inspirationTextAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.elasticOut),
    );

    _inspirationTextAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      _textController.forward();
    });

    Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => widget.destination,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutQuad),
                ),
                child: child,
              ),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener nombre del usuario desde el Provider
    final usuarioProvider = Provider.of<UsuarioProvider>(context);
    final nombreUsuario = usuarioProvider.usuario?.username ?? 'Usuario';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
            stops: const [0.1, 0.9],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _textScaleAnimation.value,
                        child: Opacity(
                          opacity: _textController.value,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        // Usar el nombre obtenido del provider
                        Text(
                          '✨ ¡Bienvenido, $nombreUsuario! ✨',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _inspirationTextAnimation,
                          child: const Text(
                            "🚀 Tu disciplina financiera inspira. ¡Sigue así! 💪",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 180,
                    width: 180,
                    child: ScaleTransition(
                      scale: _textScaleAnimation,
                      child: Image.asset(
                        'assets/img/pocketplan.png',
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: const Icon(
                              Icons.image,
                              size: 60,
                              color: Colors.white,
                            ),
                          );
                        },
                        frameBuilder: (
                          context,
                          child,
                          frame,
                          wasSynchronouslyLoaded,
                        ) {
                          if (frame == null) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          }
                          return child;
                        },
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _textScaleAnimation.value,
                        child: Opacity(
                          opacity: _textController.value,
                          child: child,
                        ),
                      );
                    },
                    child: const Text(
                      '💰 Pocket Plan 💰',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _inspirationTextAnimation,
                    child: const Text(
                      '📊 Planifica, 💰 ahorra y 🏆 vive mejor',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        letterSpacing: 1.1,
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
}
