/// Modalidade de uma quadra.
///
/// `wire` é o valor estável usado na persistência, separado de `label` para
/// que renomear o texto exibido nunca invalide um dado já gravado — mesma
/// regra do `Role`.
enum Sport {
  futsal('FUTSAL', 'Futsal'),
  society('SOCIETY', 'Society'),
  volleyball('VOLLEYBALL', 'Vôlei'),
  beachTennis('BEACH_TENNIS', 'Beach tennis'),
  basketball('BASKETBALL', 'Basquete');

  const Sport(this.wire, this.label);

  final String wire;
  final String label;

  static Sport fromWire(String value) => Sport.values.firstWhere(
        (sport) => sport.wire == value.toUpperCase(),
        orElse: () => Sport.futsal,
      );
}
