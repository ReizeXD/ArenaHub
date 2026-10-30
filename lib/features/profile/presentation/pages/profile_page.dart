import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../courts/presentation/controllers/my_courts_controller.dart';
import '../../../courts/presentation/states/my_courts_state.dart';
import '../../../../router/app_router.dart';
import '../controllers/app_mode_controller.dart';

/// Tela de perfil do usuário com informações da conta, botão de logout
/// e gatilho contextual para alternância de modo (estilo Airbnb).
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.session,
    this.appModeController,
    this.myCourtsController,
    this.onAddCourt,
    this.onSwitchToOwner,
    this.onSwitchToAthlete,
    this.onSignOut,
  });

  final AuthSession session;
  final AppModeController? appModeController;
  final MyCourtsController? myCourtsController;
  final VoidCallback? onAddCourt;
  final VoidCallback? onSwitchToOwner;
  final VoidCallback? onSwitchToAthlete;
  final VoidCallback? onSignOut;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AppModeController? _fallbackModeController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveMyCourtsController().load(widget.session.user.id);
    });
  }

  MyCourtsController _resolveMyCourtsController() {
    if (widget.myCourtsController != null) return widget.myCourtsController!;
    return context.read<MyCourtsController>();
  }

  AppModeController _resolveAppModeController() {
    if (widget.appModeController != null) return widget.appModeController!;
    try {
      return context.read<AppModeController>();
    } catch (_) {
      return _fallbackModeController ??= AppModeController();
    }
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final modeController = _resolveAppModeController();

    return ListenableBuilder(
      listenable: modeController,
      builder: (context, _) {
        final mode = modeController.mode;

        return Scaffold(
          appBar: AppBar(
            title: Text('Meu Perfil', style: AppText.headlineMd),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.margin,
                    AppSpacing.md,
                    AppSpacing.margin,
                    AppSpacing.bottomSafeArea,
                  ),
                  children: [
                    _buildUserHeader(mode),
                    const SizedBox(height: AppSpacing.lg),
                    _buildContextSection(mode, modeController),
                    const SizedBox(height: AppSpacing.xl),
                    _buildAccountActions(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserHeader(AppMode mode) {
    final user = widget.session.user;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.15),
            child: Text(
              _initials(user.fullName),
              style: AppText.headlineSm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: AppText.headlineSm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: AppText.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildModeBadge(mode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeBadge(AppMode mode) {
    final isAthlete = mode == AppMode.athlete;
    final color = isAthlete ? AppColors.primary : AppColors.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAthlete ? Icons.sports_soccer_rounded : Icons.storefront_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              isAthlete ? 'Modo Atleta' : 'Modo Proprietário',
              style: AppText.labelMd.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextSection(AppMode mode, AppModeController modeController) {
    final myCourts = widget.myCourtsController != null
        ? ListenableBuilder(
            listenable: widget.myCourtsController!,
            builder: (ctx, _) => _buildCourtContent(
              ctx,
              widget.myCourtsController!,
              mode,
              modeController,
            ),
          )
        : Builder(
            builder: (ctx) {
              final ctrl = ctx.watch<MyCourtsController>();
              return _buildCourtContent(ctx, ctrl, mode, modeController);
            },
          );

    return myCourts;
  }

  Widget _buildCourtContent(
    BuildContext context,
    MyCourtsController courtsController,
    AppMode mode,
    AppModeController modeController,
  ) {
    final state = courtsController.state;

    if (state is MyCourtsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final courts = courtsController.courts;

    // Se o usuário NÃO possui quadras cadastradas: exibe o banner CTA
    if (courts.isEmpty) {
      return _buildNoCourtsBanner(context);
    }

    // Se o usuário JÁ possui quadras cadastradas: exibe o switch de contexto
    return _buildHasCourtsCard(context, courts.length, mode, modeController);
  }

  Widget _buildNoCourtsBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cadastrar minha arena',
                      style: AppText.headlineSm,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Comece a disponibilizar quadras e receba reservas',
                      style: AppText.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Você ainda não possui quadras cadastradas. Torne-se um parceiro do ArenaHub e gerencie horários e faturamento diretamente pelo app!',
            style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('profile_add_first_court_button'),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Cadastrar Minha Arena'),
              onPressed: () {
                if (widget.onAddCourt != null) {
                  widget.onAddCourt!();
                } else {
                  context.push(AppRoutes.myCourtsNew);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHasCourtsCard(
    BuildContext context,
    int courtsCount,
    AppMode mode,
    AppModeController modeController,
  ) {
    final isAthlete = mode == AppMode.athlete;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stadium_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sua Arena',
                      style: AppText.headlineSm,
                    ),
                    Text(
                      courtsCount == 1
                          ? '1 quadra gerenciada'
                          : '$courtsCount quadras gerenciadas',
                      style: AppText.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isAthlete) ...[
            Text(
              'Alterne para o painel de proprietário para gerenciar suas quadras, aprovar horários e consultar a receita.',
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                key: const Key('profile_switch_to_owner_button'),
                icon: const Icon(Icons.storefront_rounded, size: 20),
                label: const Text('Alternar para Modo Proprietário'),
                onPressed: () {
                  if (widget.onSwitchToOwner != null) {
                    widget.onSwitchToOwner!();
                  } else {
                    modeController.setMode(AppMode.owner);
                  }
                },
              ),
            ),
          ] else ...[
            Text(
              'Você está no Modo Proprietário. Deseja navegar pelo catálogo como atleta para buscar e agendar quadras?',
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                key: const Key('profile_switch_to_athlete_button'),
                icon: const Icon(Icons.sports_soccer_rounded, size: 20),
                label: const Text('Alternar para Modo Atleta'),
                onPressed: () {
                  if (widget.onSwitchToAthlete != null) {
                    widget.onSwitchToAthlete!();
                  } else {
                    modeController.setMode(AppMode.athlete);
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: const Key('profile_logout_button'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: BorderSide(
              color: AppColors.error.withValues(alpha: 0.5),
            ),
          ),
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text('Sair da conta'),
          onPressed: () {
            if (widget.onSignOut != null) {
              widget.onSignOut!();
            } else {
              context.read<AuthController>().signOut();
            }
          },
        ),
      ],
    );
  }
}
