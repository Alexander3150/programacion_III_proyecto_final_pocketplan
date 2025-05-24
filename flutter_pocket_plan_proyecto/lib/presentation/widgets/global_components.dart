import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import 'dialogo_filtro_informe.dart';
import 'dialogo_filtro_informe_ahorros.dart';
import 'dialogo_filtro_informe_deudas.dart';
import '../pages/informe_page.dart';
import '../pages/informe_ahorros_page.dart';
import '../pages/informe_deudas_page.dart';

class GlobalLayout extends StatelessWidget {
  final String titulo;
  final Widget body;
  final int navIndex;
  final Function(int)? onTapNav;
  final bool mostrarBotonHome;
  final bool mostrarDrawer;
  final bool mostrarBotonInforme;
  final String tipoInforme; // 'financiero', 'ahorro', 'deuda'

  const GlobalLayout({
    required this.titulo,
    required this.body,
    this.navIndex = 0,
    this.onTapNav,
    this.mostrarBotonHome = false,
    this.mostrarDrawer = false,
    this.mostrarBotonInforme = false,
    this.tipoInforme = 'financiero', // por defecto
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usuarioProvider = Provider.of<UsuarioProvider>(context);
    final nombreUsuario = usuarioProvider.usuario?.username ?? 'Invitado';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titulo,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading:
            mostrarDrawer
                ? Builder(
                  builder:
                      (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                )
                : null,
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF00B0FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(15),
            ),
          ),
        ),
        actions:
            mostrarBotonHome
                ? [
                  IconButton(
                    icon: const Icon(Icons.home, color: Colors.white),
                    onPressed: () {
                      Navigator.pushNamed(context, '/resumen');
                    },
                  ),
                ]
                : null,
        toolbarHeight: 65,
      ),
      drawer: mostrarDrawer ? _buildDrawer(context, nombreUsuario) : null,
      body: SafeArea(minimum: const EdgeInsets.all(16), child: body),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildDrawer(BuildContext context, String? nombreUsuario) {
    final theme = Theme.of(context);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF00B0FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PocketPlan',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Hola, ${nombreUsuario ?? 'Invitado'}\nControla tus finanzas',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.pie_chart,
            text: 'Seguimiento de presupuesto',
            route: '/resumen',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.attach_money,
            text: 'Registro de ingresos y egresos',
            route: '/ingreso_egreso',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.credit_card,
            text: 'Tarjetas',
            route: '/historial_tarjetas',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.savings,
            text: 'Simulador de ahorros',
            route: '/simulador_ahorro',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.money_off,
            text: 'Registro de deudas',
            route: '/simulador_deuda',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.flag,
            text: 'Retos de Ahorro',
            route: '/retos_de_ahorro',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.trending_down,
            text: 'Seguimiento de deudas',
            route: '/seguimineto_deuda',
          ),
          const Divider(thickness: 1),
          _buildDrawerItem(
            context,
            icon: Icons.account_circle,
            text: 'Mi cuenta',
            route: '/micuenta',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            text: 'Cerrar sesión',
            route: '/login',
            isLogout: true,
          ),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    String? route,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Color(0xFF00B0FF)),
      title: Text(
        text,
        style: TextStyle(
          color: isLogout ? Colors.red : null,
          fontWeight: isLogout ? FontWeight.bold : null,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (route != null) {
          if (isLogout) {
            Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
          } else {
            Navigator.pushNamed(context, route);
          }
        }
      },
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BottomNavigationBar(
          currentIndex: navIndex,
          onTap: (index) async {
            if (index == 2 && mostrarBotonInforme) {
              Map<String, dynamic>? result;
              Widget? nextPage;
              String nextTitle = "Informe";

              switch (tipoInforme) {
                case 'ahorro':
                  result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => const DialogoFiltroInformeAhorros(),
                  );
                  if (result != null) {
                    nextTitle = "Informe de Ahorros";
                    nextPage = InformeAhorrosPage(
                      estado: result['estado'],
                      periodo: result['periodo'],
                      dateRange: result['dateRange'],
                    );
                  }
                  break;
                case 'deuda':
                  result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => const DialogoFiltroInformeDeudas(),
                  );
                  if (result != null) {
                    nextTitle = "Informe de Deudas";
                    nextPage = InformeDeudasPage(
                      estado: result['estado'],
                      periodo: result['periodo'],
                      dateRange: result['dateRange'],
                    );
                  }
                  break;
                default:
                  result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => const DialogoFiltroInforme(),
                  );
                  if (result != null) {
                    nextTitle = "Informe Financiero";
                    nextPage = InformePage(
                      tipo: result['tipo'],
                      periodo: result['periodo'],
                      dateRange: result['dateRange'],
                    );
                  }
              }

              if (nextPage != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => GlobalLayout(
                          titulo: nextTitle,
                          body: nextPage!,
                          mostrarDrawer: true,
                          navIndex: 2,
                          mostrarBotonInforme: true,
                          tipoInforme: tipoInforme,
                        ),
                  ),
                );
              }
            } else if (onTapNav != null) {
              onTapNav!(index);
            } else {
              switch (index) {
                case 0:
                  //Navigator.pushNamed(context, '/graficos');
                  break;
                case 1:
                  break;
                case 2:
                  break;
              }
            }
          },
          elevation: 8,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Color(0xFF00B0FF),
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart),
              label: 'Gráficos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_active),
              label: 'Alertas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insert_chart),
              label: 'Generar Informe',
            ),
          ],
        ),
      ),
    );
  }
}
