import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/domain/entities/auth_session.dart';
import '../../domain/entities/booking_with_court.dart';
import '../controllers/my_bookings_controller.dart';
import '../states/my_bookings_state.dart';
import '../widgets/sport_visuals.dart';

/// As reservas de quem está logado, separadas entre próximas e anteriores.
class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<MyBookingsPage> createState() => MyBookingsPageState();
}

class MyBookingsPageState extends State<MyBookingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => reload());
  }

  /// Recarregada também quando a aba volta ao foco, para refletir uma reserva
  /// feita na outra aba.
  void reload() =>
      context.read<MyBookingsController>().load(widget.session.user.id);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MyBookingsController>().state;

    return switch (state) {
      MyBookingsLoading() => const Center(child: CircularProgressIndicator()),
      MyBookingsFailed(:final failure) => _Empty(
          icon: Icons.error_outline_rounded,
          message: failure.message,
          onRetry: reload,
        ),
      MyBookingsLoaded(:final isEmpty) when isEmpty => const _Empty(
          icon: Icons.event_available_outlined,
          message: 'Você ainda não reservou nenhuma quadra.\n'
              'Vá em Quadras e escolha um horário.',
        ),
      MyBookingsLoaded(:final upcoming, :final past) => RefreshIndicator(
          onRefresh: () async => reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (upcoming.isNotEmpty) ...[
                const _SectionTitle('Próximas'),
                const SizedBox(height: 10),
                for (final item in upcoming) ...[
                  _BookingCard(item: item),
                  const SizedBox(height: 10),
                ],
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: 14),
                const _SectionTitle('Anteriores'),
                const SizedBox(height: 10),
                for (final item in past) ...[
                  _BookingCard(item: item),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          ),
        ),
    };
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

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.item});

  final BookingWithCourt item;

  @override
  Widget build(BuildContext context) {
    final dimmed = item.isPast;

    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CourtCover(sport: item.court.sport, width: 64, height: 64, iconSize: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.court.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${item.formattedDate} · ${item.formattedTime}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.court.formattedPrice,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: item.court.sport.color,
                    ),
                  ),
                ],
              ),
            ),
            if (dimmed)
              Text(
                'realizada',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.message, this.onRetry});

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Tentar de novo')),
            ],
          ],
        ),
      ),
    );
  }
}
