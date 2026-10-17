/// Papéis de usuário do ArenaHub.
enum Role {
  admin('ADMIN', 'Administrador do sistema'),
  owner('OWNER', 'Dono de arena'),
  player('PLAYER', 'Jogador');

  const Role(this.wire, this.label);

  final String wire;
  final String label;

  static Role fromWire(String value) => Role.values.firstWhere(
        (role) => role.wire == value.toUpperCase(),
        orElse: () => Role.player,
      );
}
