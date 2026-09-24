import '../../domain/entities/court.dart';
import '../../domain/entities/sport.dart';

/// Catálogo inicial de quadras.
///
/// Vive na camada de dados porque é dado semeado, não regra: quando as
/// quadras passarem a vir do Firestore, este arquivo vira a carga inicial da
/// coleção e some daqui — sem que nada do domínio mude.
const List<Court> demoCourts = <Court>[
  Court(
    id: 'jatiuca',
    name: 'Arena Jatiúca',
    sport: Sport.society,
    address: 'Av. Álvaro Otacílio, 3000 — Jatiúca',
    pricePerHourInCents: 12000,
  ),
  Court(
    id: 'pajucara',
    name: 'Quadra Pajuçara',
    sport: Sport.futsal,
    address: 'R. Jangadeiros Alagoanos, 820 — Pajuçara',
    pricePerHourInCents: 9000,
  ),
  Court(
    id: 'ponta-verde',
    name: 'Beach Club Ponta Verde',
    sport: Sport.beachTennis,
    address: 'Av. Dr. Antônio Gouveia, 145 — Ponta Verde',
    pricePerHourInCents: 8000,
    openingHour: 6,
    closingHour: 20,
  ),
  Court(
    id: 'farol',
    name: 'Ginásio Farol',
    sport: Sport.basketball,
    address: 'Av. Fernandes Lima, 1200 — Farol',
    pricePerHourInCents: 7000,
  ),
  Court(
    id: 'benedito-bentes',
    name: 'Arena Benedito Bentes',
    sport: Sport.volleyball,
    address: 'Conj. Benedito Bentes I — Benedito Bentes',
    pricePerHourInCents: 6000,
  ),
  Court(
    id: 'cruz-das-almas',
    name: 'Society Cruz das Almas',
    sport: Sport.society,
    address: 'R. Epaminondas Gracindo, 410 — Cruz das Almas',
    pricePerHourInCents: 11000,
    closingHour: 23,
  ),
];
