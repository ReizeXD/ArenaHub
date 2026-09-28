import 'sport.dart';

/// Uma quadra disponível para aluguel.
class Court {
  const Court({
    required this.id,
    required this.name,
    required this.sport,
    required this.address,
    required this.pricePerHourInCents,
    this.openingHour = 8,
    this.closingHour = 22,
  });

  final String id;
  final String name;
  final Sport sport;
  final String address;
  final int pricePerHourInCents;

  /// Primeira hora com início possível (8 = 08:00).
  final int openingHour;

  /// Hora em que a quadra fecha (22 = último jogo começa 21:00).
  final int closingHour;

  /// `R$ 120,00` — formatação de moeda no padrão brasileiro.
  String get formattedPrice {
    final reais = pricePerHourInCents ~/ 100;
    final cents = (pricePerHourInCents % 100).toString().padLeft(2, '0');
    return 'R\$ $reais,$cents';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Court && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
