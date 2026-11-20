import 'dart:typed_data';

import '../../../../core/result.dart';
import '../builders/court_builder.dart';
import '../entities/court.dart';
import '../entities/sport.dart';
import '../repositories/court_repository.dart';
import '../services/court_image_storage.dart';

/// Caso de uso: cadastrar uma nova quadra pelo dono usando o [CourtBuilder].
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

    // Passo 1: Configura os dados básicos no Builder.
    final builder = CourtBuilder()
        .setId(id)
        .setOwnerId(ownerId)
        .setName(name)
        .setSport(sport)
        .setAddress(address)
        .setPricePerHourInCents(pricePerHourInCents)
        .setImageUrl(imageUrl)
        .setOperatingHours(openingHour, closingHour);

    // Passo 2: Valida os dados antes de fazer upload de imagem.
    final initialValidation = builder.build();
    if (initialValidation is Err<Court>) {
      return initialValidation;
    }

    // Passo 3: Se o proprietário enviou uma foto, faz o upload e adiciona a URL no Builder.
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final uploadResult = await _imageStorage.upload(
        ownerId: ownerId,
        courtId: id,
        bytes: imageBytes,
        mimeType: imageMimeType,
      );
      if (uploadResult is Err<String>) {
        return Err(uploadResult.failure);
      }
      builder.setImageUrl((uploadResult as Ok<String>).value);
    }

    // Passo 4: Constrói a quadra final imutável e salva no repositório.
    final finalResult = builder.build();
    if (finalResult is Err<Court>) {
      return finalResult;
    }
    return _courts.create((finalResult as Ok<Court>).value);
  }
}
