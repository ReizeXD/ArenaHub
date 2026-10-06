import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/my_bookings_controller.dart';

/// Moldura de quem está logado: cabeçalho e barra de abas.
class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.session,
    required this.navigationShell,
  });

  final AuthSession session;
  final StatefulNavigationShell navigationShell;

  static const List<String> _subtitles = [
    'Encontre e reserve sua quadra hoje',
    'Seus horários reservados',
  ];

  void _onTabSelected(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
    if (index == 1) {
      context.read<MyBookingsController>().load(session.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;

    return Scaffold(
      extendBody: true,
      appBar: _Header(session: session, subtitle: _subtitles[index]),
      body: SafeArea(bottom: false, child: navigationShell),
      bottomNavigationBar: _FloatingNav(
        index: index,
        onSelected: (i) => _onTabSelected(context, i),
      ),
    );
  }
}

/// Cabeçalho com marca, saudação e saída.
class _Header extends StatelessWidget implements PreferredSizeWidget {
  const _Header({required this.session, required this.subtitle});

  final AuthSession session;
  final String subtitle;

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 76,
      titleSpacing: AppSpacing.margin,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.sports_soccer_rounded,
              size: 21,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Olá, ${session.user.firstName}',
                        overflow: TextOverflow.ellipsis,
                        style: AppText.headlineMd,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                      ),
                      child: Text(
                        'MACEIÓ, AL',
                        style: AppText.labelCaps.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodySm,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Sair',
          icon: const Icon(Icons.logout_rounded),
          color: AppColors.onSurfaceVariant,
          onPressed: () => context.read<AuthController>().signOut(),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}

/// Barra inferior flutuante, como no design.
class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  static const List<({IconData icon, IconData active, String label})> _tabs = [
    (
      icon: Icons.sports_soccer_outlined,
      active: Icons.sports_soccer_rounded,
      label: 'Quadras'
    ),
    (
      icon: Icons.event_note_outlined,
      active: Icons.event_note_rounded,
      label: 'Reservas'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.margin,
          0,
          AppSpacing.margin,
          AppSpacing.sm + 4,
        ),
        padding: const EdgeInsets.all(AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: AppShadows.bottomBar,
        ),
        child: Row(
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Expanded(
                child: _NavItem(
                  tab: _tabs[i],
                  selected: index == i,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final ({IconData icon, IconData active, String label}) tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.onSurfaceVariant;

    return Material(
      color: selected ? AppColors.surfaceLow : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? tab.active : tab.icon, size: 22, color: color),
              const SizedBox(height: 3),
              Text(tab.label, style: AppText.labelMd.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
