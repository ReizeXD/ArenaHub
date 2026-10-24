import 'dart:typed_data';

import '../../../../core/failure.dart';
import '../../../../core/result.dart';
import '../entities/court.dart';
import '../entities/sport.dart';
import '../repositories/court_repository.dart';
import '../services/court_image_storage.dart';

/// Caso de uso: atualizar os dados de uma quadra pelo próprio dono.
class UpdateCourt {
  const UpdateCourt(this._courts, this._imageStorage);

  final CourtRepository _courts;
  final CourtImageStorage _imageStorage;

  Future<Result<Court>> call({
    required Court existing,
    required String userId,
    required String name,
    required Sport sport,
    required String address,
    required int pricePerHourInCents,
    int openingHour = 8,
    int closingHour = 22,
    String? imageUrl,
    Uint8List? newImageBytes,
    String imageMimeType = 'image/jpeg',
  }) async {
    if (!existing.isOwnedBy(userId)) {
      return const Err(UnauthorizedCourtActionFailure());
    }

    final validated = Court.validated(
      id: existing.id,
      ownerId: existing.ownerId,
      name: name,
      sport: sport,
      address: address,
      pricePerHourInCents: pricePerHourInCents,
      imageUrl: imageUrl ?? existing.imageUrl,
      openingHour: openingHour,
      closingHour: closingHour,
    );
    if (validated case Err<Court> error) return error;

    var court = (validated as Ok<Court>).value;

    if (newImageBytes != null && newImageBytes.isNotEmpty) {
      final uploadResult = await _imageStorage.upload(
        ownerId: userId,
        courtId: existing.id,
        bytes: newImageBytes,
        mimeType: imageMimeType,
      );
      if (uploadResult case Err<String> error) return error.cast();
      court = court.copyWith(imageUrl: (uploadResult as Ok<String>).value);
    }

    return _courts.update(court);
  }
}
