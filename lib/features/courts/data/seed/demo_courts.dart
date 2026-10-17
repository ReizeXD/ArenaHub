import '../../domain/entities/court.dart';
import '../../domain/entities/sport.dart';

/// Catálogo inicial de quadras.
const List<Court> demoCourts = <Court>[
  Court(
    id: 'jatiuca',
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/41/Football_match_at_night_from_sideline.jpg/960px-Football_match_at_night_from_sideline.jpg',
    name: 'Arena Jatiúca',
    sport: Sport.society,
    address: 'Av. Álvaro Otacílio, 3000 — Jatiúca',
    pricePerHourInCents: 12000,
  ),
  Court(
    id: 'pajucara',
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a2/Halle%2C_Inneres%2C_Sportstrasse%2C_2026_R%C3%A1calm%C3%A1s.jpg/960px-Halle%2C_Inneres%2C_Sportstrasse%2C_2026_R%C3%A1calm%C3%A1s.jpg',
    name: 'Quadra Pajuçara',
    sport: Sport.futsal,
    address: 'R. Jangadeiros Alagoanos, 820 — Pajuçara',
    pricePerHourInCents: 9000,
  ),
  Court(
    id: 'ponta-verde',
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/74/Miami_Beach_-_Tennis_Courts_01.jpg/960px-Miami_Beach_-_Tennis_Courts_01.jpg',
    name: 'Beach Club Ponta Verde',
    sport: Sport.beachTennis,
    address: 'Av. Dr. Antônio Gouveia, 145 — Ponta Verde',
    pricePerHourInCents: 8000,
    openingHour: 6,
    closingHour: 20,
  ),
  Court(
    id: 'farol',
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/29/Hamersley_indoor_basketball_court_1.jpg/960px-Hamersley_indoor_basketball_court_1.jpg',
    name: 'Ginásio Farol',
    sport: Sport.basketball,
    address: 'Av. Fernandes Lima, 1200 — Farol',
    pricePerHourInCents: 7000,
  ),
  Court(
    id: 'benedito-bentes',
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/ef/Bondues_beach_volley_aerodrome.jpg/960px-Bondues_beach_volley_aerodrome.jpg',
    name: 'Arena Benedito Bentes',
    sport: Sport.volleyball,
    address: 'Conj. Benedito Bentes I — Benedito Bentes',
    pricePerHourInCents: 6000,
  ),
  Court(
    id: 'cruz-das-almas',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/0/0f/Football_Under_Floodlights_-_geograph.org.uk_-_619765.jpg',
    name: 'Society Cruz das Almas',
    sport: Sport.society,
    address: 'R. Epaminondas Gracindo, 410 — Cruz das Almas',
    pricePerHourInCents: 11000,
    closingHour: 23,
  ),
];
