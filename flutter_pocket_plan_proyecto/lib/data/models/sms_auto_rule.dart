class SmsAutoRule {
  final int? id;
  final int userId;
  final int tarjetaId;
  final String tipoTarjeta; // 'Crédito' o 'Débito'
  final bool enabled;
  final String sender;
  final String prefix;
  final String identifier;
  final String identifierType; // 'cuenta' o 'tarjeta'
  final String? alias;
  final String? bank;
  final DateTime? createdAt;

  SmsAutoRule({
    this.id,
    required this.userId,
    required this.tarjetaId,
    required this.tipoTarjeta,
    required this.enabled,
    required this.sender,
    required this.prefix,
    required this.identifier,
    required this.identifierType,
    this.alias,
    this.bank,
    this.createdAt,
  });

  SmsAutoRule copyWith({
    int? id,
    int? userId,
    int? tarjetaId,
    String? tipoTarjeta,
    bool? enabled,
    String? sender,
    String? prefix,
    String? identifier,
    String? identifierType,
    String? alias,
    String? bank,
    DateTime? createdAt,
  }) {
    return SmsAutoRule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tarjetaId: tarjetaId ?? this.tarjetaId,
      tipoTarjeta: tipoTarjeta ?? this.tipoTarjeta,
      enabled: enabled ?? this.enabled,
      sender: sender ?? this.sender,
      prefix: prefix ?? this.prefix,
      identifier: identifier ?? this.identifier,
      identifierType: identifierType ?? this.identifierType,
      alias: alias ?? this.alias,
      bank: bank ?? this.bank,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'tarjeta_id': tarjetaId,
      'tipo_tarjeta': tipoTarjeta,
      'enabled': enabled ? 1 : 0,
      'sender': sender,
      'prefix': prefix,
      'identifier': identifier,
      'identifier_type': identifierType,
      'alias': alias,
      'bank': bank,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory SmsAutoRule.fromMap(Map<String, dynamic> map) {
    return SmsAutoRule(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      tarjetaId: map['tarjeta_id'] as int,
      tipoTarjeta: map['tipo_tarjeta'] as String,
      enabled: (map['enabled'] as int) == 1,
      sender: map['sender'] as String,
      prefix: map['prefix'] as String,
      identifier: map['identifier'] as String,
      identifierType: map['identifier_type'] as String,
      alias: map['alias'] as String?,
      bank: map['bank'] as String?,
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }
}
