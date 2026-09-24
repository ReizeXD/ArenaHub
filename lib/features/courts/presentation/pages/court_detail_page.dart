import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/time_slot.dart';
import '../controllers/booking_controller.dart';
import '../states/agenda_state.dart';
import '../widgets/sport_visuals.dart';

/// Detalhe da quadra: dados, agenda do dia escolhido e a reserva.
class CourtDetailPage extends StatefulWidget {
  const CourtDetailPage({super.key, required this.court});

  final Court court;

  @override
  State<CourtDetailPage> createState() => _CourtDetailPageState();
}

class _CourtDetailPageState extends State<CourtDetailPage> {
  static const List<String> _weekdays = [
    'seg',
    'ter',
    'qua',
    'qui',
    'sex',
    'sáb',
    'dom',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<BookingController>().open(widget.court),
    );
  }

  String _dayLabel(DateTime day) => _weekdays[day.weekday - 1];

  Future<void> _onSlotTapped(TimeSlot slot) async {
    final controller = context.read<BookingController>();
    final session = context.read<AuthController>().session;
    if (session == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar reserva'),
        content: Text(
          '${widget.court.name}\n'
          '${slot.start.day.toString().padLeft(2, '0')}/'
          '${slot.start.month.toString().padLeft(2, '0')} às ${slot.label}\n'
          '${widget.court.formattedPrice} por 1 hora',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reservar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final failure = await controller.book(
      slot: slot,
      userId: session.user.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            failure == null ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(
              failure == null
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                failure?.message ??
                    'Reserva confirmada para ${slot.label}. Bom jogo!',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingController>();
    final court = widget.court;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          court.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                CourtCover(
                  sport: court.sport,
                  width: double.infinity,
                  height: 170,
                  borderRadius: 18,
                  iconSize: 64,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: court.sport.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        court.sport.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: court.sport.color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      court.formattedPrice,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      ' / hora',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        court.address,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const _SectionTitle('Escolha o dia'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 68,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.availableDays.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, index) {
                      final day = controller.availableDays[index];
                      final selected = day == controller.selectedDay;

                      return GestureDetector(
                        onTap: () => controller.selectDay(day),
                        child: Container(
                          width: 58,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF10B981)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _dayLabel(day),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                day.day.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      selected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const _SectionTitle('Horários'),
                const SizedBox(height: 12),
                switch (controller.state) {
                  AgendaLoading() => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  AgendaFailed(:final failure) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        failure.message,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  AgendaLoaded(:final slots) when !slots.any((s) => s.isAvailable) =>
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Nenhum horário livre neste dia. Tente outro.',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  AgendaLoaded(:final slots) => Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final slot in slots)
                          _SlotChip(
                            slot: slot,
                            enabled: slot.isAvailable && !controller.isBooking,
                            onTap: () => _onSlotTapped(slot),
                          ),
                      ],
                    ),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      );
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.enabled,
    required this.onTap,
  });

  final TimeSlot slot;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF10B981);

    return Material(
      color: enabled ? brand.withValues(alpha: 0.10) : Colors.grey[100],
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 78,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? brand.withValues(alpha: 0.35)
                  : Colors.grey.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            slot.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: enabled ? brand : Colors.grey[400],
              decoration: slot.isAvailable ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
      ),
    );
  }
}
