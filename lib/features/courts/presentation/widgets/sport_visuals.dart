import 'package:flutter/material.dart';

import '../../domain/entities/sport.dart';

/// Ícone e cor de cada modalidade.
///
/// Fica na apresentação de propósito: como a quadra é desenhada não é regra
/// de negócio, e o `Sport` do domínio não deve conhecer `Colors` (SRP).
extension SportVisuals on Sport {
  IconData get icon => switch (this) {
        Sport.futsal || Sport.society => Icons.sports_soccer_rounded,
        Sport.volleyball => Icons.sports_volleyball_rounded,
        Sport.beachTennis => Icons.sports_tennis_rounded,
        Sport.basketball => Icons.sports_basketball_rounded,
      };

  Color get color => switch (this) {
        Sport.futsal => const Color(0xFF10B981),
        Sport.society => const Color(0xFF0EA5E9),
        Sport.volleyball => const Color(0xFFF59E0B),
        Sport.beachTennis => const Color(0xFFEC4899),
        Sport.basketball => const Color(0xFFF97316),
      };
}

/// Capa de uma quadra: gradiente da modalidade com o ícone ao centro.
///
/// Não usa imagem de rede — a tela não quebra sem internet, e o app não
/// depende do Firebase Storage, o único serviço que exigiria cartão.
class CourtCover extends StatelessWidget {
  const CourtCover({
    super.key,
    required this.sport,
    this.width = 88,
    this.height = 88,
    this.borderRadius = 14,
    this.iconSize = 40,
  });

  final Sport sport;

  /// `double.infinity` ocupa a largura disponível (uso como banner).
  final double width;

  /// Sempre finita: altura infinita quebra o layout do `ListView`.
  final double height;

  final double borderRadius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final color = sport.color;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.55)],
        ),
      ),
      child: Icon(sport.icon, size: iconSize, color: Colors.white),
    );
  }
}
