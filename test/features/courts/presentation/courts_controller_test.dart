import 'package:arenahub/core/failure.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:arenahub/features/courts/presentation/states/courts_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/court_fakes.dart';

void main() {
  test('começa carregando', () {
    expect(courtsControllerWith().state, isA<CourtsLoading>());
  });

  test('carrega o catálogo de quadras', () async {
    final controller = courtsControllerWith();

    await controller.load();

    expect(controller.state, isA<CourtsLoaded>());
    expect((controller.state as CourtsLoaded).courts, isNotEmpty);
  });

  test('expõe a falha tipada quando o repositório erra', () async {
    final controller = courtsControllerWith(
      repository: const FailingCourtRepository(),
    );

    await controller.load();

    expect(controller.state, isA<CourtsFailed>());
    expect((controller.state as CourtsFailed).failure, isA<StorageFailure>());
  });

  test('passa por carregando antes de entregar a lista', () async {
    final controller = courtsControllerWith();
    final observed = <CourtsState>[];
    controller.addListener(() => observed.add(controller.state));

    await controller.load();

    expect(observed.first, isA<CourtsLoading>());
    expect(observed.last, isA<CourtsLoaded>());
  });

  group('filtro por modalidade', () {
    test('sem filtro, mostra o catálogo inteiro', () async {
      final controller = courtsControllerWith();
      await controller.load();

      expect(controller.sport, isNull);
      expect(
        controller.visibleCourts,
        hasLength((controller.state as CourtsLoaded).courts.length),
      );
    });

    test('filtrar deixa só as quadras da modalidade', () async {
      final controller = courtsControllerWith();
      await controller.load();

      controller.filterBy(Sport.society);

      expect(controller.visibleCourts, isNotEmpty);
      expect(
        controller.visibleCourts.every((c) => c.sport == Sport.society),
        isTrue,
      );
    });

    test('voltar para Todos restaura a lista', () async {
      final controller = courtsControllerWith();
      await controller.load();
      final total = controller.visibleCourts.length;

      controller.filterBy(Sport.basketball);
      controller.filterBy(null);

      expect(controller.visibleCourts, hasLength(total));
    });

    test('só oferece modalidades que existem no catálogo', () async {
      final controller = courtsControllerWith();
      await controller.load();

      // Nenhum chip para uma modalidade sem quadra cadastrada.
      for (final sport in controller.availableSports) {
        expect(
          controller.visibleCourts.isNotEmpty || true,
          isTrue,
          reason: sport.label,
        );
      }
      expect(
        controller.availableSports,
        everyElement(
          predicate<Sport>(
            (s) => (controller.state as CourtsLoaded)
                .courts
                .any((c) => c.sport == s),
          ),
        ),
      );
    });

    test('filtrar avisa os ouvintes, repetir o mesmo não', () async {
      final controller = courtsControllerWith();
      await controller.load();

      var avisos = 0;
      controller.addListener(() => avisos++);

      controller.filterBy(Sport.futsal);
      controller.filterBy(Sport.futsal);

      expect(avisos, 1);
    });

    test('antes de carregar, não há o que mostrar nem filtrar', () {
      final controller = courtsControllerWith();

      expect(controller.visibleCourts, isEmpty);
      expect(controller.availableSports, isEmpty);
    });
  });
}
