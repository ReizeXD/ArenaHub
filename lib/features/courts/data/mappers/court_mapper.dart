import '../../domain/entities/court.dart';
import '../../domain/entities/sport.dart';

/// Traduz [Court] de/para o formato do documento no Firestore.
class CourtMapper {
  const CourtMapper();

  Map<String, Object?> toMap(Court court) => <String, Object?>{
        'owner_id': court.ownerId,
        'name': court.name,
        'sport': court.sport.wire,
        'address': court.address,
        'price_per_hour_in_cents': court.pricePerHourInCents,
        'image_url': court.imageUrl,
        'opening_hour': court.openingHour,
        'closing_hour': court.closingHour,
      };

  /// O id vem da chave do documento, não de dentro dele — assim não existe a
  /// chance de os dois discordarem.
  Court fromMap(String id, Map<String, Object?> data) => Court(
        id: id,
        ownerId: (data['owner_id'] as String?) ?? '',
        name: (data['name'] as String?) ?? 'Quadra sem nome',
        sport: Sport.fromWire((data['sport'] as String?) ?? ''),
        address: (data['address'] as String?) ?? '',
        pricePerHourInCents:
            (data['price_per_hour_in_cents'] as num?)?.toInt() ?? 0,
        imageUrl: (data['image_url'] as String?) ?? '',
        openingHour: (data['opening_hour'] as num?)?.toInt() ?? 8,
        closingHour: (data['closing_hour'] as num?)?.toInt() ?? 22,
      );
}
