import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/sport.dart';

/// Ícone e cores de cada modalidade.
///
/// As cores vêm da seção "Sport Category Color Badges" do design. Ficam na
/// apresentação porque desenho não é regra de negócio: o `Sport` do domínio
/// não conhece `Colors`.
extension SportVisuals on Sport {
  IconData get icon => switch (this) {
        Sport.futsal || Sport.society => Icons.sports_soccer_rounded,
        Sport.volleyball => Icons.sports_volleyball_rounded,
        Sport.beachTennis => Icons.sports_tennis_rounded,
        Sport.basketball => Icons.sports_basketball_rounded,
      };

  Color get color => switch (this) {
        Sport.futsal || Sport.society => const Color(0xFF059669),
        Sport.volleyball || Sport.beachTennis => const Color(0xFFF59E0B),
        Sport.basketball => const Color(0xFFF97316),
      };

  Color get surface => switch (this) {
        Sport.futsal || Sport.society => const Color(0xFFD1FAE5),
        Sport.volleyball || Sport.beachTennis => const Color(0xFFFEF3C7),
        Sport.basketball => const Color(0xFFFFEDD5),
      };
}

/// Foto da quadra, com suporte a URLs remotas (HTTP), Data URLs (base64)
/// e bytes em memória, tendo o gradiente da modalidade como plano B.
class CourtImage extends StatelessWidget {
  const CourtImage({
    super.key,
    required this.court,
    this.height = 180,
    this.borderRadius,
    this.memoryBytes,
  });

  final Court court;
  final double height;
  final BorderRadius? borderRadius;
  final Uint8List? memoryBytes;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.card;

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (memoryBytes != null && memoryBytes!.isNotEmpty) {
      return Image.memory(
        memoryBytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _Gradient(sport: court.sport),
      );
    }

    final url = court.imageUrl.trim();
    if (url.isEmpty) {
      return _Gradient(sport: court.sport);
    }

    if (url.startsWith('data:')) {
      try {
        final commaIndex = url.indexOf(',');
        final base64String =
            commaIndex != -1 ? url.substring(commaIndex + 1) : url;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _Gradient(sport: court.sport),
        );
      } catch (_) {
        return _Gradient(sport: court.sport);
      }
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _Gradient(sport: court.sport),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _Gradient(sport: court.sport),
    );
  }
}

class _Gradient extends StatelessWidget {
  const _Gradient({required this.sport});

  final Sport sport;

  @override
  Widget build(BuildContext context) {
    final color = sport.color;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.5)],
        ),
      ),
      child: Center(
        child: Icon(
          sport.icon,
          size: 44,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

/// Etiqueta de modalidade em pílula.
///
/// Sobre foto usa fundo escuro translúcido com texto branco; fora dela, a cor
/// suave da modalidade.
class SportBadge extends StatelessWidget {
  const SportBadge({super.key, required this.sport, this.onImage = false});

  final Sport sport;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final background = onImage
        ? AppColors.onSurface.withValues(alpha: 0.72)
        : sport.surface;
    final foreground = onImage ? Colors.white : sport.color;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(sport.icon, size: 13, color: foreground),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            sport.label,
            style: AppText.labelMd.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
