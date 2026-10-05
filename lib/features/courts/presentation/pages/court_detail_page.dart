import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/time_slot.dart';
import '../controllers/booking_controller.dart';
import '../states/agenda_state.dart';
import '../widgets/sport_visuals.dart';

/// Faixas do dia, como o design agrupa os horários.
enum _Period {
  morning('Manhã', Icons.wb_sunny_outlined),
  afternoon('Tarde', Icons.wb_twilight_rounded),
  night('Noite', Icons.nights_stay_outlined);

  const _Period(this.label, this.icon);

  final String label;
  final IconData icon;

  static _Period of(int hour) => switch (hour) {
        < 12 => _Period.morning,
        < 18 => _Period.afternoon,
        _ => _Period.night,
      };
}

/// Detalhe da quadra: dados, agenda do dia escolhido e a reserva.
class CourtDetailPage extends StatefulWidget {
  const CourtDetailPage({super.key, required this.court});

  final Court court;

  @override
  State<CourtDetailPage> createState() => _CourtDetailPageState();
}

class _CourtDetailPageState extends State<CourtDetailPage> {
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

  TimeSlot? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<BookingController>().open(widget.court),
    );
  }

  String _dayLabel(DateTime day, List<DateTime> all) {
    if (day == all.first) return 'Hoje';
    if (all.length > 1 && day == all[1]) return 'Amanhã';
    return _weekdays[day.weekday - 1];
  }

  Future<void> _confirm() async {
    final slot = _selected;
    final controller = context.read<BookingController>();
    final session = context.read<AuthController>().session;
    if (slot == null || session == null) return;

    final failure = await controller.book(slot: slot, userId: session.user.id);
    if (!mounted) return;

    setState(() => _selected = null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: failure == null ? AppColors.primary : AppColors.error,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.slot),
        content: Row(
          children: [
            Icon(
              failure == null
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Text(
                failure?.message ??
                    'Reserva confirmada para ${slot.label}. Bom jogo!',
                style: AppText.labelLg.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingController>();
    final court = widget.court;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes da quadra', style: AppText.headlineSm),
      ),
      bottomNavigationBar: _selected == null
          ? null
          : _ConfirmBar(
              court: court,
              slot: _selected!,
              isBooking: controller.isBooking,
              onConfirm: _confirm,
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.margin,
                AppSpacing.xs,
                AppSpacing.margin,
                AppSpacing.xl,
              ),
              children: [
                _Hero(court: court),
                const SizedBox(height: AppSpacing.lg),
                _DateStrip(
                  days: controller.availableDays,
                  selected: controller.selectedDay,
                  labelOf: _dayLabel,
                  months: _months,
                  onSelect: (day) {
                    setState(() => _selected = null);
                    controller.selectDay(day);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                switch (controller.state) {
                  AgendaLoading() => const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  AgendaFailed(:final failure) => Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      child: Text(failure.message, style: AppText.bodyMd),
                    ),
                  AgendaLoaded(:final slots)
                      when !slots.any((s) => s.isAvailable) =>
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      child: Text(
                        'Nenhum horário livre neste dia. Tente outro.',
                        style: AppText.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  AgendaLoaded(:final slots) => _Agenda(
                      slots: slots,
                      court: court,
                      selected: _selected,
                      onSelect: (slot) => setState(() => _selected = slot),
                    ),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.court});

  final Court court;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CourtImage(court: court, height: 210),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.card,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.onSurface.withValues(alpha: 0.78),
                ],
                stops: const [0.45, 1],
              ),
            ),
          ),
        ),
        Positioned(
          top: AppSpacing.sm + 4,
          left: AppSpacing.sm + 4,
          child: SportBadge(sport: court.sport, onImage: true),
        ),
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                court.name,
                style: AppText.headlineLg.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 15, color: Colors.white70),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      court.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodySm.copyWith(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.days,
    required this.selected,
    required this.labelOf,
    required this.months,
    required this.onSelect,
  });

  final List<DateTime> days;
  final DateTime selected;
  final String Function(DateTime, List<DateTime>) labelOf;
  final List<String> months;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selecione a data', style: AppText.headlineMd),
        const SizedBox(height: AppSpacing.sm + 4),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, index) {
              final day = days[index];
              final isSelected = day == selected;

              return GestureDetector(
                onTap: () => onSelect(day),
                child: Container(
                  width: 72,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceLowest,
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
                        labelOf(day, days),
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
                        months[day.month - 1],
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
        ),
      ],
    );
  }
}

class _Agenda extends StatelessWidget {
  const _Agenda({
    required this.slots,
    required this.court,
    required this.selected,
    required this.onSelect,
  });

  final List<TimeSlot> slots;
  final Court court;
  final TimeSlot? selected;
  final ValueChanged<TimeSlot> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final period in _Period.values)
          if (slots.any((s) => _Period.of(s.start.hour) == period)) ...[
            Row(
              children: [
                Icon(period.icon, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  period.label.toUpperCase(),
                  style: AppText.labelCaps.copyWith(color: AppColors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            for (final slot in slots.where(
              (s) => _Period.of(s.start.hour) == period,
            )) ...[
              _SlotTile(
                slot: slot,
                court: court,
                isSelected: selected?.start == slot.start,
                onTap: () => onSelect(slot),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
            ],
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.court,
    required this.isSelected,
    required this.onTap,
  });

  final TimeSlot slot;
  final Court court;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = slot.isAvailable;
    final end = '${slot.end.hour.toString().padLeft(2, '0')}:00';

    final background = isSelected
        ? AppColors.primary
        : available
            ? AppColors.surfaceLowest
            : AppColors.surfaceLow;

    final titleColor = isSelected
        ? Colors.white
        : available
            ? AppColors.onSurface
            : AppColors.outline;

    return Material(
      color: background,
      borderRadius: AppRadius.slot,
      child: InkWell(
        borderRadius: AppRadius.slot,
        onTap: available ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          decoration: BoxDecoration(
            borderRadius: AppRadius.slot,
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: isSelected ? AppShadows.accent : null,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  isSelected
                      ? Icons.check_circle_outline_rounded
                      : available
                          ? Icons.schedule_rounded
                          : Icons.block_rounded,
                  size: 19,
                  color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${slot.label} – $end',
                      style: AppText.headlineSm.copyWith(
                        color: titleColor,
                        decoration:
                            available ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSelected
                          ? 'Selecionado para reserva'
                          : available
                              ? 'Disponível'
                              : 'Reservado',
                      style: AppText.bodySm.copyWith(
                        color: isSelected
                            ? Colors.white70
                            : available
                                ? AppColors.primary
                                : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    court.formattedPrice,
                    style: AppText.headlineSm.copyWith(
                      color: isSelected ? Colors.white : AppColors.onSurface,
                    ),
                  ),
                  Text(
                    available ? 'por hora' : 'indisponível',
                    style: AppText.bodySm.copyWith(
                      color: isSelected ? Colors.white70 : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra fixa que aparece quando um horário é escolhido.
class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.court,
    required this.slot,
    required this.isBooking,
    required this.onConfirm,
  });

  final Court court;
  final TimeSlot slot;
  final bool isBooking;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.margin,
        AppSpacing.sm + 4,
        AppSpacing.margin,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLowest,
        boxShadow: AppShadows.bottomBar,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('1 hora · ${slot.label}', style: AppText.bodySm),
                Text(court.formattedPrice, style: AppText.headlineMd),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton(
                onPressed: isBooking ? null : onConfirm,
                child: isBooking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirmar reserva'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
