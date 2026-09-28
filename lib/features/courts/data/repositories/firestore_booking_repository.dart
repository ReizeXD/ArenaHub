import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/failure.dart';
import '../../../../core/result.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../mappers/booking_mapper.dart';
import 'firestore_failures.dart';

/// Lançada dentro da transação para abortá-la quando o horário já existe.
class _SlotAlreadyTaken implements Exception {
  const _SlotAlreadyTaken();
}

/// [BookingRepository] sobre a coleção `bookings` do Firestore.
class FirestoreBookingRepository implements BookingRepository {
  const FirestoreBookingRepository(
    this._firestore, [
    this._mapper = const BookingMapper(),
  ]);

  final FirebaseFirestore _firestore;
  final BookingMapper _mapper;

  static const String collection = 'bookings';

  @override
  Future<Result<List<Booking>>> forCourtOn({
    required String courtId,
    required DateTime day,
  }) async {
    try {
      // Um único filtro de igualdade: o Firestore resolve com o índice
      // automático, sem índice composto criado à mão.
      final snapshot = await _firestore
          .collection(collection)
          .where(
            'court_day',
            isEqualTo: Booking.courtDayKey(courtId: courtId, day: day),
          )
          .get();

      return Ok([
        for (final doc in snapshot.docs) _mapper.fromMap(doc.id, doc.data()),
      ]);
    } on FirebaseException catch (error) {
      return Err(failureForFirestore(error.code));
    }
  }

  @override
  Future<Result<List<Booking>>> ofUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where('user_id', isEqualTo: userId)
          .get();

      // Ordenado no cliente de propósito: um `orderBy` junto do filtro
      // exigiria índice composto, e a lista de um usuário é pequena.
      final bookings = [
        for (final doc in snapshot.docs) _mapper.fromMap(doc.id, doc.data()),
      ]..sort((a, b) => a.start.compareTo(b.start));

      return Ok(bookings);
    } on FirebaseException catch (error) {
      return Err(failureForFirestore(error.code));
    }
  }

  @override
  Future<Result<Booking>> create(Booking booking) async {
    final reference = _firestore.collection(collection).doc(booking.id);

    try {
      await _firestore.runTransaction((transaction) async {
        final existing = await transaction.get(reference);
        if (existing.exists) throw const _SlotAlreadyTaken();

        transaction.set(reference, _mapper.toMap(booking));
      });

      return Ok(booking);
    } on _SlotAlreadyTaken {
      return const Err(SlotUnavailableFailure());
    } on FirebaseException catch (error) {
      return Err(failureForFirestore(error.code));
    }
  }
}
