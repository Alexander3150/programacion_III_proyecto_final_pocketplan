import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/user_model.dart';
import '../providers/user_provider.dart';
import '../widgets/global_components.dart';

class MiCuentaPage extends StatelessWidget {
  const MiCuentaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UsuarioProvider>(context).usuario;

    if (user == null) {
      return const Center(
        child: Text(
          "No hay usuario logueado",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return GlobalLayout(
      titulo: 'Mi cuenta',
      body: DeleteUserWidget(usuario: user),
      mostrarDrawer: true,
    );
  }
}

class DeleteUserWidget extends StatefulWidget {
  final UserModel usuario;

  const DeleteUserWidget({super.key, required this.usuario});

  @override
  _DeleteUserWidgetState createState() => _DeleteUserWidgetState();
}

class _DeleteUserWidgetState extends State<DeleteUserWidget> {
  final TextEditingController _passController = TextEditingController();
  String? _error;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _passController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final password = _passController.text.trim();
    if (password.isNotEmpty && (password.length < 8 || password.length > 20)) {
      setState(() {
        _error = 'La contraseña debe tener entre 8 y 20 caracteres';
      });
    } else {
      setState(() {
        _error = null;
      });
    }
  }

  void _eliminarCuenta() {
    final passwordIngresada = _passController.text.trim();

    final coincide = UserModel.authenticate(
      widget.usuario.username,
      passwordIngresada,
    );

    if (coincide != null) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 10,
              title: const Text(
                'Confirmar eliminación',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text(
                'Esta acción es irreversible. Se eliminarán permanentemente todos tus datos, historial y contenido asociado a esta cuenta.',
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text('Confirmar eliminación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shadowColor: Colors.red[800],
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    final success = UserModel.deleteUser(
                      username: widget.usuario.username,
                      password: passwordIngresada,
                    );
                    Navigator.pop(context);
                    if (success) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (_) => false,
                      );
                    } else {
                      setState(() {
                        _error =
                            'No se pudo eliminar la cuenta. Inténtalo nuevamente.';
                      });
                    }
                  },
                ),
              ],
            ),
      );
    } else {
      setState(() {
        _error = 'Contraseña incorrecta';
      });
    }
  }

  @override
  void dispose() {
    _passController.removeListener(_validatePassword);
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.usuario;
    final screenSize = MediaQuery.of(context).size;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.lightBlue.shade50, Colors.blue.shade100],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(screenSize.width < 600 ? 16.0 : 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: screenSize.width < 600 ? 16 : 24),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.lightBlue, Colors.blue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.account_circle,
                            size: screenSize.width < 600 ? 100 : 120,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: screenSize.width < 600 ? 20 : 25),
                      Card(
                        elevation: 3,
                        margin: EdgeInsets.symmetric(
                          vertical: screenSize.width < 600 ? 8 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(
                            screenSize.width < 600 ? 12 : 16,
                          ),
                          child: Column(
                            children: [
                              _infoTile(
                                Icons.person,
                                'Nombre de usuario:',
                                user.username,
                              ),
                              const Divider(height: 20),
                              _infoTile(
                                Icons.email,
                                'Correo electrónico:',
                                user.email,
                              ),
                              const Divider(height: 20),
                              _infoTile(
                                Icons.perm_identity,
                                'ID de usuario:',
                                user.id.toString(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_error != null)
                        Container(
                          padding: EdgeInsets.all(
                            screenSize.width < 600 ? 10 : 12,
                          ),
                          margin: EdgeInsets.only(
                            bottom: screenSize.width < 600 ? 10 : 15,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                              SizedBox(width: screenSize.width < 600 ? 6 : 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: screenSize.width < 600 ? 14 : 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _passController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Confirmar contraseña',
                          hintText: 'Ingrese su contraseña',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(
                            Icons.lock,
                            color: Colors.blue.shade600,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.blue.shade600,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              Tooltip(
                                message:
                                    'Ingrese su contraseña para confirmar la eliminación.\n'
                                    'Esta acción es permanente y todos los datos de la cuenta\n'
                                    'serán eliminados irreversiblemente.',
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: screenSize.width < 600 ? 4 : 8,
                                  ),
                                  child: Icon(
                                    Icons.help_outline,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                      SizedBox(height: screenSize.width < 600 ? 16 : 24),
                      Row(
                        children: [
                          Expanded(
                            child: _build3DButton(
                              icon: Icons.logout,
                              text: 'Cerrar sesión',
                              color: Colors.blue,
                              screenSize: screenSize,
                              onPressed: () {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (_) => false,
                                );
                              },
                            ),
                          ),
                          SizedBox(width: screenSize.width < 600 ? 12 : 16),
                          Expanded(
                            child: _build3DButton(
                              icon: Icons.delete,
                              text: 'Eliminar cuenta',
                              color: Colors.red,
                              screenSize: screenSize,
                              onPressed: _eliminarCuenta,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenSize.width < 600 ? 16 : 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    final screenSize = MediaQuery.of(context).size;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: screenSize.width < 600 ? 18 : 20,
          color: Colors.blueGrey,
        ),
        SizedBox(width: screenSize.width < 600 ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: screenSize.width < 600 ? 12 : 14,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: screenSize.width < 600 ? 2 : 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: screenSize.width < 600 ? 14 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _build3DButton({
    required IconData icon,
    required String text,
    required Color color,
    required Size screenSize,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: screenSize.width < 600 ? 48 : 50,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: screenSize.width < 600 ? 20 : 22),
        label: Text(
          text,
          style: TextStyle(
            fontSize: screenSize.width < 600 ? 14 : 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          shadowColor: color.withOpacity(0.5),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screenSize.width < 600 ? 12 : 16,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
