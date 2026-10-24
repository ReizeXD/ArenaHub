import 'dart:typed_data';

import '../../../../core/failure.dart';
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
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return const Err(InvalidCourtNameFailure());

    final trimmedAddress = address.trim();
    if (trimmedAddress.isEmpty) return const Err(InvalidCourtAddressFailure());

    if (pricePerHourInCents <= 0) return const Err(InvalidCourtPriceFailure());

    if (openingHour < 0 ||
        closingHour > 24 ||
        openingHour >= closingHour) {
      return const Err(InvalidOperatingHoursFailure());
    }

    final id = _courts.nextIdentity();

    var resolvedImageUrl = imageUrl.trim();
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final uploadResult = await _imageStorage.upload(
        ownerId: ownerId,
        courtId: id,
        bytes: imageBytes,
        mimeType: imageMimeType,
      );
      if (uploadResult case Err<String> error) return error.cast();
      resolvedImageUrl = (uploadResult as Ok<String>).value;
    }

    return _courts.create(
      Court(
        id: id,
        ownerId: ownerId,
        name: trimmedName,
        sport: sport,
        address: trimmedAddress,
        pricePerHourInCents: pricePerHourInCents,
        imageUrl: resolvedImageUrl,
        openingHour: openingHour,
        closingHour: closingHour,
      ),
    );
  }
}