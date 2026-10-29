import 'dart:convert';
import 'dart:typed_data';

import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/courts/data/services/memory_court_image_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryCourtImageStorage', () {
    late MemoryCourtImageStorage storage;

    setUp(() {
      storage = MemoryCourtImageStorage();
    });

    test('faz upload e devolve uma Data URL formatada com os bytes em base64',
        () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final result = await storage.upload(
        ownerId: 'owner-1',
        courtId: 'court-10',
        bytes: bytes,
        mimeType: 'image/png',
      );

      expect(result, isA<Ok<String>>());
      final url = (result as Ok<String>).value;

      final expectedBase64 = base64Encode(bytes);
      expect(url, 'data:image/png;base64,$expectedBase64');
      expect(storage.bytesFor('court-10'), bytes);
      expect(storage.storedCount, 1);
    });

    test('usa mimeType padrão image/jpeg quando omitido', () async {
      final bytes = Uint8List.fromList([10, 20, 30]);

      final result = await storage.upload(
        ownerId: 'owner-1',
        courtId: 'court-20',
        bytes: bytes,
      );

      expect(result, isA<Ok<String>>());
      final url = (result as Ok<String>).value;
      expect(url, startsWith('data:image/jpeg;base64,'));
    });

    test('retorna falha simulada quando failureToSimulate é configurado',
        () async {
      storage.failureToSimulate = const ImageUploadFailure();

      final result = await storage.upload(
        ownerId: 'owner-1',
        courtId: 'court-30',
        bytes: Uint8List.fromList([7, 8, 9]),
      );

      expect(result, isA<Err<String>>());
      expect((result as Err<String>).failure, isA<ImageUploadFailure>());
      expect(storage.bytesFor('court-30'), isNull);
      expect(storage.storedCount, 0);
    });

    test('sobrescreve os bytes quando o mesmo courtId recebe novo upload',
        () async {
      final primeirosBytes = Uint8List.fromList([1, 1, 1]);
      final novosBytes = Uint8List.fromList([2, 2, 2]);

      await storage.upload(
        ownerId: 'owner-1',
        courtId: 'court-40',
        bytes: primeirosBytes,
      );

      final resultadoNovo = await storage.upload(
        ownerId: 'owner-1',
        courtId: 'court-40',
        bytes: novosBytes,
      );

      expect((resultadoNovo as Ok<String>).value,
          'data:image/jpeg;base64,${base64Encode(novosBytes)}');
      expect(storage.bytesFor('court-40'), novosBytes);
      expect(storage.storedCount, 1);
    });

    test('clear remove todas as imagens da memória', () async {
      await storage.upload(
        ownerId: 'owner-1',
        courtId: 'court-1',
        bytes: Uint8List.fromList([1]),
      );
      await storage.upload(
        ownerId: 'owner-1',
        courtId: 'court-2',
        bytes: Uint8List.fromList([2]),
      );

      expect(storage.storedCount, 2);

      storage.clear();

      expect(storage.storedCount, 0);
      expect(storage.bytesFor('court-1'), isNull);
      expect(storage.bytesFor('court-2'), isNull);
    });
  });
}
