import 'package:flutter/material.dart';
import 'package:flutter_pocket_plan_proyecto/pages/editar_simulador_de_ahorros_page.dart';
import 'package:flutter_pocket_plan_proyecto/pages/login_page.dart';
import 'package:flutter_pocket_plan_proyecto/pages/datos_ahorro_page.dart'; // Importa la nueva página

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

      //Ruta inicial al abrir la app
      initialRoute: '/login',

      //Mapa de rutas de la app
      routes: {
        //'/editar_simulador': (context) => const EditarSimuladorDeAhorrosPage(),
        '/login': (context) => const IniciarSesion(),
        '/editar_simulador': (context) => const EditarSimuladorDeAhorrosPage(),
       //'/datos_ahorro': (context) => const DatosAhorroPage(),  // Nueva ruta añadida

      },

      // Por si se navega a una ruta inexistente
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: Center(child: Text('Ruta no encontrada')),
        ),
      ),
    );
  }
}

