import 'package:flutter/material.dart';

/// Pantalla de transición con animaciones personalizadas que se muestra:
/// 1. Después de un inicio de sesión exitoso
/// 2. Antes de navegar a la pantalla principal
///
/// Parámetros requeridos:
/// [destination] - Widget al que se navegará después de la animación
/// [message] - Mensaje principal a mostrar (ej. "¡Bienvenido, Melbyn!")
class SplashScreen extends StatefulWidget {
  final Widget destination; // Destino despues de la transicion
  final String message; // Mensaje que se recibe de la pagina login

  const SplashScreen({
    super.key,
    required this.destination,
    required this.message,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controladores y animaciones:
  late AnimationController
  _controller; // Controlador para animaciones principales
  late Animation<double>
  _fadeAnimation; // Animación de aparición gradual (fade)
  late Animation<Offset>
  _slideAnimation; // Animación de deslizamiento desde abajo
  late AnimationController
  _textController; // Controlador para animaciones de texto
  late Animation<double> _textScaleAnimation; // Animación de escala para textos
  late Animation<double>
  _inspirationTextAnimation; // Animación para mensaje motivacional

  @override
  void initState() {
    super.initState();

    // Configuración del controlador principal (dura 2 segundos)
    _controller = AnimationController(
      vsync: this, // Necesario para sincronizar con los frames de la UI
      duration: const Duration(seconds: 2),
    );

    // Animación de fade (opacidad) con curva suave de entrada/salida
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Animación de deslizamiento: comienza 25% abajo y termina en posición normal
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve:
            Curves.easeOutQuad, // Curva que inicia rápido y termina suavemente
      ),
    );

    // Controlador específico para animaciones de texto (dura 800ms)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Animación de escala para textos: crece de 50% a 100% con efecto elástico
    _textScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.elasticOut, // Efecto de rebote elástico
      ),
    );

    // Animación específica para el mensaje motivacional: aparece después (50%-100% de la animación)
    _inspirationTextAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // Iniciar secuencia de animaciones:
    // 1. Primero las animaciones principales (_controller)
    // 2. Luego las animaciones de texto (_textController)
    _controller.forward().then((_) {
      _textController.forward();
    });

    // Programar navegación después de 4 segundos (incluye tiempo de animaciones)
    Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder:
              (_, __, ___) =>
                  widget.destination, // Aqui se usa la ruta del destino
          transitionsBuilder: (_, animation, __, child) {
            // Transición personalizada al cambiar de pantalla:
            // - Efecto fade (opacidad)
            // - Deslizamiento suave desde abajo
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
    // Limpieza: es CRUCIAL disponer los controladores para evitar memory leaks
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo degradado moderno y elegante
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6A11CB), // Púrpura oscuro
              const Color(0xFF2575FC), // Azul brillante
            ],
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
                  const SizedBox(height: 40), // Espacio superior
                  // Contenedor principal de mensajes con animaciones
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
                        // Mensaje principal (recibido como parámetro) con emoji
                        Text(
                          '✨ ${widget.message} ✨',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Mensaje motivacional adicional con animación independiente
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

                  // Logo de la aplicación con animación de escala y mejor manejo de errores
                  SizedBox(
                    height: 180,
                    width: 180,
                    child: ScaleTransition(
                      scale: _textScaleAnimation,
                      child: Image.asset(
                        'assets/img/pocketplan.png',
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint("Error cargando imagen: $error");
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

                  // Nombre de la aplicación con animación
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

                  // Eslogan de la aplicación
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
