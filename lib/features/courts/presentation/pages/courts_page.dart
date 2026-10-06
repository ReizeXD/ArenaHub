import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../router/app_router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';
import '../../domain/entities/court.dart';
import '../controllers/courts_controller.dart';
import '../states/courts_state.dart';
import '../widgets/sport_visuals.dart';

/// Aba de quadras disponíveis.
class CourtsPage extends StatefulWidget {
  const CourtsPage({super.key});

  @override
  State<CourtsPage> createState() => _CourtsPageState();
}

class _CourtsPageState extends State<CourtsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<CourtsController>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CourtsController>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: switch (controller.state) {
          CourtsLoading() => const Center(child: CircularProgressIndicator()),
          CourtsFailed(:final failure) => _Empty(
              icon: Icons.cloud_off_rounded,
              message: failure.message,
              onRetry: () => context.read<CourtsController>().load(),
            ),
          CourtsLoaded(:final courts) when courts.isEmpty => const _Empty(
              icon: Icons.sports_soccer_outlined,
              message: 'Nenhuma quadra cadastrada ainda.',
            ),
          CourtsLoaded() => _Catalog(controller: controller),
        },
      ),
    );
  }
}

class _Catalog extends StatelessWidget {
  const _Catalog({required this.controller});

  final CourtsController controller;

  @override
  Widget build(BuildContext context) {
    final courts = controller.visibleCourts;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.margin,
        AppSpacing.sm,
        AppSpacing.margin,
        AppSpacing.bottomSafeArea,
      ),
      children: [
        _SportFilter(controller: controller),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text('Quadras disponíveis', style: AppText.headlineMd),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              courts.length == 1 ? '1 quadra' : '${courts.length} quadras',
              style: AppText.bodySm,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm + 4),
        if (courts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text(
              'Nenhuma quadra desta modalidade.',
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
          )
        else
          for (final court in courts) ...[
            _CourtCard(court: court),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

/// Chips de modalidade, em pílula, como no design.
class _SportFilter extends StatelessWidget {
  const _SportFilter({required this.controller});

  final CourtsController controller;

  @override
  Widget build(BuildContext context) {
    final sports = controller.availableSports;

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(
            label: 'Todos',
            icon: Icons.apps_rounded,
            selected: controller.sport == null,
            color: AppColors.primary,
            onTap: () => controller.filterBy(null),
          ),
          for (final sport in sports) ...[
            const SizedBox(width: AppSpacing.sm),
            _Chip(
              label: sport.label,
              icon: sport.icon,
              selected: controller.sport == sport,
              color: sport.color,
              onTap: () => controller.filterBy(sport),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceLowest,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : color,
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                label,
                style: AppText.labelLg.copyWith(
                  color: selected ? Colors.white : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourtCard extends StatelessWidget {
  const _CourtCard({required this.court});

  final Court court;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLowest,
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: () => context.push(AppRoutes.court(court.id), extra: court),
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
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md - 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(court.name, style: AppText.headlineSm),
                    const SizedBox(height: AppSpacing.xs + 2),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            court.formattedPrice,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.headlineMd.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            ' /hora',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodySm,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
              style: AppText.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
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
