import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';

/// Botão base para provedores de autenticação social.
class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isLoading = false,
    this.backgroundColor = AppColors.surfaceLowest,
    this.foregroundColor = AppColors.onSurface,
    this.borderColor = AppColors.outlineVariant,
    this.borderRadius,
    this.height = 52.0,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final bool isLoading;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final double height;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppRadius.slot;
    final isInteractive = onPressed != null && !isLoading;

    final effectiveBg = isInteractive
        ? backgroundColor
        : backgroundColor.withValues(alpha: 0.6);
    final effectiveFg = isInteractive
        ? foregroundColor
        : foregroundColor.withValues(alpha: 0.5);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveRadius,
        border: borderColor != null
            ? Border.all(
                color: isInteractive
                    ? borderColor!
                    : borderColor!.withValues(alpha: 0.4),
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInteractive ? onPressed : null,
          borderRadius: effectiveRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: effectiveFg,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        icon,
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.labelLg.copyWith(
                              color: effectiveFg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
