import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/courts/domain/builders/court_builder.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CourtBuilder (Builder Pattern)', () {
    test('constrói uma quadra passo a passo com valores padrão e limpeza de espaços',
        () {
      final result = CourtBuilder()
          .setId('court-1')
          .setOwnerId('owner-1')
          .setName('  Arena Pajuçara  ')
          .setSport(Sport.beachTennis)
          .setAddress('  Av. Sílvio Carlos Viana, 100  ')
          .setPricePerHourInCents(12000)
          .build();

      expect(result, isA<Ok<Court>>());
      final court = (result as Ok<Court>).value;
      expect(court.id, 'court-1');
      expect(court.ownerId, 'owner-1');
      expect(court.name, 'Arena Pajuçara');
      expect(court.sport, Sport.beachTennis);
      expect(court.address, 'Av. Sílvio Carlos Viana, 100');
      expect(court.pricePerHourInCents, 12000);
      expect(court.imageUrl, '');
      expect(court.openingHour, 8);
      expect(court.closingHour, 22);
    });

    test('permite adicionar foto e horário em etapas posteriores', () {
      final builder = CourtBuilder()
          .setId('court-2')
          .setOwnerId('owner-1')
          .setName('Quadra Central')
          .setSport(Sport.volleyball)
          .setAddress('Rua das Palmeiras, 50')
          .setPricePerHourInCents(9000);

      // Etapa posterior (ex.: após upload da imagem).
      builder.setImageUrl('https://cdn.arenahub.com/quadra2.jpg');
      builder.setOperatingHours(6, 23);

      final result = builder.build();
      expect(result, isA<Ok<Court>>());
      final court = (result as Ok<Court>).value;
      expect(court.imageUrl, 'https://cdn.arenahub.com/quadra2.jpg');
      expect(court.openingHour, 6);
      expect(court.closingHour, 23);
    });

    test('fromExisting preserva campos originais e atualiza apenas os alterados',
        () {
      const existing = Court(
        id: 'court-3',
        ownerId: 'owner-9',
        name: 'Arena Antiga',
        sport: Sport.society,
        address: 'Rua A, 10',
        pricePerHourInCents: 10000,
        imageUrl: 'https://cdn.arenahub.com/antiga.jpg',
        openingHour: 7,
        closingHour: 21,
      );

      final result = CourtBuilder.fromExisting(existing)
          .setName('Arena Renovada')
          .setPricePerHourInCents(15000)
          .build();

      expect(result, isA<Ok<Court>>());
      final updated = (result as Ok<Court>).value;
      expect(updated.id, 'court-3');
      expect(updated.ownerId, 'owner-9');
      expect(updated.imageUrl, 'https://cdn.arenahub.com/antiga.jpg');
      expect(updated.openingHour, 7);
      expect(updated.closingHour, 21);
      expect(updated.name, 'Arena Renovada');
      expect(updated.pricePerHourInCents, 15000);
    });

    test('valida regras de negócio no build() e retorna falhas tipadas', () {
      final emptyName = CourtBuilder()
          .setId('c1')
          .setName('   ')
          .setAddress('Rua B, 20')
          .setPricePerHourInCents(5000)
          .build();
      expect(emptyName, isA<Err<Court>>());
      expect((emptyName as Err<Court>).failure, isA<InvalidCourtNameFailure>());

      final emptyAddress = CourtBuilder()
          .setId('c2')
          .setName('Arena Sol')
          .setAddress('  ')
          .setPricePerHourInCents(5000)
          .build();
      expect(emptyAddress, isA<Err<Court>>());
      expect(
        (emptyAddress as Err<Court>).failure,
        isA<InvalidCourtAddressFailure>(),
      );

      final invalidPrice = CourtBuilder()
          .setId('c3')
          .setName('Arena Sol')
          .setAddress('Rua B, 20')
          .setPricePerHourInCents(0)
          .build();
      expect(invalidPrice, isA<Err<Court>>());
      expect(
        (invalidPrice as Err<Court>).failure,
        isA<InvalidCourtPriceFailure>(),
      );

      final invalidHours = CourtBuilder()
          .setId('c4')
          .setName('Arena Sol')
          .setAddress('Rua B, 20')
          .setPricePerHourInCents(5000)
          .setOperatingHours(20, 18)
          .build();
      expect(invalidHours, isA<Err<Court>>());
      expect(
        (invalidHours as Err<Court>).failure,
        isA<InvalidOperatingHoursFailure>(),
      );
    });
  });
}
