import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';
import '../../domain/entities/court.dart';
import 'sport_visuals.dart';

/// Card de exibição de uma quadra gerenciada pelo dono, com ações rápidas
///
/// Apresenta foto/gradiente, modalidade, nome, endereço, horários de funcionamento,
/// preço por hora e botões para Ver Agenda, Editar e Excluir.
class OwnerCourtCard extends StatelessWidget {
  const OwnerCourtCard({
    super.key,
    required this.court,
    this.onViewAgenda,
    this.onEdit,
    this.onDelete,
  });

  final Court court;
  final VoidCallback? onViewAgenda;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLowest,
      borderRadius: AppRadius.card,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem e Badge de modalidade
            Stack(
              children: [
                CourtImage(
                  court: court,
                  height: 168,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm + 2,
                  left: AppSpacing.sm + 2,
                  child: SportBadge(sport: court.sport, onImage: true),
                ),
              ],
            ),

            // Informações e Ações
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(court.name, style: AppText.headlineSm),
                  const SizedBox(height: AppSpacing.xs + 2),

                  // Endereço e Horários
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 15,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          court.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodySm,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(AppRadius.xxl),
                        ),
                        child: Text(
                          '${court.openingHour}h–${court.closingHour}h',
                          style: AppText.labelCaps,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),

                  // Preço por hora
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        court.formattedPrice,
                        style: AppText.headlineMd.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      Text(' /hora', style: AppText.bodySm),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Divider(
                    height: 1,
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),

                  // Barra de ações rápidas
                  Row(
                    children: [
                      // Ver Agenda
                      Expanded(
                        child: OutlinedButton.icon(
                          key: Key('owner_court_agenda_${court.id}'),
                          icon: const Icon(Icons.calendar_month_rounded, size: 17),
                          label: const Text('Ver Agenda'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs + 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.slot,
                            ),
                          ),
                          onPressed: onViewAgenda,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Editar
                      OutlinedButton.icon(
                        key: Key('owner_court_edit_${court.id}'),
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text('Editar'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 4,
                            vertical: AppSpacing.xs + 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.slot,
                          ),
                        ),
                        onPressed: onEdit,
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Excluir
                      IconButton.outlined(
                        key: Key('owner_court_delete_${court.id}'),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                          color: AppColors.error,
                        ),
                        tooltip: 'Excluir quadra',
                        style: IconButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.slot,
                          ),
                        ),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
