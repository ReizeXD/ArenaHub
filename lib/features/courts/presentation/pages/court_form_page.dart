import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/result.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_typography.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/sport.dart';
import '../controllers/my_courts_controller.dart';
import '../widgets/court_image_picker_field.dart';
import '../widgets/sport_visuals.dart';

/// Formulário para cadastro e edição de quadras esportivas do proprietário (#43, #44).
class CourtFormPage extends StatefulWidget {
  const CourtFormPage({
    super.key,
    required this.ownerId,
    this.courtToEdit,
    this.controller,
  });

  /// Identificador do proprietário da quadra.
  final String ownerId;

  /// Se informado, a página opera em modo de edição (#44).
  /// Se nulo, opera em modo de criação (#43).
  final Court? courtToEdit;

  /// Controlador opcional para testes ou injeção direta.
  /// Se omitido, busca via [Provider] no contexto.
  final MyCourtsController? controller;

  /// Converte texto de valor monetário (ex.: '120', '120,50', '1.200,00') em centavos.
  static int? parsePriceInCents(String raw) {
    var text = raw.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (text.isEmpty) return null;
    if (text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    }
    final value = double.tryParse(text);
    if (value == null || value <= 0 || value.isNaN || value.isInfinite) {
      return null;
    }
    return (value * 100).round();
  }

  @override
  State<CourtFormPage> createState() => _CourtFormPageState();
}

