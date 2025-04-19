import 'package:flutter/material.dart';

// Widget personalizado que extiende StatelessWidget, es decir, no cambia de estado
class GlobalLayout extends StatelessWidget {
  final String titulo; // Título que se mostrará en el AppBar
  final Widget
  body; // Cuerpo principal de la pantalla, se espera un widget como contenido
  final int
  navIndex; // Índice del ítem seleccionado en la barra de navegación inferior
  final Function(int)?
  onTapNav; // Función opcional que se ejecuta cuando se toca un ítem del BottomNavigationBar
  final bool
  mostrarBotonHome; // Indica si debe mostrarse el botón de inicio (ícono de "home") en el AppBa
  final bool mostrarDrawer; // Indica si debe mostrarse el menú lateral (Drawer)

  // Constructor del GlobalLayout con sus parámetros
  const GlobalLayout({
    required this.titulo, // Título obligatorio
    required this.body, // Contenido de la pantalla obligatorio
    this.navIndex =
        0, // Valor por defecto del ítem seleccionado en la barra inferior
    this.onTapNav, // Función callback opcional para manejar taps en la barra inferior
    this.mostrarBotonHome =
        false, // Por defecto, no se muestra el botón de home
    this.mostrarDrawer = false, // Por defecto, no se muestra el Drawer lateral
    Key?
    key, // Clave opcional para identificar el widget en el árbol de widgets
  }) : super(
         key: key,
       ); // Llama al constructor de la clase base (StatelessWidget)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // APPBAR con título, botón de drawer y botón home (opcional)
      appBar: AppBar(
        title: Text(
          titulo,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        //  Botón del Drawer siempre visible si mostrarDrawer es true
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

        automaticallyImplyLeading: false, // evita mostrar ícono automático
        centerTitle: true,
        elevation: 4,

        // Estilo del AppBar con bordes redondeados y degradado
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0D47A1), // Azul oscuro
                Color(0xFF00B0FF), // Celeste  brillante
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(15),
            ),
          ),
        ),

        // Botón Home a la derecha
        actions:
            mostrarBotonHome
                ? [
                  IconButton(
                    icon: const Icon(Icons.home, color: Colors.white),
                    onPressed:
                        () {}, //=> Navigator.pushNamed(context, // La ruta de la pantalla home), para que funcione solo elimino {}
                  ),
                ]
                : null,
        //Tamaño del AppBar
        toolbarHeight: 65,
      ),

      //  Drawer lateral si está activado
      drawer: mostrarDrawer ? _buildDrawer(context) : null,

      // Cuerpo principal de la pantalla
      body: SafeArea(minimum: const EdgeInsets.all(16), child: body),

      // Barra de navegación inferior
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  // Drawer lateral con ítems de navegación
  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Encabezado del Drawer con título y subtítulo
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D47A1), // Azul oscuro
                  Color(0xFF00B0FF), // Celeste  brillante
                ],
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
                const SizedBox(height: 10),
                Text(
                  'Controla tus finanzas',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Lista de opciones del menú
          _buildDrawerItem(
            context,
            icon: Icons.pie_chart,
            text: 'Seguimiento de presupuesto',
            //Descomentar para agregar la ruta
            //route: '/home', // Asi como esta en el main
          ),
          _buildDrawerItem(
            context,
            icon: Icons.attach_money,
            text: 'Registro de ingresos y egresos',
            //Ruta para la pantalla donde se ingresa los ingresos y egresos
            // Para agregar rout
            //route: '/transacciones',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.credit_card,
            text: 'Tarjetas',
            // Ruta para las tarjetas guardadas
          ),
          _buildDrawerItem(
            context,
            icon: Icons.savings,
            text: 'Simulador de ahorros',
            //Ruta cuando se ingresa un ahorro
          ),
          _buildDrawerItem(
            context,
            icon: Icons.money_off,
            text: 'Registro de deudas',
            //Ruta para cuando se ingresa una deuda
          ),
          _buildDrawerItem(
            context,
            icon: Icons.flag,
            text: 'Retos de Ahorro',
            //Ruta para ver el historial de ahorros
          ),
          _buildDrawerItem(
            context,
            icon: Icons.trending_down,
            text: 'Seguimiento de deudas',
            // Ruta para ver el historial de deudas
          ),

          const Divider(thickness: 1),

          // Botón de cerrar sesión
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            text: 'Cerrar sesión',
            //Ruta hacia el login
            route: '/login',
            isLogout: true,
          ),
        ],
      ),
    );
  }

  // Cada ítem del Drawer
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
        Navigator.pop(context); //  Primero cierra el Drawer

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

  // Barra de navegación inferior con tres ítems
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
                    //Ruta para ver la pantalla home de los graficos
                    // Navigator.pushNamed(context, Agregar la ruta como en el main );
                    break;
                  case 1:
                    //Ruta para ver las alertas y recordatorios
                    //  Navigator.pushNamed(context, '/alertas_recordatorios es un ejemplo ');
                    break;
                  case 2:
                    //Ruta para los informes, para generar los informes segun la pagina seleccionada
                    //Navigator.pushNamed(context, ruta');
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
