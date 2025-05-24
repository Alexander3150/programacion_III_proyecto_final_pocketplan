import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'presentation/pages/delete_user_page.dart';
import 'presentation/pages/editar_simulador_de_ahorros_page.dart';
import 'presentation/pages/history_cards_screen.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/register_credi_cart_screen.dart';
import 'presentation/pages/register_debit_card_screen.dart';
import 'presentation/pages/simulador_de_ahorros_page.dart';
import 'presentation/pages/simulador_de_deudas_page.dart';
import 'presentation/providers/user_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => UsuarioProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Ruta inicial al abrir la app
      initialRoute: '/login',

      // Mapa de rutas de la app
      routes: {
        '/login': (context) => const IniciarSesion(),
        '/micuenta': (context) => const MiCuentaPage(),
        '/historial_tarjetas': (context) => HistoryCardsScreen(),
        '/registrar_tarjeta_credito': (context) => RegisterCreditCardScreen(),
        '/registrar_tarjeta_debito': (context) => RegisterDebitCardScreen(),
        '/editar_simulador' :(context) => EditarSimuladorDeAhorrosPage(),
        '/simulador_de_ahorros': (context) => SimuladorAhorrosScreen(),
        '/simulador_de_deudas': (context) => SimuladorDeudasScreen(),

        // Aquí agregas las demás rutas que se van a utilizar en el layout global
        // Ejemplo ='/home': (context) => const HomeScreen(),
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
