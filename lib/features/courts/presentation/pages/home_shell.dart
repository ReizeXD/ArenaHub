import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/controllers/app_mode_controller.dart';
import '../controllers/my_bookings_controller.dart';
import '../controllers/my_courts_controller.dart';

/// Moldura de quem está logado: cabeçalho com feedback visual e barra de navegação
/// com alternância dinâmica de contexto (Modo Atleta / Modo Proprietário estilo Airbnb).
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.session,
    required this.navigationShell,
    this.appModeController,
  });

  final AuthSession session;
  final StatefulNavigationShell navigationShell;
  final AppModeController? appModeController;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AppModeController? _fallbackController;
  AppMode? _lastMode;

  static const List<String> _athleteSubtitles = [
    'Encontre e reserve sua quadra hoje',
    'Seus horários reservados',
    'Gerencie sua conta e modo de uso',
  ];

  static const List<String> _ownerSubtitles = [
    'Gerenciamento de quadras da arena',
    'Perfil e configurações da arena',
  ];

  AppModeController _resolveModeController() {
    if (widget.appModeController != null) return widget.appModeController!;
    try {
      return context.read<AppModeController>();
    } catch (_) {
      return _fallbackController ??= AppModeController();
    }
  }

  void _onModeChanged() {
    final controller = _resolveModeController();
    final mode = controller.mode;

    if (_lastMode != null && _lastMode != mode) {
      // Ao alternar de contexto, reseta o índice de navegação ativo para 0
      final targetBranch = mode == AppMode.owner ? 3 : 0;
      if (widget.navigationShell.currentIndex != targetBranch) {
        widget.navigationShell.goBranch(targetBranch);
      }
    }
    _lastMode = mode;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = _resolveModeController();
      _lastMode = ctrl.mode;
      ctrl.addListener(_onModeChanged);

      // Se a rota inicial for a aba de proprietário, alinha o modo
      if (widget.navigationShell.currentIndex == 3 &&
          ctrl.mode != AppMode.owner) {
        _lastMode = AppMode.owner;
        ctrl.setMode(AppMode.owner);
      }
    });
  }

  @override
  void dispose() {
    final ctrl = _resolveModeController();
    ctrl.removeListener(_onModeChanged);
    _fallbackController?.dispose();
    super.dispose();
  }

  int _calculateActiveTabIndex(AppMode mode, int branchIndex) {
    if (mode == AppMode.athlete) {
      return switch (branchIndex) {
        0 => 0,
        1 => 1,
        2 => 2,
        _ => 0,
      };
    } else {
      return switch (branchIndex) {
        3 => 0,
        2 => 1,
        _ => 0,
      };
    }
  }

  void _onTabSelected(BuildContext context, AppMode mode, int tabIndex) {
    if (mode == AppMode.athlete) {
      final targetBranch = switch (tabIndex) {
        0 => 0,
        1 => 1,
        2 => 2,
        _ => 0,
      };
      widget.navigationShell.goBranch(
        targetBranch,
        initialLocation: targetBranch == widget.navigationShell.currentIndex,
      );
      if (targetBranch == 1) {
        context.read<MyBookingsController>().load(widget.session.user.id);
      }
    } else {
      final targetBranch = switch (tabIndex) {
        0 => 3,
        1 => 2,
        _ => 3,
      };
      widget.navigationShell.goBranch(
        targetBranch,
        initialLocation: targetBranch == widget.navigationShell.currentIndex,
      );
      if (targetBranch == 3) {
        context.read<MyCourtsController>().load(widget.session.user.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeController = _resolveModeController();

    return ListenableBuilder(
      listenable: modeController,
      builder: (ctx, _) {
        final mode = modeController.mode;
        final branchIndex = widget.navigationShell.currentIndex;
        final tabIndex = _calculateActiveTabIndex(mode, branchIndex);

        final subtitle = mode == AppMode.athlete
            ? _athleteSubtitles[tabIndex.clamp(0, _athleteSubtitles.length - 1)]
            : _ownerSubtitles[tabIndex.clamp(0, _ownerSubtitles.length - 1)];

        return Scaffold(
          extendBody: true,
          appBar: _Header(
            session: widget.session,
            subtitle: subtitle,
            mode: mode,
          ),
          body: SafeArea(bottom: false, child: widget.navigationShell),
          bottomNavigationBar: _FloatingNav(
            mode: mode,
            index: tabIndex,
            onSelected: (i) => _onTabSelected(ctx, mode, i),
          ),
        );
      },
    );
  }
}

/// Cabeçalho com marca, saudação, badge do modo ativo e botão de saída.
class _Header extends StatelessWidget implements PreferredSizeWidget {
  const _Header({
    required this.session,
    required this.subtitle,
    required this.mode,
  });

  final AuthSession session;
  final String subtitle;
  final AppMode mode;

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final isAthlete = mode == AppMode.athlete;

    return AppBar(
      toolbarHeight: 76,
      titleSpacing: AppSpacing.margin,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isAthlete ? AppColors.primary : AppColors.secondary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(
              isAthlete ? Icons.sports_soccer_rounded : Icons.storefront_rounded,
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
                        isAthlete
                            ? 'Olá, ${session.user.firstName}'
                            : 'Arena de ${session.user.firstName}',
                        overflow: TextOverflow.ellipsis,
                        style: AppText.headlineMd,
                      ),
                    ),
                    if (!isAthlete) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.xxl),
                        ),
                        child: Text(
                          'PROPRIETÁRIO',
                          style: AppText.labelCaps.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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

/// Barra inferior flutuante adaptável ao contexto ativo.
class _FloatingNav extends StatelessWidget {
  const _FloatingNav({
    required this.mode,
    required this.index,
    required this.onSelected,
  });

  final AppMode mode;
  final int index;
  final ValueChanged<int> onSelected;

  static const List<({IconData icon, IconData active, String label})> _athleteTabs = [
    (
      icon: Icons.sports_soccer_outlined,
      active: Icons.sports_soccer_rounded,
      label: 'Quadras',
    ),
    (
      icon: Icons.event_note_outlined,
      active: Icons.event_note_rounded,
      label: 'Reservas',
    ),
    (
      icon: Icons.person_outline_rounded,
      active: Icons.person_rounded,
      label: 'Perfil',
    ),
  ];

  static const List<({IconData icon, IconData active, String label})> _ownerTabs = [
    (
      icon: Icons.stadium_outlined,
      active: Icons.stadium_rounded,
      label: 'Minhas Quadras',
    ),
    (
      icon: Icons.manage_accounts_outlined,
      active: Icons.manage_accounts_rounded,
      label: 'Perfil da Arena',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tabs = mode == AppMode.athlete ? _athleteTabs : _ownerTabs;

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
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: _NavItem(
                  tab: tabs[i],
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
              Text(
                tab.label,
                style: AppText.labelMd.copyWith(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
