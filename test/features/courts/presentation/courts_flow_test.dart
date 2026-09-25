import 'package:arenahub/features/courts/presentation/pages/court_detail_page.dart';
import 'package:arenahub/features/courts/presentation/pages/courts_page.dart';
import 'package:arenahub/features/courts/presentation/pages/home_shell.dart';
import 'package:arenahub/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/court_fakes.dart';
import '../../../support/fakes.dart';

/// Percorre o caminho que será mostrado na apresentação: entrar, escolher uma
/// quadra, escolher um horário e reservar.
void main() {
  final agora = DateTime(2026, 9, 28, 9, 30);

  Future<void> pumpLogado(WidgetTester tester) async {
    final auth = controllerWith();
    await auth.restoreSession();
    await auth.signIn(email: 'jogador@arenahub.com', password: 'arena2026');

    // Um repositório só para reservar e para listar: é assim no app real, e
    // sem isso a aba Reservas não enxergaria o que a outra acabou de gravar.
    final bookings = FakeBookingRepository();

    await tester.pumpWidget(
      ArenaHubApp(
        authController: auth,
        courtsController: courtsControllerWith(),
        bookingController: bookingControllerWith(
          bookings: bookings,
          now: () => agora,
        ),
        myBookingsController: myBookingsControllerWith(
          bookings: bookings,
          now: () => agora,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reservarPajucaraAmanha(WidgetTester tester) async {
    await tester.tap(find.text('Quadra Pajuçara'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('29'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reservar'));
    await tester.pumpAndSettle();
  }

  testWidgets('lista as quadras depois do login', (tester) async {
    await pumpLogado(tester);

    expect(find.byType(CourtsPage), findsOneWidget);
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.text('Arena Jatiúca'), findsOneWidget);
    expect(find.text('Quadra Pajuçara'), findsOneWidget);
    expect(find.text(r'R$ 120,00'), findsOneWidget);
  });

  testWidgets('abre o detalhe da quadra escolhida', (tester) async {
    await pumpLogado(tester);

    await tester.tap(find.text('Quadra Pajuçara'));
    await tester.pumpAndSettle();

    expect(find.byType(CourtDetailPage), findsOneWidget);
    expect(find.text('Escolha o dia'), findsOneWidget);
    expect(find.text('Horários'), findsOneWidget);
    expect(find.text('R. Jangadeiros Alagoanos, 820 — Pajuçara'), findsOneWidget);
  });

  testWidgets('reserva um horário e confirma na tela', (tester) async {
    await pumpLogado(tester);

    await tester.tap(find.text('Quadra Pajuçara'));
    await tester.pumpAndSettle();

    // Amanhã, para que nenhum horário esteja no passado.
    await tester.tap(find.text('29'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('10:00'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar reserva'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Reservar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Reserva confirmada'), findsOneWidget);
  });

  testWidgets('horário reservado deixa de ser oferecido', (tester) async {
    await pumpLogado(tester);

    await tester.tap(find.text('Quadra Pajuçara'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('29'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('10:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reservar'));
    await tester.pumpAndSettle();

    // Tocar de novo no mesmo horário não deve abrir o diálogo: ele saiu de
    // circulação assim que a agenda recarregou.
    await tester.tap(find.text('10:00'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar reserva'), findsNothing);
  });

  testWidgets('aba de reservas começa vazia', (tester) async {
    await pumpLogado(tester);

    await tester.tap(find.text('Reservas'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ainda não reservou'), findsOneWidget);
  });

  testWidgets('a reserva feita aparece na aba Reservas', (tester) async {
    await pumpLogado(tester);
    await reservarPajucaraAmanha(tester);

    // Volta do detalhe para a moldura e troca de aba.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reservas'));
    await tester.pumpAndSettle();

    expect(find.text('Próximas'), findsOneWidget);
    expect(find.text('Quadra Pajuçara'), findsOneWidget);
    expect(find.text('29/09 · 10:00 às 11:00'), findsOneWidget);
  });

  testWidgets('sair volta para o login', (tester) async {
    await pumpLogado(tester);

    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsNothing);
    expect(find.text('Entrar'), findsWidgets);
  });
}
