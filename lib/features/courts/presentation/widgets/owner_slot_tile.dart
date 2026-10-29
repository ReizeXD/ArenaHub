import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/owner_slot_info.dart';

/// Card individual representando um horário na agenda da quadra do proprietário
///
/// Diferencia visualmente horários livres de reservados, destacando nos horários
/// ocupados a identificação do atleta que agendou, faixa horária e status.
class OwnerSlotTile extends StatelessWidget {
  const OwnerSlotTile({
    super.key,
    required this.slot,
    required this.court,
  });

  final OwnerSlotInfo slot;
  final Court court;

  String get _timeRange {
    final start = slot.label;
    final end = '${slot.end.hour.toString().padLeft(2, '0')}:00';
    return '$start às $end';
  }

  @override
  Widget build(BuildContext context) {
    final isBooked = slot.isBooked;

    return Container(
      key: Key('owner_slot_${slot.start.hour}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: isBooked
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.outlineVariant.withValues(alpha: 0.5),
          width: isBooked ? 1.5 : 1,
        ),
        boxShadow: isBooked ? AppShadows.accent : AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: isBooked ? _buildBookedContent() : _buildAvailableContent(),
      ),
    );
  }

  /// Conteúdo para horário livre.
  Widget _buildAvailableContent() {
    return Row(
      children: [
        // Faixa de horário
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs + 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(
            Icons.schedule_rounded,
            size: 18,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_timeRange, style: AppText.labelLg),
            const SizedBox(height: 2),
            Text(
              slot.isPast ? 'Horário encerrado' : 'Horário livre para reserva',
              style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        const Spacer(),

        // Status e Preço
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              key: Key('owner_slot_status_${slot.start.hour}'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: slot.isPast
                    ? AppColors.surfaceLow
                    : const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
              ),
              child: Text(
                slot.isPast ? 'ENCERRADO' : 'DISPONÍVEL',
                style: AppText.labelCaps.copyWith(
                  color: slot.isPast
                      ? AppColors.onSurfaceVariant
                      : const Color(0xFF059669),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              court.formattedPrice,
              style: AppText.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Conteúdo para horário reservado com identificação do atleta.
  Widget _buildBookedContent() {
    final athleteName = slot.booking?.userName.trim();
    final displayName = (athleteName != null && athleteName.isNotEmpty)
        ? athleteName
        : 'Atleta';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha superior: Horário e Status de Reserva
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs + 2),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Text(_timeRange, style: AppText.labelLg),
            const Spacer(),
            Container(
              key: Key('owner_slot_status_${slot.start.hour}'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'RESERVADO',
                    style: AppText.labelCaps.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Divider(
          height: 1,
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        const SizedBox(height: AppSpacing.md),

        // Linha inferior: Identificação do Atleta e Preço
        Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: AppColors.primaryContainer,
              child: const Icon(
                Icons.person_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    key: Key('owner_slot_athlete_${slot.start.hour}'),
                    style: AppText.labelLg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Reserva confirmada',
                    style: AppText.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              court.formattedPrice,
              style: AppText.headlineSm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
