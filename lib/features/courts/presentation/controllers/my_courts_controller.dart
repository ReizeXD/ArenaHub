import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/result.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/sport.dart';
import '../../domain/usecases/create_court.dart';
import '../../domain/usecases/delete_court.dart';
import '../../domain/usecases/list_my_courts.dart';
import '../../domain/usecases/update_court.dart';
import '../states/my_courts_state.dart';

/// Gerencia o estado das quadras cadastradas pelo proprietário logado.
class MyCourtsController extends ChangeNotifier {
  MyCourtsController({
    required this.listMyCourts,
    required this.createCourt,
    required this.updateCourt,
    required this.deleteCourt,
    this.onCourtMutated,
  });

  final ListMyCourts listMyCourts;
  final CreateCourt createCourt;
  final UpdateCourt updateCourt;
  final DeleteCourt deleteCourt;

  /// Callback disparado após criação, edição ou exclusão de quadra com sucesso.
  /// Suporta retorno síncrono ou assíncrono (Future), permitindo aguardar a sincronização.
  final FutureOr<void> Function()? onCourtMutated;

  MyCourtsState _state = const MyCourtsLoading();
  MyCourtsState get state => _state;

  String? _currentOwnerId;
  String? get currentOwnerId => _currentOwnerId;

  /// Retorna as quadras carregadas quando o estado for [MyCourtsLoaded], ou lista vazia.
  List<Court> get courts => switch (_state) {
        MyCourtsLoaded(:final courts) => courts,
        _ => const <Court>[],
      };

  /// Carrega as quadras pertencentes ao [ownerId].
  Future<void> load(String ownerId) async {
    _currentOwnerId = ownerId;
    _emit(const MyCourtsLoading());

    final result = await listMyCourts(ownerId);
    _emit(
      result.fold(
        onSuccess: (courts) => MyCourtsLoaded(courts),
        onFailure: (failure) => MyCourtsFailed(failure),
      ),
    );
  }

  /// Cadastra uma nova quadra para o proprietário.
  Future<Result<Court>> create({
    required String ownerId,
    required String name,
    required Sport sport,
    required String address,
    required int pricePerHourInCents,
    String imageUrl = '',
    int openingHour = 8,
    int closingHour = 22,
    Uint8List? imageBytes,
    String imageMimeType = 'image/jpeg',
  }) async {
    final result = await createCourt(
      ownerId: ownerId,
      name: name,
      sport: sport,
      address: address,
      pricePerHourInCents: pricePerHourInCents,
      imageUrl: imageUrl,
      openingHour: openingHour,
      closingHour: closingHour,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
    );

    if (result is Ok<Court>) {
      if (_currentOwnerId != null) {
        await load(_currentOwnerId!);
      }
      await onCourtMutated?.call();
    }

    return result;
  }

  /// Atualiza os dados de uma quadra existente.
  Future<Result<Court>> update({
    required Court existing,
    required String userId,
    required String name,
    required Sport sport,
    required String address,
    required int pricePerHourInCents,
    int openingHour = 8,
    int closingHour = 22,
    String? imageUrl,
    Uint8List? newImageBytes,
    String newImageMimeType = 'image/jpeg',
  }) async {
    final result = await updateCourt(
      existing: existing,
      userId: userId,
      name: name,
      sport: sport,
      address: address,
      pricePerHourInCents: pricePerHourInCents,
      openingHour: openingHour,
      closingHour: closingHour,
      imageUrl: imageUrl,
      newImageBytes: newImageBytes,
      imageMimeType: newImageMimeType,
    );

    if (result is Ok<Court>) {
      if (_currentOwnerId != null) {
        await load(_currentOwnerId!);
      }
      await onCourtMutated?.call();
    }

    return result;
  }

  /// Exclui uma quadra pertencente ao usuário.
  Future<Result<void>> delete({
    required Court court,
    required String userId,
  }) async {
    final result = await deleteCourt(court: court, userId: userId);

    if (result is Ok<void>) {
      if (_currentOwnerId != null) {
        await load(_currentOwnerId!);
      }
      await onCourtMutated?.call();
    }

    return result;
  }

  void _emit(MyCourtsState next) {
    _state = next;
    notifyListeners();
  }
}
