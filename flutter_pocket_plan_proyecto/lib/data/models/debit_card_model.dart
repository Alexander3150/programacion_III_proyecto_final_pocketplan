/// Modelo de tarjeta de débito.
class DebitCard {
  final int? id;
  final int userId;
  final String banco;
  final String numero;
  final String alias;
  final String expiracion;

  DebitCard({
    this.id,
    required this.userId,
    required this.banco,
    required this.numero,
    required this.alias,
    required this.expiracion,
  });

  factory DebitCard.fromMap(Map<String, dynamic> map) {
    return DebitCard(
      id: map['id'],
      userId: map['user_id'],
      banco: map['banco'],
      numero: map['numero'],
      alias: map['alias'],
      expiracion: map['expiracion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'banco': banco,
      'numero': numero,
      'alias': alias,
      'expiracion': expiracion,
    };
  }

  DebitCard copyWith({
    int? id,
    int? userId,
    String? banco,
    String? numero,
    String? alias,
    String? expiracion,
  }) {
    return DebitCard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      banco: banco ?? this.banco,
      numero: numero ?? this.numero,
      alias: alias ?? this.alias,
      expiracion: expiracion ?? this.expiracion,
    );
  }
}
