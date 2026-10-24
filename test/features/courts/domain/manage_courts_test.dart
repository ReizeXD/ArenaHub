import 'dart:typed_data';

import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_court_repository.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:arenahub/features/courts/domain/usecases/create_court.dart';
import 'package:arenahub/features/courts/domain/usecases/delete_court.dart';
import 'package:arenahub/features/courts/domain/usecases/update_court.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/court_fakes.dart';

void main() {
  late InMemoryCourtRepository repository;
  late FakeCourtImageStorage imageStorage;
  late CreateCourt createCourt;
  late UpdateCourt updateCourt;
  late DeleteCourt deleteCourt;

  setUp(() {
    repository = InMemoryCourtRepository(<Court>[]);
    imageStorage = FakeCourtImageStorage(urlToReturn: 'https://cdn.com/foto.jpg');
    createCourt = CreateCourt(repository, imageStorage);
    updateCourt = UpdateCourt(repository, imageStorage);
    deleteCourt = DeleteCourt(repository);
  });

  group('CreateCourt', () {
    test('cria quadra com sucesso sem imagem', () async {
      final result = await createCourt(
        ownerId: 'dono-1',
        name: 'Arena Central',
        sport: Sport.society,
        address: 'Rua do Gol, 10',
        pricePerHourInCents: 12000,
        openingHour: 8,
        closingHour: 23,
      );

      expect(result, isA<Ok<Court>>());
      final court = (result as Ok<Court>).value;
      expect(court.ownerId, 'dono-1');
      expect(court.name, 'Arena Central');
      expect(court.imageUrl, isEmpty);
      expect(imageStorage.uploadCalls, 0);

      final salvo = await repository.findById(court.id);
      expect((salvo as Ok<Court>).value.name, 'Arena Central');
    });

    test('faz upload de imagem quando bytes são informados', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final result = await createCourt(
        ownerId: 'dono-1',
        name: 'Beach Club',
        sport: Sport.beachTennis,
        address: 'Av Mar, 50',
        pricePerHourInCents: 8000,
        imageBytes: bytes,
      );

      expect(result, isA<Ok<Court>>());
      final court = (result as Ok<Court>).value;
      expect(court.imageUrl, 'https://cdn.com/foto.jpg');
      expect(imageStorage.uploadCalls, 1);
    });

    test('não faz upload de imagem se os dados da quadra forem inválidos', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final result = await createCourt(
        ownerId: 'dono-1',
        name: '  ',
        sport: Sport.futsal,
        address: 'Rua 1',
        pricePerHourInCents: 10000,
        imageBytes: bytes,
      );

      expect((result as Err<Court>).failure, isA<InvalidCourtNameFailure>());
      expect(imageStorage.uploadCalls, 0, reason: 'valida a entidade antes do upload');
    });

    test('propaga falha caso o upload da imagem falhe', () async {
      imageStorage.failure = const ImageUploadFailure();
      final bytes = Uint8List.fromList([1, 2, 3]);

      final result = await createCourt(
        ownerId: 'dono-1',
        name: 'Arena Sol',
        sport: Sport.volleyball,
        address: 'Praia',
        pricePerHourInCents: 7000,
        imageBytes: bytes,
      );

      expect((result as Err<Court>).failure, isA<ImageUploadFailure>());
    });
  });

  group('UpdateCourt', () {
    const existingCourt = Court(
      id: 'c1',
      ownerId: 'dono-1',
      name: 'Arena Antiga',
      sport: Sport.futsal,
      address: 'Rua Antiga',
      pricePerHourInCents: 8000,
      imageUrl: 'https://old.url',
      openingHour: 8,
      closingHour: 22,
    );

    setUp(() async {
      await repository.create(existingCourt);
    });

    test('atualiza os dados com sucesso quando chamado pelo dono', () async {
      final result = await updateCourt(
        existing: existingCourt,
        userId: 'dono-1',
        name: 'Arena Reformada',
        sport: Sport.society,
        address: 'Rua Nova, 20',
        pricePerHourInCents: 11000,
        openingHour: 7,
        closingHour: 23,
      );

      expect(result, isA<Ok<Court>>());
      final updated = (result as Ok<Court>).value;
      expect(updated.name, 'Arena Reformada');
      expect(updated.sport, Sport.society);
      expect(updated.pricePerHourInCents, 11000);
      expect(updated.imageUrl, 'https://old.url', reason: 'preserva foto existente');

      final noBanco = await repository.findById('c1');
      expect((noBanco as Ok<Court>).value.name, 'Arena Reformada');
    });

    test('recusa atualização se o usuário não for o dono', () async {
      final result = await updateCourt(
        existing: existingCourt,
        userId: 'invasor-99',
        name: 'Tentativa Hacker',
        sport: Sport.futsal,
        address: 'Rua Qualquer',
        pricePerHourInCents: 5000,
        openingHour: 8,
        closingHour: 22,
      );

      expect((result as Err<Court>).failure, isA<UnauthorizedCourtActionFailure>());
      expect(imageStorage.uploadCalls, 0);
    });

    test('atualiza foto quando nova imagem é fornecida', () async {
      final bytes = Uint8List.fromList([9, 8, 7]);
      final result = await updateCourt(
        existing: existingCourt,
        userId: 'dono-1',
        name: 'Arena Com Foto Nova',
        sport: Sport.futsal,
        address: 'Rua Antiga',
        pricePerHourInCents: 8000,
        openingHour: 8,
        closingHour: 22,
        newImageBytes: bytes,
      );

      expect(result, isA<Ok<Court>>());
      expect((result as Ok<Court>).value.imageUrl, 'https://cdn.com/foto.jpg');
      expect(imageStorage.uploadCalls, 1);
    });

    test('recusa atualização se os novos dados forem inválidos', () async {
      final result = await updateCourt(
        existing: existingCourt,
        userId: 'dono-1',
        name: 'Nome Válido',
        sport: Sport.futsal,
        address: 'Rua',
        pricePerHourInCents: -50,
        openingHour: 8,
        closingHour: 22,
      );

      expect((result as Err<Court>).failure, isA<InvalidCourtPriceFailure>());
    });
  });

  group('DeleteCourt', () {
    const court = Court(
      id: 'c-del',
      ownerId: 'dono-1',
      name: 'Arena Deletar',
      sport: Sport.basketball,
      address: 'Rua 3',
      pricePerHourInCents: 9000,
    );

    setUp(() async {
      await repository.create(court);
    });

    test('exclui com sucesso quando chamado pelo dono', () async {
      final result = await deleteCourt(court: court, userId: 'dono-1');

      expect(result, isA<Ok<void>>());
      final busca = await repository.findById('c-del');
      expect((busca as Err<Court>).failure, isA<CourtNotFoundFailure>());
    });

    test('recusa exclusão quando chamado por outro usuário', () async {
      final result = await deleteCourt(court: court, userId: 'outro-user');

      expect((result as Err<void>).failure, isA<UnauthorizedCourtActionFailure>());
      final busca = await repository.findById('c-del');
      expect(busca, isA<Ok<Court>>());
    });
  });
}
