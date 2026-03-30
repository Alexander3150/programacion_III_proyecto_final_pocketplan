import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../../data/models/debit_card_model.dart';
import '../../data/models/sms_auto_rule.dart';
import '../../data/models/repositories/tarjeta_debito_repository.dart';
import '../../data/models/repositories/sms_auto_rule_repository.dart';
import '../widgets/global_components.dart';
import 'movimientos_tarjeta_page.dart';
import 'history_cards_screen.dart';

int getCurrentUserId(BuildContext context) {
  final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
  return usuarioProvider.usuario?.id ?? 0;
}





class DebitCardColors {
  static const Color background = Color(0xFFF5FDF7);
  static const Color primary = Color(0xFF2E7D32);
  static const Color secondary = Color(0xFF4CAF50);
  static const Color accent = Color(0xFF00B0FF);
  static const Color error = Color(0xFFE53935);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Colors.white;
}
class ModificacionDetalleTarjetaDebitoScreen extends StatelessWidget {
  final DebitCard tarjeta;
  final bool modoEdicion;

  const ModificacionDetalleTarjetaDebitoScreen({
    super.key,
    required this.tarjeta,
    this.modoEdicion = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: modoEdicion ? 'Modificar Tarjeta' : 'Detalles de Tarjeta',
      body: _ModificacionDetalleTarjetaDebitoContent(
        tarjeta: tarjeta,
        modoEdicion: modoEdicion,
      ),
      mostrarDrawer: true,
      mostrarBotonHome: true,
      navIndex: 0,
    );
  }
}
class _ModificacionDetalleTarjetaDebitoContent extends StatefulWidget {
  final DebitCard tarjeta;
  final bool modoEdicion;

  const _ModificacionDetalleTarjetaDebitoContent({
    required this.tarjeta,
    required this.modoEdicion,
  });

  @override
  State<_ModificacionDetalleTarjetaDebitoContent> createState() =>
      _ModificacionDetalleTarjetaDebitoContentState();
}

