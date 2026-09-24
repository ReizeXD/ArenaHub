import 'package:arenahub/core/failure.dart';
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
}
