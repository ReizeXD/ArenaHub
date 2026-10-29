import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';
import '../../domain/entities/court.dart';

/// Modal de confirmação para exclusão de quadra esportiva (#46).
class DeleteCourtDialog extends StatelessWidget {
  const DeleteCourtDialog({super.key, required this.court});

  final Court court;

  /// Exibe o diálogo de confirmação e retorna `true` se o usuário confirmou a exclusão.
  static Future<bool> show({
    required BuildContext context,
    required Court court,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => DeleteCourtDialog(court: court),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      backgroundColor: AppColors.surfaceLowest,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Text('Excluir Quadra', style: AppText.headlineSm),
        ],
      ),
      content: Text(
        'Tem certeza de que deseja excluir a quadra "${court.name}"? Esta ação é definitiva e não poderá ser desfeita.',
        style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        TextButton(
          key: const Key('delete_court_cancel_button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('delete_court_confirm_button'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            minimumSize: const Size(100, 44),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Excluir'),
        ),
      ],
    );
  }
}
