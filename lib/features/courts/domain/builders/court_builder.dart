import '../../../../core/result.dart';
import '../entities/court.dart';
import '../entities/sport.dart';

/// Builder Pattern:
/// Constrói uma instância imutável de [Court] passo a passo e valida todas
/// as regras de negócio apenas no momento final do [build].
class CourtBuilder {
  CourtBuilder();

  /// Inicializa o builder copiando os dados de uma quadra já existente
  /// (usado no fluxo de edição de quadra).
  CourtBuilder.fromExisting(Court existing)
      : _id = existing.id,
        _ownerId = existing.ownerId,
        _name = existing.name,
        _sport = existing.sport,
        _address = existing.address,
        _pricePerHourInCents = existing.pricePerHourInCents,
        _imageUrl = existing.imageUrl,
        _openingHour = existing.openingHour,
        _closingHour = existing.closingHour;

  String _id = '';
  String _ownerId = '';
  String _name = '';
  Sport _sport = Sport.society;
  String _address = '';
  int _pricePerHourInCents = 0;
  String _imageUrl = '';
  int _openingHour = 8;
  int _closingHour = 22;

  CourtBuilder setId(String id) {
    _id = id;
    return this;
  }

  CourtBuilder setOwnerId(String ownerId) {
    _ownerId = ownerId;
    return this;
  }

  CourtBuilder setName(String name) {
    _name = name;
    return this;
  }

  CourtBuilder setSport(Sport sport) {
    _sport = sport;
    return this;
  }

  CourtBuilder setAddress(String address) {
    _address = address;
    return this;
  }

  CourtBuilder setPricePerHourInCents(int pricePerHourInCents) {
    _pricePerHourInCents = pricePerHourInCents;
    return this;
  }

  CourtBuilder setImageUrl(String imageUrl) {
    _imageUrl = imageUrl;
    return this;
  }

  CourtBuilder setOperatingHours(int openingHour, int closingHour) {
    _openingHour = openingHour;
    _closingHour = closingHour;
    return this;
  }

  /// Etapa final: valida os dados acumulados e entrega a [Court] pronta.
  Result<Court> build() {
    return Court.validated(
      id: _id,
      ownerId: _ownerId,
      name: _name,
      sport: _sport,
      address: _address,
      pricePerHourInCents: _pricePerHourInCents,
      imageUrl: _imageUrl,
      openingHour: _openingHour,
      closingHour: _closingHour,
    );
  }
}
