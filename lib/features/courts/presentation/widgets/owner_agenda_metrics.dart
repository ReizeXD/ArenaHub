import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';

/// Cards com estatísticas e métricas do dia para o proprietário da quadra.
///
/// Exibe a contagem de horários agendados e a estimativa de faturamento diário.
class OwnerAgendaMetricsCards extends StatelessWidget {
  const OwnerAgendaMetricsCards({
    super.key,
    required this.bookedCount,
    required this.totalSlots,
    required this.formattedRevenue,
  });

  /// Total de slots reservados no dia.
  final int bookedCount;

  /// Total de slots operacionais no dia.
  final int totalSlots;

  /// Faturamento previsto formatado em R$.
  final String formattedRevenue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Card 1: Horários Agendados
        Expanded(
          child: _MetricCard(
            key: const Key('metric_booked_slots'),
            icon: Icons.event_available_rounded,
            iconColor: AppColors.primary,
            iconBackground: AppColors.primaryContainer.withValues(alpha: 0.6),
            value: '$bookedCount / $totalSlots',
            label: 'Horários agendados',
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // Card 2: Faturamento Estimado
        Expanded(
          child: _MetricCard(
            key: const Key('metric_revenue'),
            icon: Icons.payments_outlined,
            iconColor: const Color(0xFF059669),
            iconBackground: const Color(0xFFD1FAE5),
            value: formattedRevenue,
            valueColor: AppColors.primary,
            label: 'Faturamento estimado',
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
    this.valueColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String value;
  final Color? valueColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Text(
            value,
            style: AppText.headlineMd.copyWith(
              color: valueColor ?? AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
