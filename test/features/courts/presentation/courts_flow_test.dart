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

  /// Rola até o alvo antes de tocar: com foto, os cartões passaram a ser
  /// altos o bastante para sair da área visível.
  Future<void> tocarEm(WidgetTester tester, Finder alvo) async {
    await tester.ensureVisible(alvo);
    await tester.pumpAndSettle();
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  Future<void> pumpLogado(WidgetTester tester) async {
    // Tamanho de telefone: o layout é desenhado para uma coluna estreita.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    await tocarEm(tester, find.text('Quadra Pajuçara'));
    await tocarEm(tester, find.text('29'));
    await tocarEm(tester, find.text('10:00 – 11:00'));
    await tocarEm(tester, find.widgetWithText(FilledButton, 'Confirmar reserva'));
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

    await tocarEm(tester, find.text('Quadra Pajuçara'));

    expect(find.byType(CourtDetailPage), findsOneWidget);
    expect(find.text('Selecione a data'), findsOneWidget);
    expect(find.text('MANHÃ'), findsOneWidget);
    expect(find.text('R. Jangadeiros Alagoanos, 820 — Pajuçara'), findsOneWidget);
  });

  testWidgets('reserva um horário e confirma na tela', (tester) async {
    await pumpLogado(tester);

    await tocarEm(tester, find.text('Quadra Pajuçara'));

    // Amanhã, para que nenhum horário esteja no passado.
    await tocarEm(tester, find.text('29'));
    await tocarEm(tester, find.text('10:00 – 11:00'));

    // Selecionar mostra a barra fixa; a reserva só acontece ao confirmar.
    expect(find.text('Selecionado para reserva'), findsOneWidget);
    await tocarEm(tester, find.widgetWithText(FilledButton, 'Confirmar reserva'));

    expect(find.textContaining('Reserva confirmada'), findsOneWidget);
  });

  testWidgets('horário reservado deixa de ser oferecido', (tester) async {
    await pumpLogado(tester);

    await tocarEm(tester, find.text('Quadra Pajuçara'));
    await tocarEm(tester, find.text('29'));
    await tocarEm(tester, find.text('10:00 – 11:00'));
    await tocarEm(tester, find.widgetWithText(FilledButton, 'Confirmar reserva'));

    // Tocar de novo no mesmo horário não seleciona nada: ele saiu de
    // circulação assim que a agenda recarregou.
    await tocarEm(tester, find.text('10:00 – 11:00'));

    expect(find.text('Selecionado para reserva'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Confirmar reserva'), findsNothing);
  });

  testWidgets('aba de reservas começa vazia', (tester) async {
    await pumpLogado(tester);

    await tester.tap(find.text('Reservas').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('ainda não reservou'), findsOneWidget);
  });

  testWidgets('a reserva feita aparece na aba Reservas', (tester) async {
    await pumpLogado(tester);
    await reservarPajucaraAmanha(tester);

    // Volta do detalhe para a moldura e troca de aba.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reservas').last);
    await tester.pumpAndSettle();

    expect(find.text('Seu próximo jogo'), findsOneWidget);
    expect(find.text('Quadra Pajuçara'), findsOneWidget);
    expect(find.text('29/09 · 10:00 às 11:00'), findsOneWidget);
  });

  testWidgets('sair volta para o login', (tester) async {
    await pumpLogado(tester);

    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsNothing);
    expect(find.text('Entrar na quadra'), findsWidgets);
  });

  testWidgets('os chips filtram a lista por modalidade', (tester) async {
    await pumpLogado(tester);

    // Sem filtro, a primeira da lista aparece. O Ginásio Farol é o quarto e
    // nem chega a ser construído: o ListView só monta o que está visível.
    expect(find.text('Arena Jatiúca'), findsOneWidget);
    expect(find.text('6 quadras'), findsOneWidget);

    // Futsal é o segundo chip e tem uma quadra só.
    // O chip vem antes do cartão na árvore, então `.first` é o chip.
    await tocarEm(tester, find.text('Futsal').first);

    expect(find.text('1 quadra'), findsOneWidget);
    expect(find.text('Quadra Pajuçara'), findsOneWidget);
    expect(find.text('Arena Jatiúca'), findsNothing);
  });

  testWidgets('a aba Reservas mostra os contadores', (tester) async {
    await pumpLogado(tester);
    await reservarPajucaraAmanha(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tocarEm(tester, find.text('Reservas').last);

    expect(find.text('ATIVAS'), findsOneWidget);
    expect(find.text('CONCLUÍDAS'), findsOneWidget);
    expect(find.text('Próxima partida'), findsOneWidget);
    expect(find.text('Próximas (1)'), findsOneWidget);
    expect(find.text('Anteriores (0)'), findsOneWidget);
  });
}
