import 'dart:typed_data';

import '../../../../core/result.dart';

/// Port de armazenamento de fotos das quadras.
abstract interface class CourtImageStorage {
  Future<Result<String>> upload({
    required String ownerId,
    required String courtId,
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  });
}