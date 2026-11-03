import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';

/// Divisor visual entre o formulário de credenciais e os botões sociais.
class SocialAuthDivider extends StatelessWidget {
  const SocialAuthDivider({
    super.key,
    this.label = 'ou continue com',
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.md),
  });

  final String label;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          const Expanded(
            child: Divider(
              color: AppColors.outlineVariant,
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              label,
              style: AppText.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const Expanded(
            child: Divider(
              color: AppColors.outlineVariant,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}
