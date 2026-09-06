/// Papéis de usuário do ArenaHub.
///
/// A tela de login promete dois públicos — "reserve sua quadra" e "gerencie
/// suas arenas". Aqui essa promessa vira modelo, e não só texto.
///
/// `wire` é o valor estável usado na persistência e em um eventual backend,
/// separado de `label` para que renomear o texto exibido nunca invalide um
/// dado já gravado.
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
