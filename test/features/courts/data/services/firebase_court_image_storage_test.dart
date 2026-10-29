import 'package:arenahub/core/failure.dart';
import 'package:arenahub/features/courts/data/services/firebase_court_image_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('failureForFirebaseStorage', () {
    test('permissão negada vira ImageUploadFailure mencionando regras', () {
      final f1 = failureForFirebaseStorage('unauthorized');
      expect(f1, isA<ImageUploadFailure>());
      expect(f1.message, contains('regras'));

      final f2 = failureForFirebaseStorage('permission-denied');
      expect(f2, isA<ImageUploadFailure>());
      expect(f2.message, contains('regras'));
    });

    test('cancelamento vira ImageUploadFailure indicando cancelado', () {
      final f = failureForFirebaseStorage('canceled');
      expect(f, isA<ImageUploadFailure>());
      expect(f.message, contains('cancelado'));
    });

    test('cota excedida vira ImageUploadFailure informando limite', () {
      final f = failureForFirebaseStorage('quota-exceeded');
      expect(f, isA<ImageUploadFailure>());
      expect(f.message, contains('excedido'));
    });

    test('erros de conexão viram NetworkFailure', () {
      final f1 = failureForFirebaseStorage('network-request-failed');
      expect(f1, isA<NetworkFailure>());

      final f2 = failureForFirebaseStorage('retry-limit-exceeded');
      expect(f2, isA<NetworkFailure>());
    });

    test('código desconhecido não estoura exceção e retorna falha padrão', () {
      final f = failureForFirebaseStorage('qualquer-outro');
      expect(f, isA<ImageUploadFailure>());
    });
  });

  group('FirebaseCourtImageStorage utils', () {
    test('extensionForMimeType resolve as extensões corretamente', () {
      expect(FirebaseCourtImageStorage.extensionForMimeType('image/png'), '.png');
      expect(FirebaseCourtImageStorage.extensionForMimeType('image/webp'), '.webp');
      expect(FirebaseCourtImageStorage.extensionForMimeType('image/gif'), '.gif');
      expect(FirebaseCourtImageStorage.extensionForMimeType('image/jpeg'), '.jpg');
      expect(FirebaseCourtImageStorage.extensionForMimeType('IMAGE/PNG'), '.png');
      expect(FirebaseCourtImageStorage.extensionForMimeType('desconhecido'), '.jpg');
    });
  });
}
