import 'dart:typed_data';

import '../../../../core/result.dart';
import '../entities/court.dart';
import '../entities/sport.dart';
import '../repositories/court_repository.dart';
import '../services/court_image_storage.dart';

/// Caso de uso: cadastrar uma nova quadra pelo dono.
class CreateCourt {
  const CreateCourt(this._courts, this._imageStorage);

  final CourtRepository _courts;
  final CourtImageStorage _imageStorage;

  Future<Result<Court>> call({
    required String ownerId,
    required String name,
    required Sport sport,
    required String address,
    required int pricePerHourInCents,
    int openingHour = 8,
    int closingHour = 22,
    String imageUrl = '',
    Uint8List? imageBytes,
    String imageMimeType = 'image/jpeg',
  }) async {
    final id = _courts.nextIdentity();

    final validated = Court.validated(
      id: id,
      ownerId: ownerId,
      name: name,
      sport: sport,
      address: address,
      pricePerHourInCents: pricePerHourInCents,
      imageUrl: imageUrl,
      openingHour: openingHour,
      closingHour: closingHour,
    );
    if (validated case Err<Court> error) return error;

    var court = (validated as Ok<Court>).value;

    if (imageBytes != null && imageBytes.isNotEmpty) {
      final uploadResult = await _imageStorage.upload(
        ownerId: ownerId,
        courtId: id,
        bytes: imageBytes,
        mimeType: imageMimeType,
      );
      if (uploadResult case Err<String> error) return error.cast();
      court = court.copyWith(imageUrl: (uploadResult as Ok<String>).value);
    }

    return _courts.create(court);
  }
}
