import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/repositories/usuario_repository.dart';
import '../../data/models/user_model.dart';
import '../providers/user_provider.dart';
import '../widgets/global_components.dart';

// Para importar/exportar
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';

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
      mostrarBotonHome: true,
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

  // late final UsuarioRepository _usuarioRepository;
  /// late final SimuladorAhorroRepository _simAhorroRepository;
  // late final SimuladorDeudaRepository _simDeudaRepository;
  // late final TarjetaCreditoRepository _tarjetaCreditoRepository;
  // late final TarjetaDebitoRepository _tarjetaDebitoRepository;
  // late final CuotaAhorroRepository _cuotaAhorroRepository;
  // late final CuotaPagoRepository _cuotaPagoRepository;
  // late final MovimientoRepository _movimientoRepository;

  @override
  void initState() {
    super.initState();
    //_usuarioRepository = UsuarioRepository();
    /// _simAhorroRepository = SimuladorAhorroRepository();
    // _simDeudaRepository = SimuladorDeudaRepository();
    // _tarjetaCreditoRepository = TarjetaCreditoRepository();
    // _tarjetaDebitoRepository = TarjetaDebitoRepository();
    // _cuotaAhorroRepository = CuotaAhorroRepository();
    // _cuotaPagoRepository = CuotaPagoRepository();
    _passController.addListener(_validatePassword);

    /// _movimientoRepository = MovimientoRepository();
  }

  @override
  void dispose() {
    _passController.dispose();
    super.dispose();
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

  // ------------- EXPORTAR BASE DE DATOS -----------------
  Future<void> exportarBaseDeDatos(BuildContext context) async {
    // Feedback inicial
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.upload_file, color: Colors.white),
            SizedBox(width: 12),
            Text("Exportando base de datos..."),
          ],
        ),
        backgroundColor: Colors.blue[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(appDocDir.path, 'pocket_plan.db');
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text("No se encontró la base de datos en el dispositivo."),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'pocket_plan_backup_${DateTime.now().millisecondsSinceEpoch}.db';
      final tempPath = p.join(tempDir.path, fileName);

      await dbFile.copy(tempPath);

      await Share.shareXFiles(
        [XFile(tempPath)],
        text: '''
Archivo de respaldo PocketPlan

Guía para restaurar tus datos en otro dispositivo:

1. Envía este archivo de respaldo a tu nuevo dispositivo (puedes usar correo, Bluetooth, WhatsApp, Google Drive, etc.).

2. En el nuevo dispositivo, abre Pocket Plan e inicia la app.

3. **Crea una cuenta temporal** (por ejemplo, llamada "Importación" o cualquier nombre), solo para poder acceder al menú de importación. No importa el nombre o la contraseña: estos datos se reemplazarán.

4. Una vez dentro de la app, usa la opción de "Importar" y selecciona este archivo de respaldo.

5. **¡Importante!**: Al importar el respaldo, **se eliminarán todos los datos y usuarios existentes en el dispositivo** y serán reemplazados por los datos del archivo. 
   
6. Después de importar, **inicia sesión usando el nombre de usuario y contraseña que usabas en tu dispositivo anterior** (los que tenía el respaldo).

¡Así puedes mantener todos tus movimientos, tarjetas y registros financieros sin perder nada!

⚠️ Importante:
Este archivo contiene información privada de tus transacciones y cuentas. 
No lo compartas con otras personas para proteger tu privacidad.
  ''',
        subject: "Respaldo PocketPlan",
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text("Ocurrió un error al exportar la base de datos."),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ------------- IMPORTAR BASE DE DATOS (MODERNO) -----------------
  Future<bool> importarBaseDeDatos(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Mejor compatibilidad
      );

      if (result != null && result.files.single.path != null) {
        final selectedFile = File(result.files.single.path!);

        // Validar que sea .db
        if (!selectedFile.path.endsWith('.db')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Selecciona un archivo .db válido"),
                ],
              ),
              backgroundColor: Colors.red[700],
            ),
          );
          return false;
        }

        final appDocDir = await getApplicationDocumentsDirectory();
        final dbPath = p.join(appDocDir.path, 'pocket_plan.db');
        await selectedFile.copy(dbPath);

        // Éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.download_done, color: Colors.white),
                SizedBox(width: 12),
                Text("¡Base de datos importada exitosamente!"),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return true;
      } else {
        // Cancelado por el usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 12),
                Text("Importación cancelada."),
              ],
            ),
            backgroundColor: Colors.blueGrey,
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Text("Ocurrió un error al importar la base de datos.\n$e"),
            ],
          ),
          backgroundColor: Colors.red[700],
        ),
      );
      return false;
    }
  }

  // --------- Elimina TODOS los datos del usuario ----------
  /*Future<void> deleteAllUserData(int userId) async {
    final simAhorros = await _simAhorroRepository.getSimuladoresAhorroByUser(
      userId,
    );
    for (final sa in simAhorros) {
      final cuotas = await _cuotaAhorroRepository.getCuotasPorSimuladorId(
        sa.id!,
        userId,
      );
      for (final cuota in cuotas) {
        await _cuotaAhorroRepository.deleteCuotaAhorro(cuota.id!, userId);
      }
      await _simAhorroRepository.deleteSimuladorAhorro(sa.id!, userId);
    }
    final simDeudas = await _simDeudaRepository.getSimuladoresDeudaByUser(
      userId,
    );
    for (final sd in simDeudas) {
      final cuotas = await _cuotaPagoRepository.getCuotasPorSimuladorId(
        sd.id!,
        userId,
      );
      for (final cuota in cuotas) {
        await _cuotaPagoRepository.deleteCuotaPago(cuota.id!, userId);
      }
      await _simDeudaRepository.deleteSimuladorDeuda(sd.id!, userId);
    }
    final tarjetasCredito = await _tarjetaCreditoRepository
        .getTarjetasCreditoByUser(userId);
    for (final tc in tarjetasCredito) {
      await _tarjetaCreditoRepository.deleteTarjetaCredito(tc.id!, userId);
    }
    final tarjetasDebito = await _tarjetaDebitoRepository
        .getTarjetasDebitoByUser(userId);
    for (final td in tarjetasDebito) {
      await _tarjetaDebitoRepository.deleteTarjetaDebito(td.id!, userId);
    }
    await _movimientoRepository.limpiarMovimientosUsuario(userId);
  }

  // ------------- ELIMINAR CUENTA -----------------
  Future<void> _eliminarCuenta() async {
    final passwordIngresada = _passController.text.trim();

    final userFromDb = await _usuarioRepository.getUsuarioByUsername(
      widget.usuario.username,
    );

    if (userFromDb != null && userFromDb.password == passwordIngresada) {
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
                  onPressed: () async {
                    if (userFromDb.id == null) {
                      setState(() {
                        _error = 'Error interno: el usuario no tiene ID';
                      });
                      Navigator.pop(context);
                      return;
                    }

                    final userId = userFromDb.id!;
                    await deleteAllUserData(userId);

                    final result = await _usuarioRepository.deleteUsuario(
                      userId,
                    );
                    Navigator.pop(context);

                    if (result > 0) {
                      if (mounted) {
                        Provider.of<UsuarioProvider>(
                          context,
                          listen: false,
                        ).cerrarSesion();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (_) => false,
                        );
                      }
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
*/
  // Este metodo se tiene que eliminar cuando ya todo este bien
  void _mostrarDialogoEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar la cuenta? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            TextButton(
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // Cierra el diálogo

                // Muestra el SnackBar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Cuenta eliminada exitosamente!'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.usuario;
    final screenSize = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/resumen');
        return false;
      },
      child: LayoutBuilder(
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
                    padding: EdgeInsets.all(
                      screenSize.width < 600 ? 16.0 : 24.0,
                    ),
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

                        // --------- BOTONES EXPORTAR / IMPORTAR --------------
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: _build3DButton(
                                  icon: Icons.import_export,
                                  text: 'Exportar',
                                  color: Colors.indigo,
                                  screenSize: screenSize,
                                  onPressed: () => exportarBaseDeDatos(context),
                                ),
                              ),
                              SizedBox(width: screenSize.width < 600 ? 12 : 18),
                              Expanded(
                                child: _build3DButton(
                                  icon: Icons.input,
                                  text: 'Importar',
                                  color: Colors.teal,
                                  screenSize: screenSize,
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder:
                                          (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                            ),
                                            title: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.orange.shade100,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.warning_amber_rounded,
                                                    color: Colors.orange,
                                                    size: 34,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Text(
                                                  "¡Advertencia!",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 22,
                                                    color: Colors.orange,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            content: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                    horizontal: 2,
                                                  ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    "Vas a reemplazar **todos los datos actuales** de Pocket Plan con los del archivo que selecciones.",
                                                    style: TextStyle(
                                                      fontSize: 17,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 18),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.orange.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      border: Border.all(
                                                        color:
                                                            Colors.orangeAccent,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: const [
                                                        Icon(
                                                          Icons
                                                              .info_outline_rounded,
                                                          color: Colors.orange,
                                                          size: 22,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            "Después tendrás que iniciar sesión con el usuario y contraseña con los que realizaste el respaldo.",
                                                            style: TextStyle(
                                                              fontSize: 15.2,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                child: const Text(
                                                  "Cancelar",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                              ),
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.teal,
                                                  elevation: 5,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 22,
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                                icon: const Icon(
                                                  Icons.check_circle_outline,
                                                  size: 20,
                                                  color: Colors.white,
                                                ),
                                                label: const Text(
                                                  "Sí, estoy seguro",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                              ),
                                            ],
                                          ),
                                    );

                                    if (confirm == true) {
                                      // Loader moderno
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder:
                                            (context) => AlertDialog(
                                              backgroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              content: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 22,
                                                      horizontal: 12,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    const CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.teal),
                                                      strokeWidth: 5,
                                                    ),
                                                    const SizedBox(width: 24),
                                                    Expanded(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: const [
                                                          Text(
                                                            "Importando base de datos...",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 17.5,
                                                            ),
                                                          ),
                                                          SizedBox(height: 4),
                                                          Text(
                                                            "No cierres la app ni cambies de pantalla.",
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors
                                                                      .black54,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                      );

                                      final exito = await importarBaseDeDatos(
                                        context,
                                      );

                                      // Cierra loader
                                      if (context.mounted)
                                        Navigator.pop(context);

                                      if (exito && context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).clearSnackBars();
                                        await Future.delayed(
                                          const Duration(milliseconds: 300),
                                        );
                                        await showDialog(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                title: Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors
                                                                .green
                                                                .shade100,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.check_circle,
                                                        color: Colors.teal,
                                                        size: 34,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    const Text(
                                                      "¡Importación Exitosa!",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 20,
                                                        color: Colors.teal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: const [
                                                    Text(
                                                      "La base de datos fue importada correctamente.",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    SizedBox(height: 14),
                                                    Divider(
                                                      height: 2,
                                                      thickness: 1,
                                                    ),
                                                    SizedBox(height: 12),
                                                    Icon(
                                                      Icons.restart_alt_rounded,
                                                      color: Colors.teal,
                                                      size: 30,
                                                    ),
                                                    SizedBox(height: 10),
                                                    Text(
                                                      "Por tu seguridad, Pocket Plan te recomienda cerrar la aplicación y volver a abrirla.\n\n"
                                                      "Luego, inicia sesión con el usuario y contraseña con los que creaste el respaldo.\n\n"
                                                      "¡Tus datos han sido restaurados!",
                                                      style: TextStyle(
                                                        fontSize: 15.2,
                                                        color: Colors.black87,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  Center(
                                                    child: ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.teal,
                                                        foregroundColor:
                                                            Colors
                                                                .white, // <- Esto pone el texto en blanco
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 30,
                                                              vertical: 12,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                14,
                                                              ),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        "Entendido",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          // color: Colors.white, // Este NO es necesario si usas foregroundColor
                                                        ),
                                                      ),
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenSize.width < 600 ? 10 : 16),

                        // --------- FIN NUEVOS BOTONES ---------
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
                                      fontSize:
                                          screenSize.width < 600 ? 14 : 16,
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
                          maxLength: 20,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          decoration: InputDecoration(
                            labelText: 'Confirmar contraseña',
                            hintText:
                                'Ingrese su contraseña para eliminar su perfil',
                            hintStyle: TextStyle(
                              fontSize: screenSize.width < 600 ? 12 : 14,
                              color: Colors.grey.shade400,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.shade300,
                              ),
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
                            counterText: '',
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
                                onPressed: () {
                                  _mostrarDialogoEliminar(context);
                                },
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
      ),
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
