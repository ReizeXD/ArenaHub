import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/failure.dart';
import '../../../../core/result.dart';
import '../../domain/services/court_image_storage.dart';

/// Traduz o código de erro do Firebase Storage para o vocabulário de falhas do domínio.
Failure failureForFirebaseStorage(String code) => switch (code) {
      'unauthorized' || 'permission-denied' => const ImageUploadFailure(
          'Sem permissão para enviar a imagem. As regras de segurança foram publicadas?',
        ),
      'canceled' => const ImageUploadFailure('Envio da imagem cancelado.'),
      'quota-exceeded' => const ImageUploadFailure(
          'Limite de armazenamento do Firebase excedido.',
        ),
      'retry-limit-exceeded' || 'network-request-failed' => const NetworkFailure(
          'Falha de rede ao enviar a imagem. Verifique sua conexão.',
        ),
      _ => const ImageUploadFailure(),
    };

/// Implementação de [CourtImageStorage] que faz upload das fotos para o Firebase Storage.
class FirebaseCourtImageStorage implements CourtImageStorage {
  FirebaseCourtImageStorage({
    this.storage,
    int Function()? nowMillis,
  }) : _nowMillis = nowMillis ?? (() => DateTime.now().millisecondsSinceEpoch);

  final FirebaseStorage? storage;
  final int Function() _nowMillis;

  FirebaseStorage get _instance => storage ?? FirebaseStorage.instance;

  static String extensionForMimeType(String mimeType) =>
      switch (mimeType.toLowerCase()) {
        'image/png' => '.png',
        'image/webp' => '.webp',
        'image/gif' => '.gif',
        _ => '.jpg',
      };

  @override
  Future<Result<String>> upload({
    required String ownerId,
    required String courtId,
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final ext = extensionForMimeType(mimeType);
      final fileName = '${courtId}_${_nowMillis()}$ext';
      final path = 'courts/$ownerId/$fileName';

      final ref = _instance.ref().child(path);
      final metadata = SettableMetadata(contentType: mimeType);

      final uploadTask = await ref.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return Ok(downloadUrl);
    } on FirebaseException catch (error) {
      return Err(failureForFirebaseStorage(error.code));
    } catch (_) {
      return const Err(ImageUploadFailure());
    }
  }
}
