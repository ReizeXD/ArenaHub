import '../../../../core/failure.dart';
import '../../domain/entities/court.dart';

/// Estados da tela de gerenciamento de quadras do dono.
sealed class MyCourtsState {
  const MyCourtsState();
}

final class MyCourtsLoading extends MyCourtsState {
  const MyCourtsLoading();
}

final class MyCourtsLoaded extends MyCourtsState {
  const MyCourtsLoaded(this.courts);

  final List<Court> courts;
}

final class MyCourtsFailed extends MyCourtsState {
  const MyCourtsFailed(this.failure);

  final Failure failure;
}
