import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/sport.dart';
import 'sport_visuals.dart';

/// Campo de seleção e pré-visualização de foto da quadra.
///
/// Permite escolher imagem da câmera ou da galeria usando [ImagePicker],
/// exibindo preview instantâneo com suporte a remoção ou troca.
class CourtImagePickerField extends StatefulWidget {
  const CourtImagePickerField({
    super.key,
    this.initialBytes,
    this.initialImageUrl,
    this.sport = Sport.futsal,
    required this.onImagePicked,
    this.picker,
  });

  final Uint8List? initialBytes;
  final String? initialImageUrl;
  final Sport sport;
  final void Function(Uint8List? bytes, String mimeType) onImagePicked;
  final ImagePicker? picker;

  @override
  State<CourtImagePickerField> createState() => _CourtImagePickerFieldState();
}

class _CourtImagePickerFieldState extends State<CourtImagePickerField> {
  Uint8List? _bytes;
  late ImagePicker _picker;

  @override
  void initState() {
    super.initState();
    _bytes = widget.initialBytes;
    _picker = widget.picker ?? ImagePicker();
  }

  @override
  void didUpdateWidget(covariant CourtImagePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialBytes != oldWidget.initialBytes) {
      _bytes = widget.initialBytes;
    }
  }

  bool get _hasImage =>
      _bytes != null ||
      (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty);

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop();

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      final mimeType = file.mimeType ?? 'image/jpeg';

      setState(() {
        _bytes = bytes;
      });

      widget.onImagePicked(bytes, mimeType);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar a imagem selecionada.'),
        ),
      );
    }
  }

  void _removeImage() {
    Navigator.of(context).pop();
    setState(() {
      _bytes = null;
    });
    widget.onImagePicked(null, 'image/jpeg');
  }

  void _showPickerBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Text('Foto da Quadra', style: AppText.headlineSm),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.primary),
                title: const Text('Tirar Foto com a Câmera'),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppColors.primary),
                title: const Text('Escolher da Galeria'),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              if (_hasImage)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                  title: Text(
                    'Remover Foto',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: _removeImage,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double height = 180;
    final borderRadius = AppRadius.card;

    return Semantics(
      label: 'Selecionar foto da quadra',
      button: true,
      child: InkWell(
        onTap: _showPickerBottomSheet,
        borderRadius: borderRadius,
        child: Ink(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: borderRadius,
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPreview(),
                _buildOverlayButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: BoxFit.cover,
      );
    }

    if (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty) {
      return CourtImage(
        court: Court(
          id: 'preview',
          name: '',
          sport: widget.sport,
          address: '',
          pricePerHourInCents: 0,
          imageUrl: widget.initialImageUrl!,
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: widget.sport.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.add_a_photo_rounded,
            size: 26,
            color: widget.sport.color,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Adicionar foto da quadra',
          style: AppText.labelLg.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Câmera ou galeria (PNG/JPG)',
          style: AppText.labelMd.copyWith(
            color: AppColors.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildOverlayButton() {
    if (!_hasImage) return const SizedBox.shrink();

    return Positioned(
      bottom: AppSpacing.sm,
      right: AppSpacing.sm,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs + 1,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Trocar foto',
              style: AppText.labelMd.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
