import 'package:arenahub/features/courts/data/mappers/booking_mapper.dart';
import 'package:arenahub/features/courts/data/mappers/court_mapper.dart';
import 'package:arenahub/features/courts/domain/entities/booking.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/court_fakes.dart';

void main() {
  group('CourtMapper', () {
    const mapper = CourtMapper();

    test('ida e volta preserva os dados da quadra', () {
      final restored = mapper.fromMap(testCourt.id, mapper.toMap(testCourt));

      expect(restored.id, testCourt.id);
      expect(restored.name, testCourt.name);
      expect(restored.sport, testCourt.sport);
      expect(restored.pricePerHourInCents, testCourt.pricePerHourInCents);
      expect(restored.openingHour, testCourt.openingHour);
      expect(restored.closingHour, testCourt.closingHour);
    });

    test('documento incompleto não derruba a leitura', () {
      // Documento gravado por uma versão antiga, ou editado à mão no console.
      final court = mapper.fromMap('x', <String, Object?>{'name': 'Só o nome'});

      expect(court.name, 'Só o nome');
      expect(court.sport, Sport.futsal, reason: 'modalidade padrão');
      expect(court.openingHour, 8);
      expect(court.pricePerHourInCents, 0);
    });
  });

  group('BookingMapper', () {
    const mapper = BookingMapper();

    final booking = Booking(
      id: 'pajucara__2026-09-28__19',
      courtId: 'pajucara',
      userId: 'uid-1',
      start: DateTime(2026, 9, 28, 19),
    );

    test('ida e volta preserva a reserva', () {
      final restored = mapper.fromMap(booking.id, mapper.toMap(booking));

      expect(restored.id, booking.id);
      expect(restored.courtId, 'pajucara');
      expect(restored.userId, 'uid-1');
      expect(restored.start, DateTime(2026, 9, 28, 19));
      expect(restored.duration, const Duration(hours: 1));
    });

    test('grava as chaves de consulta', () {
      final map = mapper.toMap(booking);

      // Um campo só com quadra e dia: permite buscar a agenda com um único
      // filtro de igualdade, sem índice composto.
      expect(map['court_day'], 'pajucara|2026-09-28');
      expect(map['day'], '2026-09-28');
      expect(map['start_at'], isA<Timestamp>());
    });

    test('usa user_id, o campo que as regras do Firestore verificam', () {
      // A regra exige request.resource.data.user_id == request.auth.uid.
      // Renomear este campo quebraria a gravação com permission-denied.
      expect(mapper.toMap(booking)['user_id'], 'uid-1');
    });
  });
}
