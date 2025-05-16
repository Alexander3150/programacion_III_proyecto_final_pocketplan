/// Manager centralizado para gestionar tarjetas en memoria durante la ejecución
class CardManager {
  // Implementación del patrón Singleton
  static final CardManager _instance = CardManager._internal();
  factory CardManager() => _instance;
  CardManager._internal();

  // Listas para almacenar tarjetas en memoria
  final List<CreditCard> _creditCards = [];
  final List<DebitCard> _debitCards = [];

  //---------------- Métodos para tarjetas de crédito ----------------
  /// Obtiene lista de tarjetas de crédito (lista inmutable)
  List<CreditCard> get creditCards => List.unmodifiable(_creditCards);

  /// Agrega una nueva tarjeta de crédito
  void addCreditCard(CreditCard card) {
    _creditCards.add(card);
  }

  /// Actualiza una tarjeta de crédito existente
  void updateCreditCard(String id, CreditCard newCard) {
    final index = _creditCards.indexWhere((card) => card.id == id);
    if (index != -1) {
      _creditCards[index] = newCard;
    }
  }

  /// Elimina una tarjeta de crédito por su ID
  void removeCreditCard(String id) {
    _creditCards.removeWhere((card) => card.id == id);
  }

  //---------------- Métodos para tarjetas de débito ----------------
  /// Obtiene lista de tarjetas de débito (lista inmutable)
  List<DebitCard> get debitCards => List.unmodifiable(_debitCards);

  /// Agrega una nueva tarjeta de débito
  void addDebitCard(DebitCard card) {
    _debitCards.add(card);
  }

  /// Actualiza una tarjeta de débito existente
  void updateDebitCard(String id, DebitCard newCard) {
    final index = _debitCards.indexWhere((card) => card.id == id);
    if (index != -1) {
      _debitCards[index] = newCard;
    }
  }

  /// Elimina una tarjeta de débito por su ID
  void removeDebitCard(String id) {
    _debitCards.removeWhere((card) => card.id == id);
  }
}

/// Modelo de datos para tarjetas de crédito
class CreditCard {
  final String id;
  final String banco;
  final String numero;
  final String alias;
  final double limite;
  final String expiracion;
  final String corte;
  final String pago;

  CreditCard({
    required this.id,
    required this.banco,
    required this.numero,
    required this.alias,
    required this.limite,
    required this.expiracion,
    required this.corte,
    required this.pago,
  });

  @override
  String toString() {
    return 'CreditCard($banco - $alias)';
  }
}

/// Modelo de datos para tarjetas de débito
class DebitCard {
  final String id;
  final String banco;
  final String numero;
  final String alias;
  final String expiracion;

  DebitCard({
    required this.id,
    required this.banco,
    required this.numero,
    required this.alias,
    required this.expiracion,
  });

  @override
  String toString() {
    return 'DebitCard($banco - $alias)';
  }
}
