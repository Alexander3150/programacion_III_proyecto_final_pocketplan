import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'presentation/pages/delete_user_page.dart';
import 'presentation/pages/editar_simulador_de_ahorros_page.dart';
import 'presentation/pages/guardar_simulador_de_ahorros_page.dart';
import 'presentation/pages/guardar_simulador_de_deudas_page.dart';
import 'presentation/pages/history_cards_screen.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/register_credi_cart_screen.dart';
import 'presentation/pages/register_debit_card_screen.dart';
import 'presentation/pages/registros_ie_page.dart';
import 'presentation/pages/resumen_page.dart';
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
        // Rutas de Login
        '/login': (context) => const IniciarSesion(),
        '/micuenta': (context) => const MiCuentaPage(),

        // Rutas de tarjetas
        '/historial_tarjetas': (context) => HistoryCardsScreen(),
        '/registrar_tarjeta_credito': (context) => RegisterCreditCardScreen(),
        '/registrar_tarjeta_debito': (context) => RegisterDebitCardScreen(),

        //Rutas de simulador de ahorros
        '/retos_de_ahorro': (context) => GuardarSimuladorDeAhorrosPage(),
        '/simulador_ahorro': (context) => SimuladorAhorrosScreen(),
        '/editar_simulador': (context) => const EditarSimuladorDeAhorrosPage(),
        // Rutas de Presupuesto, ingreso de egresos e ingresos
        '/ingreso_egreso': (context) => RegistroMovimientoScreen(),
        '/resumen': (context) => ResumenScreen(),
        // Rutas de simulador de deudas
        '/seguimineto_deuda': (context) => GuardarSimuladorDeDeudasPage(),
        '/simulador_deuda': (context) => SimuladorDeudasScreen(),
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
