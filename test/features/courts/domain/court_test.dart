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

  group('Booking.startsAt', () {
    final reserva = Booking(
      id: 'r',
      courtId: 'q',
      userId: 'u',
      start: DateTime(2026, 9, 28, 19),
    );

    test('reconhece o mesmo horário', () {
      expect(reserva.startsAt(DateTime(2026, 9, 28, 19)), isTrue);
      // Minutos não importam: a granularidade do sistema é de uma hora.
      expect(reserva.startsAt(DateTime(2026, 9, 28, 19, 45)), isTrue);
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
