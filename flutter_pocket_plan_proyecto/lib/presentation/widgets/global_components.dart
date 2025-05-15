import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart'; // Importa provider

// Widget personalizado que extiende StatelessWidget
class GlobalLayout extends StatelessWidget {
  final String titulo; // Título que se mostrará en el AppBar
  final Widget body; // Cuerpo principal de la pantalla
  final int
  navIndex; // Índice del ítem seleccionado en la barra de navegación inferior
  final Function(int)?
  onTapNav; // Función opcional que se ejecuta cuando se toca un ítem del BottomNavigationBar
  final bool mostrarBotonHome; // Indica si debe mostrarse el botón de inicio
  final bool mostrarDrawer; // Indica si debe mostrarse el menú lateral

  // Constructor del GlobalLayout con sus parámetros
  const GlobalLayout({
    required this.titulo,
    required this.body,
    this.navIndex = 0,
    this.onTapNav,
    this.mostrarBotonHome = false,
    this.mostrarDrawer = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Usamos Provider para obtener el nombre del usuario
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
                    onPressed: () {},
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

  // Drawer lateral con ítems de navegación
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
          ),
          _buildDrawerItem(
            context,
            icon: Icons.attach_money,
            text: 'Registro de ingresos y egresos',
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
          ),
          _buildDrawerItem(
            context,
            icon: Icons.money_off,
            text: 'Registro de deudas',
          ),
          _buildDrawerItem(context, icon: Icons.flag, text: 'Retos de Ahorro'),
          _buildDrawerItem(
            context,
            icon: Icons.trending_down,
            text: 'Seguimiento de deudas',
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
          onTap:
              onTapNav ??
              (index) {
                switch (index) {
                  case 0:
                    break;
                  case 1:
                    break;
                  case 2:
                    break;
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
              label: 'Informe',
            ),
          ],
        ),
      ),
    );
  }
}
