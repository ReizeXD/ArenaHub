import 'dart:typed_data';

import '../../../../core/failure.dart';
import '../../../../core/result.dart';
import '../builders/court_builder.dart';
import '../entities/court.dart';
import '../entities/sport.dart';
import '../repositories/court_repository.dart';
import '../services/court_image_storage.dart';

/// Caso de uso: atualizar os dados de uma quadra pelo próprio dono usando o [CourtBuilder].
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

    // Passo 1: Inicia o Builder a partir da quadra existente e atualiza os campos.
    final builder = CourtBuilder.fromExisting(existing)
        .setName(name)
        .setSport(sport)
        .setAddress(address)
        .setPricePerHourInCents(pricePerHourInCents)
        .setOperatingHours(openingHour, closingHour);

    if (imageUrl != null) {
      builder.setImageUrl(imageUrl);
    }

    // Passo 2: Valida os dados antes de fazer upload de imagem.
    final initialValidation = builder.build();
    if (initialValidation is Err<Court>) {
      return initialValidation;
    }

    // Passo 3: Se houver nova foto, faz o upload e atualiza a URL no Builder.
    if (newImageBytes != null && newImageBytes.isNotEmpty) {
      final uploadResult = await _imageStorage.upload(
        ownerId: userId,
        courtId: existing.id,
        bytes: newImageBytes,
        mimeType: imageMimeType,
      );
      if (uploadResult is Err<String>) {
        return Err(uploadResult.failure);
      }
      builder.setImageUrl((uploadResult as Ok<String>).value);
    }

    // Passo 4: Constrói a quadra final atualizada e persiste no repositório.
    final finalResult = builder.build();
    if (finalResult is Err<Court>) {
      return finalResult;
    }
    return _courts.update((finalResult as Ok<Court>).value);
  }
}
