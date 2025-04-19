import 'package:flutter/material.dart';
import 'package:flutter_pocket_plan_proyecto/pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //home: const IniciarSesion(),
      debugShowCheckedModeBanner: false,

      //Ruta inicila al abrir la app
      initialRoute: '/login',

      //Mapa de rutas de la app
      routes: {
        '/login': (context) => const IniciarSesion(),

        // Aqui agrego las demas rutas que se van a utilizar en el layout global
        // Ejemplo  ='/home': (context) => const HomeScreen(),
      },
      // Por si se navega a una ruta inexistente
      onUnknownRoute:
          (settings) => MaterialPageRoute(
            builder:
                (context) => const Scaffold(
                  body: Center(child: Text('Ruta no encontrada')),
                ),
          ),
    );
  }
}
