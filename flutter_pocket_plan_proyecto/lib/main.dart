import 'package:flutter/material.dart';
import 'package:flutter_pocket_plan_proyecto/presentation/pages/editar_simulador_de_ahorros_page.dart';
import 'package:flutter_pocket_plan_proyecto/presentation/pages/login_page.dart';


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
       //esto agregue
        

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

