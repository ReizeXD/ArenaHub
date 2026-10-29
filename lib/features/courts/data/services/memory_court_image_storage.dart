import 'dart:convert';
import 'dart:typed_data';

import '../../../../core/failure.dart';
import '../../../../core/result.dart';
import '../../domain/services/court_image_storage.dart';

/// Implementação em memória de [CourtImageStorage] para testes e modo local.
///
/// Converte os bytes recebidos em Data URL (`data:<mimeType>;base64,<encoded>`),
/// permitindo renderização imediata no app sem depender de nuvem ou conexão de rede.
class MemoryCourtImageStorage implements CourtImageStorage {
  MemoryCourtImageStorage({this.failureToSimulate});

  /// Permite simular falhas em cenários de teste automatizado.
  Failure? failureToSimulate;

  final Map<String, Uint8List> _storage = <String, Uint8List>{};

  /// Retorna os bytes armazenados para uma determinada quadra, se existirem.
  Uint8List? bytesFor(String courtId) => _storage[courtId];

  /// Quantidade de imagens atualmente armazenadas.
  int get storedCount => _storage.length;

  /// Limpa as imagens armazenadas em memória.
  void clear() => _storage.clear();

  @override
  Future<Result<String>> upload({
    required String ownerId,
    required String courtId,
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  }) async {
    if (failureToSimulate != null) {
      return Err(failureToSimulate!);
    }

    _storage[courtId] = bytes;
    final base64String = base64Encode(bytes);
    final dataUrl = 'data:$mimeType;base64,$base64String';

    return Ok(dataUrl);
  }
}