class _ModificacionDetalleTarjetaDebitoContentState
    extends State<_ModificacionDetalleTarjetaDebitoContent> {
  late TextEditingController _bancoController;
  late TextEditingController _numeroTarjetaController;
  late TextEditingController _aliasController;
  late TextEditingController _fechaExpiracionController;
  late TextEditingController _smsSenderController;
  late TextEditingController _smsPrefixController;
  late TextEditingController _smsIdentifierController;
  late TextEditingController _smsAliasController;

  String? _errorBanco;
  String? _errorNumeroTarjeta;
  String? _errorAlias;
  String? _errorFechaExpiracion;
  String? _errorSmsSender;
  String? _errorSmsPrefix;
  String? _errorSmsIdentifier;
  String _smsIdentifierType = 'cuenta';
  bool _autoSmsEnabled = false;
  SmsAutoRule? _smsRule;

  final FocusNode _bancoFocusNode = FocusNode();
  final FocusNode _numeroTarjetaFocusNode = FocusNode();
  final FocusNode _aliasFocusNode = FocusNode();
  final FocusNode _fechaExpiracionFocusNode = FocusNode();
  final FocusNode _smsSenderFocusNode = FocusNode();
  final FocusNode _smsPrefixFocusNode = FocusNode();
  final FocusNode _smsIdentifierFocusNode = FocusNode();
  final FocusNode _smsAliasFocusNode = FocusNode();

  late final TarjetaDebitoRepository _debitCardRepository;
  late final SmsAutoRuleRepository _smsRuleRepository;

  @override
  void initState() {
    super.initState();
    _bancoController = TextEditingController(text: widget.tarjeta.banco);
    _numeroTarjetaController = TextEditingController(
      text: widget.tarjeta.numero,
    );
    _aliasController = TextEditingController(text: widget.tarjeta.alias);
    _fechaExpiracionController = TextEditingController(
      text: widget.tarjeta.expiracion,
    );
    _smsSenderController = TextEditingController(text: '+2424');
    _smsPrefixController = TextEditingController(text: 'BiMovil:');
    _smsIdentifierController = TextEditingController();
    _smsAliasController = TextEditingController();

    _setupFocusListeners();
    _debitCardRepository = TarjetaDebitoRepository();
    _smsRuleRepository = SmsAutoRuleRepository();
    _cargarSmsRule();
  }

  void _setupFocusListeners() {
    _bancoFocusNode.addListener(() => setState(() {}));
    _numeroTarjetaFocusNode.addListener(() => setState(() {}));
    _aliasFocusNode.addListener(() => setState(() {}));
    _fechaExpiracionFocusNode.addListener(() => setState(() {}));
    _smsSenderFocusNode.addListener(() => setState(() {}));
    _smsPrefixFocusNode.addListener(() => setState(() {}));
    _smsIdentifierFocusNode.addListener(() => setState(() {}));
    _smsAliasFocusNode.addListener(() => setState(() {}));
  }

  Future<void> _cargarSmsRule() async {
    final userId = getCurrentUserId(context);
    final rule = await _smsRuleRepository.getRuleByCard(
      userId,
      widget.tarjeta.id!,
      'DÃ©bito',
    );
    if (!mounted) return;
    setState(() {
      _smsRule = rule;
      _autoSmsEnabled = rule?.enabled ?? false;
      _smsSenderController.text = rule?.sender ?? '+2424';
      _smsPrefixController.text = rule?.prefix ?? 'BiMovil:';
      _smsIdentifierController.text = rule?.identifier ?? '';
      _smsAliasController.text = rule?.alias ?? '';
      _smsIdentifierType = rule?.identifierType ?? 'cuenta';
    });
  }

  @override
  void dispose() {
    _bancoController.dispose();
    _numeroTarjetaController.dispose();
    _aliasController.dispose();
    _fechaExpiracionController.dispose();
    _smsSenderController.dispose();
    _smsPrefixController.dispose();
    _smsIdentifierController.dispose();
    _smsAliasController.dispose();

    _bancoFocusNode.dispose();
    _numeroTarjetaFocusNode.dispose();
    _aliasFocusNode.dispose();
    _fechaExpiracionFocusNode.dispose();
    _smsSenderFocusNode.dispose();
    _smsPrefixFocusNode.dispose();
    _smsIdentifierFocusNode.dispose();
    _smsAliasFocusNode.dispose();
    super.dispose();
  }

  void _validarFechaExpiracion(String value) {
    if (value.isEmpty) {
      setState(() => _errorFechaExpiracion = 'Ingrese la fecha de expiraciÃ³n');
      return;
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      setState(() => _errorFechaExpiracion = 'Formato invÃ¡lido (MM/AA)');
      return;
    }
    final parts = value.split('/');
    final mes = int.tryParse(parts[0]) ?? 0;
    final anio = int.tryParse(parts[1]) ?? 0;

    if (mes < 1 || mes > 12) {
      setState(() => _errorFechaExpiracion = 'Mes invÃ¡lido (1-12)');
      return;
    }
    final currentYear = DateTime.now().year % 100;
    if (anio < currentYear) {
      setState(
        () => _errorFechaExpiracion = 'AÃ±o no puede ser anterior al actual',
      );
      return;
    }

    setState(() => _errorFechaExpiracion = null);
  }

  void _validarCampos() {
    setState(() {
      // Banco: requerido y mÃ¡ximo 50 caracteres
      if (_bancoController.text.isEmpty) {
        _errorBanco = 'Ingrese el banco';
      } else if (_bancoController.text.length > 50) {
        _errorBanco = 'MÃ¡x. 50 caracteres';
      } else {
        _errorBanco = null;
      }

      // NÃºmero de tarjeta: requerido y exactamente 4 dÃ­gitos
      if (_numeroTarjetaController.text.isEmpty) {
        _errorNumeroTarjeta = 'Ingrese el nÃºmero';
      } else if (_numeroTarjetaController.text.length != 4) {
        _errorNumeroTarjeta = 'Debe tener 4 dÃ­gitos';
      } else {
        _errorNumeroTarjeta = null;
      }

      // Nombre del titular: requerido y mÃ¡ximo 50 caracteres
      if (_aliasController.text.isEmpty) {
        _errorAlias = 'Ingrese el nombre del titular';
      } else if (_aliasController.text.length > 50) {
        _errorAlias = 'MÃ¡x. 50 caracteres';
      } else {
        _errorAlias = null;
      }

      // Fecha de expiraciÃ³n: requerido y con validaciÃ³n de formato
      if (_fechaExpiracionController.text.isEmpty) {
        _errorFechaExpiracion = 'Ingrese la fecha de expiraciÃ³n';
      } else {
        _validarFechaExpiracion(_fechaExpiracionController.text);
      }

      if (_autoSmsEnabled) {
        if (_smsSenderController.text.trim().isEmpty) {
          _errorSmsSender = 'Ingrese el remitente';
        } else {
          _errorSmsSender = null;
        }
        if (_smsPrefixController.text.trim().isEmpty) {
          _errorSmsPrefix = 'Ingrese el prefijo';
        } else {
          _errorSmsPrefix = null;
        }
        if (_smsIdentifierController.text.trim().isEmpty) {
          _errorSmsIdentifier = 'Ingrese el identificador';
        } else {
          _errorSmsIdentifier = null;
        }
      } else {
        _errorSmsSender = null;
        _errorSmsPrefix = null;
        _errorSmsIdentifier = null;
      }
    });
  }

  Future<void> _actualizarTarjeta() async {
    if (!widget.modoEdicion) return;
    _validarCampos();
    if (_errorBanco == null &&
        _errorNumeroTarjeta == null &&
        _errorAlias == null &&
        _errorFechaExpiracion == null &&
        _errorSmsSender == null &&
        _errorSmsPrefix == null &&
        _errorSmsIdentifier == null) {
      final tarjetaActualizada = DebitCard(
        id: widget.tarjeta.id,
        userId: widget.tarjeta.userId,
        banco: _bancoController.text,
        numero: _numeroTarjetaController.text,
        alias: _aliasController.text,
        expiracion: _fechaExpiracionController.text,
      );

      final result = await _debitCardRepository.updateTarjetaDebito(
        tarjetaActualizada,
      );

      if (result > 0) {
        if (_autoSmsEnabled) {
          final rule = SmsAutoRule(
            id: _smsRule?.id,
            userId: tarjetaActualizada.userId,
            tarjetaId: tarjetaActualizada.id!,
            tipoTarjeta: 'Débito',
            enabled: true,
            sender: _smsSenderController.text.trim(),
            prefix: _smsPrefixController.text.trim(),
            identifier: _smsIdentifierController.text.trim().toUpperCase(),
            identifierType: _smsIdentifierType,
            alias:
                _smsAliasController.text.trim().isEmpty
                    ? _aliasController.text.trim()
                    : _smsAliasController.text.trim(),
            bank: _bancoController.text.trim(),
          );
          if (_smsRule?.id != null) {
            await _smsRuleRepository.updateRule(rule);
          } else {
            await _smsRuleRepository.insertRule(rule);
          }
          _smsRule = rule;
        } else if (_smsRule?.id != null) {
          await _smsRuleRepository.deleteRule(
            _smsRule!.id!,
            tarjetaActualizada.userId,
          );
          _smsRule = null;
        }
        /* // Cancelar notificaciones anteriores
        await NotificationService().cancelDebitCardNotifications(
          tarjetaActualizada.id!,
          tarjetaActualizada.userId,
        );
        // Programar nuevas notificaciones para la tarjeta actualizada
        await NotificationService().scheduleDebitCardNotifications(
          tarjetaActualizada,
          tarjetaActualizada.userId,
        );*/

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tarjeta actualizada con Ã©xito'),
            backgroundColor: DebitCardColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HistoryCardsScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo actualizar la tarjeta'),
            backgroundColor: DebitCardColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        color: DebitCardColors.background,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono de tarjeta de dÃ©bito
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: DebitCardColors.secondary.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 3,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: DebitCardColors.secondary,
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Campos del formulario
              _buildTextFieldWithIcon(
                controller: _bancoController,
                label: 'Banco',
                hint: 'Ej. Banco Industrial',
                icon: Icons.account_balance,
                errorText: _errorBanco,
                editable: widget.modoEdicion,
                focusNode: _bancoFocusNode,
                maxLength: 50,
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
              ),

              const SizedBox(height: 16),

              // Campo de nÃºmero de tarjeta con tooltip
              _buildTextFieldWithIcon(
                controller: _numeroTarjetaController,
                label: 'NÃºmero de tarjeta',
                hint: 'Ingrese los Ãºltimos 4 dÃ­gitos',
                icon: Icons.credit_card,
                errorText: _errorNumeroTarjeta,
                editable: widget.modoEdicion,
                focusNode: _numeroTarjetaFocusNode,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                helperText:
                    widget.modoEdicion
                        ? 'Por temas de seguridad, solo ingrese los Ãºltimos 4 dÃ­gitos de su tarjeta. Esto ayuda a proteger sus datos.'
                        : null,
              ),

              const SizedBox(height: 16),

              _buildTextFieldWithIcon(
                controller: _aliasController,
                label: 'Nombre del titular',
                hint: 'Ej. Pocket Plan',
                icon: Icons.label,
                errorText: _errorAlias,
                editable: widget.modoEdicion,
                focusNode: _aliasFocusNode,
                maxLength: 40,
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
              ),

              const SizedBox(height: 16),

              // Campo de fecha de expiraciÃ³n con formato MM/AA
              _buildExpirationDateField(),
              if (!widget.modoEdicion) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Ver historial de movimientos'),
                    onPressed: () {
                      final userId = getCurrentUserId(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => MovimientosTarjetaPage(
                                userId: userId,
                                tarjetaId: widget.tarjeta.id!,
                                tipoTarjeta: 'Débito',
                                titulo: 'Historial - ${widget.tarjeta.alias}',
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _buildSmsConfigSection(),
              const SizedBox(height: 32),

              // BotÃ³n de actualizar (solo en modo ediciÃ³n)
              if (widget.modoEdicion)
                Center(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: DebitCardColors.secondary.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: FloatingActionButton(
                          onPressed: _actualizarTarjeta,
                          backgroundColor: DebitCardColors.secondary,
                          elevation: 0,
                          child: const Icon(Icons.save, size: 30),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ACTUALIZAR TARJETA',
                        style: TextStyle(
                          color: DebitCardColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.1,
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
  }

  Widget _buildTextFieldWithIcon({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? errorText,
    required bool editable,
    required FocusNode focusNode,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? helperText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                label,
                style: TextStyle(
                  color: DebitCardColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            if (helperText != null && label == 'NÃºmero de tarjeta') ...[
              const SizedBox(width: 8),
              Tooltip(
                message: helperText,
                triggerMode: TooltipTriggerMode.tap,
                child: const Icon(
                  Icons.help_outline,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            style: TextStyle(color: DebitCardColors.textDark),
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            // Esto oculta el contador aunque haya maxLength:
            buildCounter:
                (
                  BuildContext context, {
                  required int currentLength,
                  required bool isFocused,
                  int? maxLength,
                }) => null,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              filled: true,
              fillColor: editable ? Colors.white : Colors.grey.shade200,
              prefixIcon: Icon(
                icon,
                color:
                    editable
                        ? (focusNode.hasFocus
                            ? const Color.fromARGB(255, 94, 216, 105)
                            : DebitCardColors.secondary)
                        : Colors.grey,
              ),
              hintText: hint,
              errorText: editable ? errorText : null,
              errorStyle: TextStyle(color: DebitCardColors.error),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: editable ? DebitCardColors.secondary : Colors.grey,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: DebitCardColors.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: DebitCardColors.error, width: 2),
              ),
              enabled: editable,
            ),
            onChanged:
                editable
                    ? (_) {
                      setState(() {
                        if (label.contains('Banco')) _errorBanco = null;
                        if (label.contains('NÃºmero'))
                          _errorNumeroTarjeta = null;
                        if (label.contains('Alias')) _errorAlias = null;
                      });
                    }
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _buildExpirationDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                'Fecha de expiraciÃ³n',
                style: TextStyle(
                  color: DebitCardColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            if (widget.modoEdicion) ...[
              const SizedBox(width: 8),
              Tooltip(
                message:
                    'Ingrese el mes y aÃ±o de expiraciÃ³n de su tarjeta en formato MM/AA. Ej: 12/25',
                triggerMode: TooltipTriggerMode.tap,
                child: const Icon(
                  Icons.help_outline,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: TextField(
            controller: _fechaExpiracionController,
            focusNode: _fechaExpiracionFocusNode,
            keyboardType: TextInputType.number,
            maxLength: 5,
            enabled: widget.modoEdicion,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _ExpirationDateFormatter(),
            ],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              filled: true,
              fillColor:
                  widget.modoEdicion ? Colors.white : Colors.grey.shade200,
              prefixIcon: Icon(
                Icons.calendar_today,
                color:
                    _fechaExpiracionFocusNode.hasFocus
                        ? DebitCardColors.secondary
                        : Colors.grey,
              ),
              hintText: 'MM/AA',
              errorText: widget.modoEdicion ? _errorFechaExpiracion : null,
              errorStyle: TextStyle(color: DebitCardColors.error),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      widget.modoEdicion
                          ? DebitCardColors.secondary
                          : Colors.grey,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: DebitCardColors.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: DebitCardColors.error, width: 2),
              ),
            ),
            onChanged:
                widget.modoEdicion
                    ? (value) {
                      _validarFechaExpiracion(value);
                      if (value.isEmpty) {
                        setState(() => _errorFechaExpiracion = null);
                      }
                    }
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSmsConfigSection() {
    final editable = widget.modoEdicion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Transacciones automÃ¡ticas por SMS',
                style: TextStyle(
                  color: DebitCardColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            Switch(
              value: _autoSmsEnabled,
              onChanged:
                  editable
                      ? (value) => setState(() => _autoSmsEnabled = value)
                      : null,
              activeColor: DebitCardColors.secondary,
            ),
          ],
        ),
        if (_autoSmsEnabled) ...[
          const SizedBox(height: 8),
          Text(
            'Configura cÃ³mo reconocer los mensajes del banco para esta tarjeta.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 12),
          _buildTextFieldWithIcon(
            controller: _smsSenderController,
            label: 'Remitente del SMS',
            hint: 'Ej. +2424',
            icon: Icons.message,
            errorText: _errorSmsSender,
            focusNode: _smsSenderFocusNode,
            editable: editable,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildTextFieldWithIcon(
            controller: _smsPrefixController,
            label: 'Prefijo del mensaje',
            hint: 'Ej. BiMovil:',
            icon: Icons.short_text,
            errorText: _errorSmsPrefix,
            focusNode: _smsPrefixFocusNode,
            editable: editable,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 12),
          _buildTextFieldWithIcon(
            controller: _smsIdentifierController,
            label: 'Identificador en el SMS',
            hint: 'Ej. BICHEQUE1',
            icon: Icons.tag,
            errorText: _errorSmsIdentifier,
            focusNode: _smsIdentifierFocusNode,
            editable: editable,
            keyboardType: TextInputType.text,
            helperText:
                'Este identificador aparece como Cuenta o Tarjeta en el SMS.',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _smsIdentifierType,
            decoration: const InputDecoration(
              labelText: 'Tipo de identificador',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'cuenta', child: Text('Cuenta')),
              DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
            ],
            onChanged:
                editable
                    ? (v) {
                      if (v == null) return;
                      setState(() => _smsIdentifierType = v);
                    }
                    : null,
          ),
          const SizedBox(height: 12),
          _buildTextFieldWithIcon(
            controller: _smsAliasController,
            label: 'Alias de la regla (opcional)',
            hint: 'Ej. Banco Industrial - BICHEQUE1',
            icon: Icons.edit_note,
            errorText: null,
            focusNode: _smsAliasFocusNode,
            editable: editable,
            keyboardType: TextInputType.text,
          ),
        ],
      ],
    );
  }

}

// Formateador personalizado para fecha de expiraciÃ³n MM/AA
class _ExpirationDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var newText = newValue.text;
    if (newText.length > 5) return oldValue;

    newText = newText.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.length >= 2) {
      newText = '${newText.substring(0, 2)}/${newText.substring(2)}';
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
