import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/courts/domain/entities/booking.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Court.formattedPrice', () {
    Court withCents(int cents) => Court(
          id: 'x',
          name: 'x',
          sport: Sport.futsal,
          address: 'x',
          pricePerHourInCents: cents,
        );

    test('formata reais e centavos', () {
      expect(withCents(12000).formattedPrice, r'R$ 120,00');
      expect(withCents(9050).formattedPrice, r'R$ 90,50');
    });

    test('preenche o centavo com zero à esquerda', () {
      // O bug clássico: 90,5 em vez de 90,05.
      expect(withCents(9005).formattedPrice, r'R$ 90,05');
    });

    test('lida com valor zerado', () {
      expect(withCents(0).formattedPrice, r'R$ 0,00');
    });
  });

  group('Court.isOwnedBy', () {
    const court = Court(
      id: 'c1',
      ownerId: 'dono-1',
      name: 'Arena',
      sport: Sport.society,
      address: 'Rua 1',
      pricePerHourInCents: 10000,
    );

    test('retorna true apenas para o dono legítimo', () {
      expect(court.isOwnedBy('dono-1'), isTrue);
      expect(court.isOwnedBy('outro-usuario'), isFalse);
      expect(court.isOwnedBy(''), isFalse);
    });

    test('retorna false quando a quadra não tem dono associado', () {
      const courtSemDono = Court(
        id: 'c2',
        name: 'Arena Demo',
        sport: Sport.futsal,
        address: 'Rua 2',
        pricePerHourInCents: 10000,
      );
      expect(courtSemDono.isOwnedBy('dono-1'), isFalse);
      expect(courtSemDono.isOwnedBy(''), isFalse);
    });
  });

  group('Court.validated', () {
    test('cria quadra válida com dados corretos', () {
      final result = Court.validated(
        id: 'c1',
        ownerId: 'dono-1',
        name: ' Arena Nova ',
        sport: Sport.society,
        address: ' Av Principal, 100 ',
        pricePerHourInCents: 12000,
        imageUrl: ' https://img.com/foto.jpg ',
        openingHour: 8,
        closingHour: 22,
      );

      expect(result, isA<Ok<Court>>());
      final court = (result as Ok<Court>).value;
      expect(court.name, 'Arena Nova');
      expect(court.address, 'Av Principal, 100');
      expect(court.imageUrl, 'https://img.com/foto.jpg');
    });

    test('recusa nome vazio', () {
      final result = Court.validated(
        id: 'c1',
        ownerId: 'dono-1',
        name: '   ',
        sport: Sport.society,
        address: 'Rua 1',
        pricePerHourInCents: 10000,
      );
      expect((result as Err<Court>).failure, isA<InvalidCourtNameFailure>());
    });

    test('recusa endereço vazio', () {
      final result = Court.validated(
        id: 'c1',
        ownerId: 'dono-1',
        name: 'Arena',
        sport: Sport.society,
        address: '   ',
        pricePerHourInCents: 10000,
      );
      expect((result as Err<Court>).failure, isA<InvalidCourtAddressFailure>());
    });

    test('recusa preço menor ou igual a zero', () {
      final resultZero = Court.validated(
        id: 'c1',
        ownerId: 'dono-1',
        name: 'Arena',
        sport: Sport.society,
        address: 'Rua 1',
        pricePerHourInCents: 0,
      );
      expect((resultZero as Err<Court>).failure, isA<InvalidCourtPriceFailure>());

      final resultNegativo = Court.validated(
        id: 'c1',
        ownerId: 'dono-1',
        name: 'Arena',
        sport: Sport.society,
        address: 'Rua 1',
        pricePerHourInCents: -500,
      );
      expect((resultNegativo as Err<Court>).failure, isA<InvalidCourtPriceFailure>());
    });

    test('recusa horários de funcionamento inválidos', () {
      final resultInvertido = Court.validated(
        id: 'c1',
        ownerId: 'dono-1',
        name: 'Arena',
        sport: Sport.society,
        address: 'Rua 1',
        pricePerHourInCents: 10000,
        openingHour: 22,
        closingHour: 8,
      );
      expect((resultInvertido as Err<Court>).failure, isA<InvalidOperatingHoursFailure>());

      final resultIgual = Court.validated(
        id: 'c1',
        ownerId: 'dono-1',
        name: 'Arena',
        sport: Sport.society,
        address: 'Rua 1',
        pricePerHourInCents: 10000,
        openingHour: 10,
        closingHour: 10,
      );
      expect((resultIgual as Err<Court>).failure, isA<InvalidOperatingHoursFailure>());

      final resultForaLimite = Court.validated(
        id: 'c1',
        ownerId: 'dono-1',
        name: 'Arena',
        sport: Sport.society,
        address: 'Rua 1',
        pricePerHourInCents: 10000,
        openingHour: -1,
        closingHour: 25,
      );
      expect((resultForaLimite as Err<Court>).failure, isA<InvalidOperatingHoursFailure>());
    });
  });

  group('Court.copyWith', () {
    const original = Court(
      id: 'c1',
      ownerId: 'dono-1',
      name: 'Arena Antiga',
      sport: Sport.futsal,
      address: 'Rua Antiga',
      pricePerHourInCents: 8000,
    );

    test('atualiza apenas campos fornecidos', () {
      final updated = original.copyWith(
        name: 'Arena Nova',
        pricePerHourInCents: 9500,
      );

      expect(updated.id, 'c1');
      expect(updated.ownerId, 'dono-1');
      expect(updated.name, 'Arena Nova');
      expect(updated.pricePerHourInCents, 9500);
      expect(updated.sport, Sport.futsal);
      expect(updated.address, 'Rua Antiga');
    });
  });

  group('Booking.startsAt', () {
    final reserva = Booking(
      id: 'r',
      courtId: 'q',
      userId: 'u',
      userName: 'Carlos Silva',
      start: DateTime(2026, 9, 28, 19),
    );

    test('reconhece o mesmo horário e preserva userName', () {
      expect(reserva.startsAt(DateTime(2026, 9, 28, 19)), isTrue);
      expect(reserva.startsAt(DateTime(2026, 9, 28, 19, 45)), isTrue);
      expect(reserva.userName, 'Carlos Silva');
    });

    test('distingue hora e dia diferentes', () {
      expect(reserva.startsAt(DateTime(2026, 9, 28, 20)), isFalse);
      expect(reserva.startsAt(DateTime(2026, 9, 29, 19)), isFalse);
    });

    test('termina uma hora depois de começar', () {
      expect(reserva.end, DateTime(2026, 9, 28, 20));
    });
  });

  group('Sport', () {
    test('traduz o valor persistido de volta para o enum', () {
      expect(Sport.fromWire('BEACH_TENNIS'), Sport.beachTennis);
      expect(Sport.fromWire('volleyball'), Sport.volleyball);
    });

    test('cai em futsal diante de modalidade desconhecida', () {
      expect(Sport.fromWire('CURLING'), Sport.futsal);
    });
  });
}
