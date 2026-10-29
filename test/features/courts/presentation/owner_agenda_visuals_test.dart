import 'package:arenahub/features/courts/domain/entities/booking.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/entities/owner_slot_info.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:arenahub/features/courts/presentation/widgets/owner_agenda_metrics.dart';
import 'package:arenahub/features/courts/presentation/widgets/owner_slot_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testCourt = Court(
    id: 'court-1',
    ownerId: 'owner-1',
    name: 'Arena Central de Futsal',
    sport: Sport.futsal,
    address: 'Rua do Esporte, 100',
    pricePerHourInCents: 12000,
    openingHour: 8,
    closingHour: 22,
  );

  group('OwnerAgendaMetricsCards', () {
    testWidgets('exibe métricas de horários agendados e faturamento formatado',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: OwnerAgendaMetricsCards(
                bookedCount: 4,
                totalSlots: 14,
                formattedRevenue: 'R\$ 480,00',
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('metric_booked_slots')), findsOneWidget);
      expect(find.text('4 / 14'), findsOneWidget);
      expect(find.text('Horários agendados'), findsOneWidget);

      expect(find.byKey(const Key('metric_revenue')), findsOneWidget);
      expect(find.text('R\$ 480,00'), findsOneWidget);
      expect(find.text('Faturamento estimado'), findsOneWidget);
    });
  });

  group('OwnerSlotTile — Horário Disponível', () {
    testWidgets('renderiza slot livre futuro com badge DISPONÍVEL e preço',
        (tester) async {
      final freeSlot = OwnerSlotInfo(
        start: DateTime(2026, 10, 29, 8, 0),
        isPast: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OwnerSlotTile(
              slot: freeSlot,
              court: testCourt,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('owner_slot_8')), findsOneWidget);
      expect(find.text('08:00 às 09:00'), findsOneWidget);
      expect(find.text('DISPONÍVEL'), findsOneWidget);
      expect(find.text('Horário livre para reserva'), findsOneWidget);
      expect(find.text('R\$ 120,00'), findsOneWidget);
      expect(find.text('RESERVADO'), findsNothing);
    });

    testWidgets('renderiza slot livre que já passou com badge ENCERRADO',
        (tester) async {
      final pastSlot = OwnerSlotInfo(
        start: DateTime(2026, 10, 29, 6, 0),
        isPast: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OwnerSlotTile(
              slot: pastSlot,
              court: testCourt,
            ),
          ),
        ),
      );

      expect(find.text('06:00 às 07:00'), findsOneWidget);
      expect(find.text('ENCERRADO'), findsOneWidget);
      expect(find.text('Horário encerrado'), findsOneWidget);
    });
  });

  group('OwnerSlotTile — Horário Reservado com Identificação do Atleta', () {
    testWidgets('renderiza slot reservado exibindo nome do atleta e status',
        (tester) async {
      final bookedSlot = OwnerSlotInfo(
        start: DateTime(2026, 10, 29, 19, 0),
        isPast: false,
        booking: Booking(
          id: 'booking-1',
          courtId: testCourt.id,
          userId: 'athlete-10',
          userName: 'Gabriel Medina',
          start: DateTime(2026, 10, 29, 19, 0),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OwnerSlotTile(
              slot: bookedSlot,
              court: testCourt,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('owner_slot_19')), findsOneWidget);
      expect(find.text('19:00 às 20:00'), findsOneWidget);
      expect(find.text('RESERVADO'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Identificação do Atleta
      expect(find.text('Gabriel Medina'), findsOneWidget);
      expect(find.byKey(const Key('owner_slot_athlete_19')), findsOneWidget);
      expect(find.text('Reserva confirmada'), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      expect(find.text('R\$ 120,00'), findsOneWidget);
    });

    testWidgets('exibe fallback "Atleta" quando o nome da reserva estiver em branco',
        (tester) async {
      final bookedSlotWithoutName = OwnerSlotInfo(
        start: DateTime(2026, 10, 29, 21, 0),
        isPast: false,
        booking: Booking(
          id: 'booking-2',
          courtId: testCourt.id,
          userId: 'athlete-20',
          userName: '', // nome não informado
          start: DateTime(2026, 10, 29, 21, 0),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OwnerSlotTile(
              slot: bookedSlotWithoutName,
              court: testCourt,
            ),
          ),
        ),
      );

      expect(find.text('Atleta'), findsOneWidget);
      expect(find.text('Reserva confirmada'), findsOneWidget);
    });
  });
}
