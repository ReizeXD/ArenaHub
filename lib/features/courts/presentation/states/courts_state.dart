import '../../../../core/failure.dart';
import '../../domain/entities/court.dart';

/// Estados da listagem de quadras.
sealed class CourtsState {
  const CourtsState();
}

final class CourtsLoading extends CourtsState {
  const CourtsLoading();
}

final class CourtsLoaded extends CourtsState {
  const CourtsLoaded(this.courts);

  final List<Court> courts;
}

final class CourtsFailed extends CourtsState {
  const CourtsFailed(this.failure);

  final Failure failure;
}
