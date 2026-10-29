import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/result.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';
import '../../domain/entities/court.dart';
import '../controllers/my_courts_controller.dart';
import '../states/my_courts_state.dart';
import '../widgets/delete_court_dialog.dart';
import '../widgets/owner_court_card.dart';
import 'court_form_page.dart';

/// Aba/Tela de gerenciamento de quadras do dono da arena (#47).
///
/// Exibe listagem com cards rápidos, estado vazio amigável convidando ao cadastro,
/// atualização via pull-to-refresh e modais de edição e exclusão.
class MyCourtsPage extends StatefulWidget {
  const MyCourtsPage({
    super.key,
    required this.ownerId,
    this.controller,
    this.onViewCourtAgenda,
  });

  /// Identificador do proprietário das quadras.
  final String ownerId;

  /// Controlador opcional (para injeção direta em testes).
  final MyCourtsController? controller;

  /// Callback para navegação para a agenda da quadra (quando integrado ao épico 5).
  final void Function(Court court)? onViewCourtAgenda;

  @override
  State<MyCourtsPage> createState() => _MyCourtsPageState();
}

class _MyCourtsPageState extends State<MyCourtsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveController().load(widget.ownerId);
    });
  }

  MyCourtsController _resolveController() {
    if (widget.controller != null) return widget.controller!;
    return context.read<MyCourtsController>();
  }

  Future<void> _openAddCourt(MyCourtsController controller) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CourtFormPage(
          ownerId: widget.ownerId,
          controller: controller,
        ),
      ),
    );
  }

  Future<void> _openEditCourt(
    MyCourtsController controller,
    Court court,
  ) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CourtFormPage(
          ownerId: widget.ownerId,
          courtToEdit: court,
          controller: controller,
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteCourt(
    MyCourtsController controller,
    Court court,
  ) async {
    final confirmed = await DeleteCourtDialog.show(
      context: context,
      court: court,
    );

    if (!confirmed || !mounted) return;

    final result = await controller.delete(
      court: court,
      userId: widget.ownerId,
    );

    if (!mounted) return;

    switch (result) {
      case Ok():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.slot),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: Text(
                    'Quadra "${court.name}" excluída com sucesso.',
                    style: AppText.labelLg.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      case Err(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.slot),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: Text(
                    failure.message,
                    style: AppText.labelLg.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller != null
        ? ListenableBuilder(
            listenable: widget.controller!,
            builder: (ctx, _) => _buildBody(ctx, widget.controller!),
          )
        : Builder(
            builder: (ctx) {
              final ctrl = ctx.watch<MyCourtsController>();
              return _buildBody(ctx, ctrl);
            },
          );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: controller,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MyCourtsController controller) {
    return switch (controller.state) {
      MyCourtsLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
      MyCourtsFailed(:final failure) => _ErrorView(
          message: failure.message,
          onRetry: () => controller.load(widget.ownerId),
        ),
      MyCourtsLoaded(:final courts) when courts.isEmpty => _EmptyView(
          onAddCourt: () => _openAddCourt(controller),
        ),
      MyCourtsLoaded(:final courts) => RefreshIndicator(
          onRefresh: () => controller.load(widget.ownerId),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.margin,
              AppSpacing.md,
              AppSpacing.margin,
              AppSpacing.bottomSafeArea,
            ),
            children: [
              // Barra superior com contagem e botão de adição
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Minhas Quadras', style: AppText.headlineMd),
                        const SizedBox(height: 2),
                        Text(
                          courts.length == 1
                              ? '1 quadra gerenciada'
                              : '${courts.length} quadras gerenciadas',
                          style: AppText.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    key: const Key('add_court_button'),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Nova Quadra'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.slot,
                      ),
                    ),
                    onPressed: () => _openAddCourt(controller),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Lista de cards das quadras
              for (final court in courts) ...[
                OwnerCourtCard(
                  court: court,
                  onViewAgenda: () => widget.onViewCourtAgenda?.call(court),
                  onEdit: () => _openEditCourt(controller, court),
                  onDelete: () => _confirmAndDeleteCourt(controller, court),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
    };
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAddCourt});

  final VoidCallback onAddCourt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sports_soccer_rounded,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nenhuma quadra cadastrada',
              style: AppText.headlineSm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Você ainda não possui quadras cadastradas na sua arena. Comece adicionando sua primeira quadra para disponibilizar horários!',
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              key: const Key('empty_add_court_button'),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Cadastrar Primeira Quadra'),
              onPressed: onAddCourt,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
