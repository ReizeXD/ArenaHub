import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';

import 'sport.dart';

/// Uma quadra disponível para aluguel.
class Court {
  const Court({
    required this.id,
    this.ownerId = '',
    required this.name,
    required this.sport,
    required this.address,
    required this.pricePerHourInCents,
    this.imageUrl = '',
    this.openingHour = 8,
    this.closingHour = 22,
  });

  final String id;
  final String ownerId;
  final String name;
  final Sport sport;
  final String address;
  final int pricePerHourInCents;

  /// Foto da quadra. Vazio é válido: a tela cai no gradiente da modalidade.
  final String imageUrl;

  /// Primeira hora com início possível (8 = 08:00).
  final int openingHour;

  /// Hora em que a quadra fecha (22 = último jogo começa 21:00).
  final int closingHour;

  Court copyWith({
    String? id,
    String? ownerId,
    String? name,
    Sport? sport,
    String? address,
    int? pricePerHourInCents,
    String? imageUrl,
    int? openingHour,
    int? closingHour,
  }) => Court(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    name: name ?? this.name,
    sport: sport ?? this.sport,
    address: address ?? this.address,
    pricePerHourInCents: pricePerHourInCents ?? this.pricePerHourInCents,
    imageUrl: imageUrl ?? this.imageUrl,
    openingHour: openingHour ?? this.openingHour,
    closingHour: closingHour ?? this.closingHour,
  );

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

  /// Verifica se a quadra pertence a [userId].
  bool isOwnedBy(String userId) => ownerId.isNotEmpty && ownerId == userId;

  /// Constrói uma [Court] garantindo todas as invariantes de negócio.
  static Result<Court> validated({
    required String id,
    required String ownerId,
    required String name,
    required Sport sport,
    required String address,
    required int pricePerHourInCents,
    String imageUrl = '',
    int openingHour = 8,
    int closingHour = 22,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return const Err(InvalidCourtNameFailure());
    final trimmedAddress = address.trim();
    if (trimmedAddress.isEmpty) return const Err(InvalidCourtAddressFailure());
    if (pricePerHourInCents <= 0) return const Err(InvalidCourtPriceFailure());
    if (openingHour < 0 || closingHour > 24 || openingHour >= closingHour) {
      return const Err(InvalidOperatingHoursFailure());
    }
    return Ok(
      Court(
        id: id,
        ownerId: ownerId,
        name: trimmedName,
        sport: sport,
        address: trimmedAddress,
        pricePerHourInCents: pricePerHourInCents,
        imageUrl: imageUrl.trim(),
        openingHour: openingHour,
        closingHour: closingHour,
      ),
    );
  }
}
