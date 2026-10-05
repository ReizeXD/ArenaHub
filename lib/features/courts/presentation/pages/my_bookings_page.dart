import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../domain/entities/booking_with_court.dart';
import '../controllers/my_bookings_controller.dart';
import '../states/my_bookings_state.dart';
import '../widgets/sport_visuals.dart';

/// As reservas de quem está logado, separadas entre próximas e anteriores.
class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<MyBookingsPage> createState() => MyBookingsPageState();
}

class MyBookingsPageState extends State<MyBookingsPage> {
  bool _showingPast = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => reload());
  }

  /// Recarregada também quando a aba volta ao foco.
  void reload() =>
      context.read<MyBookingsController>().load(widget.session.user.id);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MyBookingsController>().state;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: switch (state) {
          MyBookingsLoading() => const Center(child: CircularProgressIndicator()),
          MyBookingsFailed(:final failure) => _Empty(
              icon: Icons.cloud_off_rounded,
              message: failure.message,
              onRetry: reload,
            ),
          MyBookingsLoaded(:final isEmpty) when isEmpty => const _Empty(
              icon: Icons.event_available_outlined,
              message: 'Você ainda não reservou nenhuma quadra.\n'
                  'Vá em Quadras e escolha um horário.',
            ),
          MyBookingsLoaded(:final upcoming, :final past) => RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margin,
                  AppSpacing.sm,
                  AppSpacing.margin,
                  AppSpacing.bottomSafeArea,
                ),
                children: [
                  _Stats(upcoming: upcoming.length, past: past.length),
                  const SizedBox(height: AppSpacing.md),
                  _Switcher(
                    showingPast: _showingPast,
                    upcoming: upcoming.length,
                    past: past.length,
                    onChanged: (value) => setState(() => _showingPast = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ..._list(_showingPast ? past : upcoming),
                ],
              ),
            ),
        },
      ),
    );
  }

  List<Widget> _list(List<BookingWithCourt> items) {
    if (items.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Text(
            _showingPast
                ? 'Nenhuma partida jogada ainda.'
                : 'Nenhuma reserva futura. Que tal marcar um jogo?',
            textAlign: TextAlign.center,
            style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
      ];
    }

    final featured = !_showingPast ? items.first : null;
    final rest = featured == null ? items : items.skip(1).toList();

    return [
      if (featured != null) ...[
        Text('Seu próximo jogo', style: AppText.headlineMd),
        const SizedBox(height: AppSpacing.sm + 4),
        _FeaturedCard(item: featured),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Também agendadas', style: AppText.headlineMd),
          const SizedBox(height: AppSpacing.sm + 4),
        ],
      ],
      for (final item in rest) ...[
        _BookingCard(item: item),
        const SizedBox(height: AppSpacing.sm + 4),
      ],
    ];
  }
}

/// Os dois contadores do topo, como no design.
class _Stats extends StatelessWidget {
  const _Stats({required this.upcoming, required this.past});

  final int upcoming;
  final int past;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.bolt_rounded,
            tag: 'ATIVAS',
            value: upcoming,
            caption: upcoming == 1 ? 'Próxima partida' : 'Próximas partidas',
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 4),
        Expanded(
          child: _StatCard(
            icon: Icons.history_rounded,
            tag: 'CONCLUÍDAS',
            value: past,
            caption: past == 1 ? 'Partida jogada' : 'Partidas jogadas',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.tag,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final String tag;
  final int value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md - 2),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                  ),
                  child: Text(
                    tag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.labelCaps,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Text('$value', style: AppText.displayMobile),
          Text(caption, style: AppText.bodySm),
        ],
      ),
    );
  }
}

/// Alternador Próximas / Anteriores.
class _Switcher extends StatelessWidget {
  const _Switcher({
    required this.showingPast,
    required this.upcoming,
    required this.past,
    required this.onChanged,
  });

  final bool showingPast;
  final int upcoming;
  final int past;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'Próximas ($upcoming)',
              selected: !showingPast,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'Anteriores ($past)',
              selected: showingPast,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceLowest : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.labelLg.copyWith(
              color: selected ? AppColors.onSurface : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cartão grande do próximo jogo, com foto da quadra.
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.item});

  final BookingWithCourt item;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Stack(
            children: [
              CourtImage(
                court: item.court,
                height: 150,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.onSurface.withValues(alpha: 0.75),
                      ],
                      stops: const [0.4, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: SportBadge(sport: item.court.sport, onImage: true),
              ),
              Positioned(
                left: AppSpacing.md - 2,
                right: AppSpacing.md - 2,
                bottom: AppSpacing.sm + 4,
                child: Text(
                  item.court.name,
                  style: AppText.headlineMd.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md - 2),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HORÁRIO', style: AppText.labelCaps),
                      Text(
                        '${item.formattedDate} · ${item.formattedTime}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.headlineSm,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('VALOR', style: AppText.labelCaps),
                    Text(
                      item.court.formattedPrice,
                      maxLines: 1,
                      style: AppText.headlineSm.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.item});

  final BookingWithCourt item;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.isPast ? 0.65 : 1,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: item.court.sport.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                item.court.sport.icon,
                size: 22,
                color: item.court.sport.color,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.court.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.headlineSm,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.formattedDate} · ${item.formattedTime}',
                    style: AppText.bodySm,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.xs + 1,
              ),
              decoration: BoxDecoration(
                color: item.isPast ? AppColors.surfaceLow : const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
              ),
              child: Text(
                item.isPast ? 'REALIZADA' : 'CONFIRMADA',
                style: AppText.labelCaps.copyWith(
                  color: item.isPast
                      ? AppColors.onSurfaceVariant
                      : const Color(0xFF059669),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.message, this.onRetry});

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.outline),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: onRetry, child: const Text('Tentar de novo')),
            ],
          ],
        ),
      ),
    );
  }
}
