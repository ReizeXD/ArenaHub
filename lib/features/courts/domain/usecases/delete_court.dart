import '../../../../core/failure.dart';
import '../../../../core/result.dart';
import '../entities/court.dart';
import '../repositories/court_repository.dart';

/// Caso de uso: excluir uma quadra pertencente ao usuário.
class DeleteCourt {
  const DeleteCourt(this._courts);

  final CourtRepository _courts;

  Future<Result<void>> call({
    required Court court,
    required String userId,
  }) async {
    if (!court.isOwnedBy(userId)) {
      return const Err(UnauthorizedCourtActionFailure());
    }
    return _courts.delete(court.id);
  }
}
