import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/owner_slot_info.dart';
import '../controllers/owner_agenda_controller.dart';
import '../states/owner_agenda_state.dart';
import '../widgets/owner_agenda_metrics.dart';
import '../widgets/owner_slot_tile.dart';
import '../widgets/sport_visuals.dart';

/// Tela da agenda da quadra na visão do proprietário.
///
/// Integra seletor horizontal de datas, cards com métricas do dia
/// (reservas agendadas e faturamento estimado) e lista detalhada de horários
/// livres e ocupados com identificação dos atletas.
class OwnerCourtAgendaPage extends StatefulWidget {
  const OwnerCourtAgendaPage({
    super.key,
    required this.court,
    required this.ownerId,
    this.controller,
  });

  final Court court;
  final String ownerId;
  final OwnerAgendaController? controller;

  @override
  State<OwnerCourtAgendaPage> createState() => _OwnerCourtAgendaPageState();
}

class _OwnerCourtAgendaPageState extends State<OwnerCourtAgendaPage> {
  static const List<String> _weekdays = [
    'seg',
    'ter',
    'qua',
    'qui',
    'sex',
    'sáb',
    'dom',
  ];

  static const List<String> _months = [
    'JAN',
    'FEV',
    'MAR',
    'ABR',
    'MAI',
    'JUN',
    'JUL',
    'AGO',
    'SET',
    'OUT',
    'NOV',
    'DEZ',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveController().load(
        court: widget.court,
        userId: widget.ownerId,
      );
    });
  }

  OwnerAgendaController _resolveController() {
    if (widget.controller != null) return widget.controller!;
    return context.read<OwnerAgendaController>();
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayLabel(DateTime day, List<DateTime> all) {
    if (all.isNotEmpty && _isSameDay(day, all.first)) return 'Hoje';
    if (all.length > 1 && _isSameDay(day, all[1])) return 'Amanhã';
    return _weekdays[day.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final controllerWidget = widget.controller != null
        ? ListenableBuilder(
            listenable: widget.controller!,
            builder: (ctx, _) => _buildScaffold(ctx, widget.controller!),
          )
        : Builder(
            builder: (ctx) {
              final ctrl = ctx.watch<OwnerAgendaController>();
              return _buildScaffold(ctx, ctrl);
            },
          );

    return controllerWidget;
  }

  Widget _buildScaffold(BuildContext context, OwnerAgendaController controller) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Agenda da Quadra', style: AppText.headlineMd),
            Text(
              widget.court.name,
              style: AppText.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.margin),
            child: SportBadge(sport: widget.court.sport),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: switch (controller.state) {
              OwnerAgendaLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
              OwnerAgendaFailed(:final failure) => _buildError(
                  failure.message,
                  () => controller.reload(),
                ),
              OwnerAgendaLoaded(
                :final court,
                :final selectedDay,
                :final availableDays,
                :final slots,
              ) =>
                _buildContent(
                  controller: controller,
                  court: court,
                  selectedDay: selectedDay,
                  availableDays: availableDays,
                  slots: slots,
                ),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              key: const Key('agenda_retry_button'),
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({
    required OwnerAgendaController controller,
    required Court court,
    required DateTime selectedDay,
    required List<DateTime> availableDays,
    required List<OwnerSlotInfo> slots,
  }) {
    return RefreshIndicator(
      onRefresh: controller.reload,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.margin,
          AppSpacing.sm,
          AppSpacing.margin,
          AppSpacing.bottomSafeArea,
        ),
        children: [
          // Resumo da Quadra
          _buildCourtSummaryCard(court),
          const SizedBox(height: AppSpacing.md),

          // Seletor Horizontal de Datas
          Text('Selecione a data', style: AppText.headlineMd),
          const SizedBox(height: AppSpacing.sm + 2),
          _buildDateStrip(controller, selectedDay, availableDays),
          const SizedBox(height: AppSpacing.lg),

          // Cards de Estatísticas e Métricas
          OwnerAgendaMetricsCards(
            bookedCount: controller.bookedCount,
            totalSlots: controller.totalSlots,
            formattedRevenue: controller.formattedRevenue,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Cabeçalho da Grade de Horários
          Row(
            children: [
              Expanded(
                child: Text('Grade de Horários', style: AppText.headlineMd),
              ),
              Text(
                slots.length == 1 ? '1 horário' : '${slots.length} horários',
                style: AppText.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 4),

          // Lista de Slots
          if (slots.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                'Nenhum horário disponível para esta data.',
                textAlign: TextAlign.center,
                style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
            )
          else
            for (final slot in slots) ...[
              OwnerSlotTile(slot: slot, court: court),
            ],
        ],
      ),
    );
  }

  Widget _buildCourtSummaryCard(Court court) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.place_outlined,
            size: 17,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Expanded(
            child: Text(
              court.address,
              style: AppText.bodySm,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
            ),
            child: Text(
              '${court.openingHour}h–${court.closingHour}h',
              style: AppText.labelCaps,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStrip(
    OwnerAgendaController controller,
    DateTime selected,
    List<DateTime> days,
  ) {
    return SizedBox(
      key: const Key('owner_agenda_date_strip'),
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, index) {
          final day = days[index];
          final isSelected = _isSameDay(day, selected);

          return GestureDetector(
            key: Key('agenda_day_${day.day}'),
            onTap: () => controller.selectDay(day),
            child: Container(
              width: 72,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceLowest,
                borderRadius: AppRadius.slot,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.outlineVariant.withValues(alpha: 0.6),
                ),
                boxShadow: isSelected ? AppShadows.accent : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayLabel(day, days),
                    style: AppText.labelMd.copyWith(
                      color: isSelected
                          ? Colors.white70
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    day.day.toString().padLeft(2, '0'),
                    style: AppText.headlineMd.copyWith(
                      color: isSelected ? Colors.white : AppColors.onSurface,
                    ),
                  ),
                  Text(
                    _months[day.month - 1],
                    style: AppText.labelCaps.copyWith(
                      color: isSelected
                          ? Colors.white70
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
