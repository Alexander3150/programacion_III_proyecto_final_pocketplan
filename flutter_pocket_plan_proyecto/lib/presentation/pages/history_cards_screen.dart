import 'package:flutter/material.dart';
import '../../data/models/card_manager.dart';
import '../widgets/global_components.dart';
import 'modificacion_detalle_tarjeta_credito_screen.dart';
import 'modificacion_detalle_tarjeta_debito.dart';
import 'register_credi_cart_screen.dart';
import 'register_debit_card_screen.dart';

class HistoryCardsScreen extends StatelessWidget {
  const HistoryCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: 'Mis Tarjetas',
      body: const _HistoryCardsContent(),
      mostrarDrawer: true,
      mostrarBotonHome: true,
      navIndex: 0,
    );
  }
}

class _HistoryCardsContent extends StatefulWidget {
  const _HistoryCardsContent();

  @override
  State<_HistoryCardsContent> createState() => _HistoryCardsContentState();
}

class _HistoryCardsContentState extends State<_HistoryCardsContent> {
  String tipoSeleccionado = 'Crédito';

  @override
  Widget build(BuildContext context) {
    final cardManager = CardManager();
    final Color fondoColor =
        tipoSeleccionado == 'Crédito'
            ? const Color.fromARGB(179, 225, 245, 254)
            : const Color.fromARGB(221, 232, 245, 233);

    return Stack(
      children: [
        // Fondo dinámico
        Container(color: fondoColor),

        // Contenido principal
        GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              // Ícono principal
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors:
                            tipoSeleccionado == 'Crédito'
                                ? [
                                  Colors.blue.shade100,
                                  const Color.fromARGB(255, 22, 116, 192),
                                ]
                                : [
                                  Colors.green.shade100,
                                  const Color.fromARGB(255, 33, 148, 38),
                                ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              tipoSeleccionado == 'Crédito'
                                  ? Colors.blue.withOpacity(0.3)
                                  : Colors.green.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 500),
                        child: Icon(
                          tipoSeleccionado == 'Crédito'
                              ? Icons.credit_card
                              : Icons.account_balance_wallet,
                          key: ValueKey<String>(tipoSeleccionado),
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Selector de tipo
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ToggleButtons(
                    borderRadius: BorderRadius.circular(30),
                    fillColor:
                        tipoSeleccionado == 'Crédito'
                            ? Colors.blue.withOpacity(0.15)
                            : Colors.green.withOpacity(0.15),
                    selectedColor:
                        tipoSeleccionado == 'Crédito'
                            ? Colors.blue[800]
                            : Colors.green[800],
                    color: Colors.grey[600],
                    isSelected: [
                      tipoSeleccionado == 'Crédito',
                      tipoSeleccionado == 'Débito',
                    ],
                    onPressed: (index) {
                      setState(() {
                        tipoSeleccionado = index == 0 ? 'Crédito' : 'Débito';
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.credit_card, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Crédito',
                              style: TextStyle(
                                fontWeight:
                                    tipoSeleccionado == 'Crédito'
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_balance_wallet, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Débito',
                              style: TextStyle(
                                fontWeight:
                                    tipoSeleccionado == 'Débito'
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Lista de tarjetas
              Expanded(
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axis: Axis.vertical,
                        child: child,
                      ),
                    );
                  },
                  child:
                      tipoSeleccionado == 'Crédito'
                          ? _buildCreditCardList(cardManager.creditCards)
                          : _buildDebitCardList(cardManager.debitCards),
                ),
              ),

              // Botón para agregar tarjeta
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        tipoSeleccionado == 'Crédito'
                            ? const Color.fromARGB(226, 25, 118, 210)
                            : const Color.fromARGB(218, 45, 153, 50),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor:
                        tipoSeleccionado == 'Crédito'
                            ? const Color.fromARGB(
                              160,
                              33,
                              149,
                              243,
                            ).withOpacity(0.3)
                            : const Color.fromARGB(
                              139,
                              76,
                              175,
                              79,
                            ).withOpacity(0.3),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                tipoSeleccionado == 'Crédito'
                                    ? const RegisterCreditCardScreen()
                                    : const RegisterDebitCardScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.add_circle_outline, size: 22),
                  label: Text(
                    'Agregar tarjeta de $tipoSeleccionado',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // CONSTRUYE LISTA DE TARJETAS DE CRÉDITO
  Widget _buildCreditCardList(List<CreditCard> tarjetas) {
    return tarjetas.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
          padding: EdgeInsets.only(top: 12, bottom: 8),
          itemCount: tarjetas.length,
          itemBuilder: (context, index) {
            final tarjeta = tarjetas[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _mostrarDetalles(context, tarjeta),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color.fromARGB(255, 211, 212, 212),
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.blue.shade100],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.credit_card, color: Colors.blue[700]),
                      ),
                      title: Text(
                        tarjeta.banco,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      subtitle: Text(
                        tarjeta.alias,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: _buildPopupMenu(tarjeta),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
  }

  // CONSTRUYE LISTA DE TARJETAS DE DÉBITO
  Widget _buildDebitCardList(List<DebitCard> tarjetas) {
    return tarjetas.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
          padding: EdgeInsets.only(top: 12, bottom: 8),
          itemCount: tarjetas.length,
          itemBuilder: (context, index) {
            final tarjeta = tarjetas[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _mostrarDetalles(context, tarjeta),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color.fromARGB(255, 230, 228, 228),
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade50,
                              Colors.green.shade100,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: Colors.green[700],
                        ),
                      ),
                      title: Text(
                        tarjeta.banco,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      subtitle: Text(
                        tarjeta.alias,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: _buildPopupMenu(tarjeta),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
  }

  // ESTADO VACÍO (CUANDO NO HAY TARJETAS)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
            ),
            child: Icon(
              tipoSeleccionado == 'Crédito'
                  ? Icons.credit_card
                  : Icons.account_balance_wallet,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No tienes tarjetas de $tipoSeleccionado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Agrega tu primera tarjeta para comenzar a gestionarla',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  // MENÚ DE OPCIONES (POPUP)
  Widget _buildPopupMenu(dynamic tarjeta) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      onSelected: (value) {
        if (value == 'eliminar') {
          _eliminarTarjeta(tarjeta.id);
        } else if (value == 'editar') {
          _editarTarjeta(context, tarjeta);
        } else if (value == 'detalles') {
          _mostrarDetalles(context, tarjeta);
        }
      },
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: 'detalles',
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  SizedBox(width: 8),
                  Text('Ver detalles'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.orange[700]),
                  SizedBox(width: 8),
                  Text('Modificar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red[700]),
                  SizedBox(width: 8),
                  Text('Eliminar'),
                ],
              ),
            ),
          ],
    );
  }

  // ELIMINAR TARJETA (DIÁLOGO)
  void _eliminarTarjeta(String id) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red[50],
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 36,
                      color: Colors.red[700],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '¿Eliminar tarjeta?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Esta acción no se puede deshacer',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            if (tipoSeleccionado == 'Crédito') {
                              CardManager().removeCreditCard(id);
                            } else {
                              CardManager().removeDebitCard(id);
                            }
                            setState(() {});
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Tarjeta eliminada correctamente',
                                ),
                                backgroundColor: Colors.red[600],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // EDITAR TARJETA
  void _editarTarjeta(BuildContext context, dynamic tarjeta) {
    if (tarjeta is CreditCard) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ModificacionDetalleTarjetaCreditoScreen(
                tarjeta: tarjeta,
                modoEdicion: true,
              ),
        ),
      ).then((_) => setState(() {}));
    } else if (tarjeta is DebitCard) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ModificacionDetalleTarjetaDebitoScreen(
                tarjeta: tarjeta,
                modoEdicion: true,
              ),
        ),
      ).then((_) => setState(() {}));
    }
  }

  // MOSTRAR DETALLES DE TARJETA
  void _mostrarDetalles(BuildContext context, dynamic tarjeta) {
    if (tarjeta is CreditCard) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ModificacionDetalleTarjetaCreditoScreen(
                tarjeta: tarjeta,
                modoEdicion: false,
              ),
        ),
      );
    } else if (tarjeta is DebitCard) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ModificacionDetalleTarjetaDebitoScreen(
                tarjeta: tarjeta,
                modoEdicion: false,
              ),
        ),
      );
    }
  }
}
