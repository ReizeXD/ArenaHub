import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/booking.dart';

/// Traduz [Booking] de/para o documento do Firestore.
class BookingMapper {
  const BookingMapper();

  Map<String, Object?> toMap(Booking booking) => <String, Object?>{
        'court_id': booking.courtId,
        'user_id': booking.userId,
        'court_day': Booking.courtDayKey(
          courtId: booking.courtId,
          day: booking.start,
        ),
        'day': Booking.dayKey(booking.start),
        'start_at': Timestamp.fromDate(booking.start),
        'duration_minutes': booking.duration.inMinutes,
      };

  Booking fromMap(String id, Map<String, Object?> data) => Booking(
        id: id,
        courtId: (data['court_id'] as String?) ?? '',
        userId: (data['user_id'] as String?) ?? '',
        start: (data['start_at'] as Timestamp).toDate(),
        duration: Duration(
          minutes: (data['duration_minutes'] as num?)?.toInt() ?? 60,
        ),
      );
}