class _CourtFormPageState extends State<CourtFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _priceController;

  late Sport _selectedSport;
  late int _openingHour;
  late int _closingHour;

  Uint8List? _imageBytes;
  String _imageMimeType = 'image/jpeg';
  bool _imageCleared = false;
  bool _isSubmitting = false;
  String? _hoursError;

  bool get _isEditing => widget.courtToEdit != null;

  @override
  void initState() {
    super.initState();
    final court = widget.courtToEdit;

    _nameController = TextEditingController(text: court?.name ?? '');
    _addressController = TextEditingController(text: court?.address ?? '');

    if (court != null) {
      final cents = court.pricePerHourInCents;
      final reais = cents ~/ 100;
      final centRemainder = cents % 100;
      _priceController = TextEditingController(
        text: centRemainder == 0
            ? '$reais'
            : '$reais,${centRemainder.toString().padLeft(2, '0')}',
      );
    } else {
      _priceController = TextEditingController();
    }

    _selectedSport = court?.sport ?? Sport.beachTennis;
    _openingHour = court?.openingHour ?? 8;
    _closingHour = court?.closingHour ?? 22;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  MyCourtsController _resolveController() {
    if (widget.controller != null) return widget.controller!;
    return context.read<MyCourtsController>();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() {
      _hoursError = null;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_closingHour <= _openingHour) {
      setState(() {
        _hoursError =
            'O horário de fechamento deve ser posterior ao de abertura.';
      });
      return;
    }

    final priceInCents = CourtFormPage.parsePriceInCents(_priceController.text);
    if (priceInCents == null || priceInCents <= 0) {
      return;
    }

    setState(() => _isSubmitting = true);

    final controller = _resolveController();
    final Result<Court> result;

    if (_isEditing) {
      final existing = widget.courtToEdit!;
      result = await controller.update(
        existing: existing,
        userId: widget.ownerId,
        name: _nameController.text.trim(),
        sport: _selectedSport,
        address: _addressController.text.trim(),
        pricePerHourInCents: priceInCents,
        imageUrl: _imageCleared ? '' : existing.imageUrl,
        newImageBytes: _imageBytes,
        newImageMimeType: _imageMimeType,
        openingHour: _openingHour,
        closingHour: _closingHour,
      );
    } else {
      result = await controller.create(
        ownerId: widget.ownerId,
        name: _nameController.text.trim(),
        sport: _selectedSport,
        address: _addressController.text.trim(),
        pricePerHourInCents: priceInCents,
        imageUrl: '',
        imageBytes: _imageBytes,
        imageMimeType: _imageMimeType,
        openingHour: _openingHour,
        closingHour: _closingHour,
      );
    }

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    switch (result) {
      case Ok():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.slot),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: Text(
                    _isEditing
                        ? 'Quadra atualizada com sucesso!'
                        : 'Quadra cadastrada com sucesso!',
                    style: AppText.labelLg.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      case Err(:final failure):
        setState(() => _isSubmitting = false);
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
    final title = _isEditing ? 'Editar Quadra' : 'Nova Quadra';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: AppText.headlineMd),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
                vertical: AppSpacing.md,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo de Foto (#41)
                    CourtImagePickerField(
                      initialImageUrl: widget.courtToEdit?.imageUrl,
                      sport: _selectedSport,
                      onImagePicked: (bytes, mimeType) {
                        setState(() {
                          _imageBytes = bytes;
                          _imageMimeType = mimeType;
                          _imageCleared = (bytes == null);
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Nome da quadra
                    Text('Nome da quadra', style: AppText.labelLg),
                    const SizedBox(height: AppSpacing.xs + 2),
                    TextFormField(
                      key: const Key('court_name_field'),
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Ex.: Quadra Principal de Beach Tennis',
                        prefixIcon: Icon(Icons.sports_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome da quadra';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Modalidade
                    Text('Modalidade', style: AppText.labelLg),
                    const SizedBox(height: AppSpacing.xs + 2),
                    DropdownButtonFormField<Sport>(
                      key: const Key('court_sport_field'),
                      initialValue: _selectedSport,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      items: Sport.values.map((sport) {
                        return DropdownMenuItem<Sport>(
                          value: sport,
                          child: Row(
                            children: [
                              Icon(sport.icon, size: 20, color: sport.color),
                              const SizedBox(width: AppSpacing.sm),
                              Text(sport.label, style: AppText.bodyMd),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSport = val);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Endereço
                    Text('Endereço', style: AppText.labelLg),
                    const SizedBox(height: AppSpacing.xs + 2),
                    TextFormField(
                      key: const Key('court_address_field'),
                      controller: _addressController,
                      decoration: const InputDecoration(
                        hintText: 'Ex.: Av. das Américas, 500 - Barra',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o endereço da quadra';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Preço por hora
                    Text('Preço por hora', style: AppText.labelLg),
                    const SizedBox(height: AppSpacing.xs + 2),
                    TextFormField(
                      key: const Key('court_price_field'),
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.,]'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'Ex.: 120,00',
                        prefixText: 'R\$ ',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o preço por hora';
                        }
                        final cents = CourtFormPage.parsePriceInCents(value);
                        if (cents == null || cents <= 0) {
                          return 'Informe um preço válido maior que zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Horários de Funcionamento
                    Text('Horário de funcionamento', style: AppText.labelLg),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            key: const Key('court_opening_hour_field'),
                            initialValue: _openingHour,
                            decoration: const InputDecoration(
                              labelText: 'Abertura',
                              prefixIcon: Icon(Icons.schedule_rounded),
                            ),
                            items: List.generate(24, (i) => i).map((h) {
                              return DropdownMenuItem<int>(
                                value: h,
                                child: Text('${h.toString().padLeft(2, '0')}:00'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _openingHour = val;
                                  _hoursError = null;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            key: const Key('court_closing_hour_field'),
                            initialValue: _closingHour,
                            decoration: const InputDecoration(
                              labelText: 'Fechamento',
                              prefixIcon: Icon(Icons.schedule_rounded),
                            ),
                            items: List.generate(25, (i) => i)
                                .where((h) => h > 0)
                                .map((h) {
                              return DropdownMenuItem<int>(
                                value: h,
                                child: Text('${h.toString().padLeft(2, '0')}:00'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _closingHour = val;
                                  _hoursError = null;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_hoursError != null) ...[
                      const SizedBox(height: AppSpacing.xs + 2),
                      Text(
                        _hoursError!,
                        style: AppText.bodySm.copyWith(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),

                    // Botão de submissão
                    FilledButton(
                      key: const Key('court_submit_button'),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEditing ? 'Salvar Alterações' : 'Cadastrar Quadra'),
                    ),
                    const SizedBox(height: AppSpacing.bottomSafeArea),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
