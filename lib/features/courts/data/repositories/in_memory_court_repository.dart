import '../../../../core/failure.dart';
import '../../../../core/result.dart';
import '../../domain/entities/court.dart';
import '../../domain/repositories/court_repository.dart';
import '../seed/demo_courts.dart';

/// [CourtRepository] servindo um catálogo fixo em memória.
///
/// Primeira implementação do port — roda sem rede e sem configuração. Quando
/// o Firestore entrar, ele será a segunda, e nenhuma linha de domínio ou de
/// tela muda por causa disso.
class InMemoryCourtRepository implements CourtRepository {
  const InMemoryCourtRepository([this._courts = demoCourts]);

  final List<Court> _courts;

  @override
  Future<Result<List<Court>>> listAll() async => Ok(List.unmodifiable(_courts));

  @override
  Future<Result<Court>> findById(String id) async {
    for (final court in _courts) {
      if (court.id == id) return Ok(court);
    }
    return const Err(CourtNotFoundFailure());
  }
}
