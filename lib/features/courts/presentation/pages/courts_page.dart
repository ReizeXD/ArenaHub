import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/court.dart';
import '../controllers/courts_controller.dart';
import '../states/courts_state.dart';
import '../widgets/sport_visuals.dart';
import 'court_detail_page.dart';

/// Aba de quadras disponíveis.
///
/// Sem `Scaffold` nem `AppBar`: quem monta a moldura é a `HomeShell`, para
/// que as duas abas dividam o cabeçalho e a navegação.
class CourtsPage extends StatefulWidget {
  const CourtsPage({super.key});

  @override
  State<CourtsPage> createState() => _CourtsPageState();
}

class _CourtsPageState extends State<CourtsPage> {
  @override
  void initState() {
    super.initState();
    // Depois do primeiro frame: o controller notifica ouvintes, e emitir
    // durante o build da árvore dispararia erro do Flutter.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<CourtsController>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CourtsController>().state;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: switch (state) {
          CourtsLoading() => const Center(child: CircularProgressIndicator()),
          CourtsFailed(:final failure) => _ErrorView(
              message: failure.message,
              onRetry: () => context.read<CourtsController>().load(),
            ),
          CourtsLoaded(:final courts) when courts.isEmpty =>
            const _ErrorView(message: 'Nenhuma quadra cadastrada ainda.'),
          CourtsLoaded(:final courts) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: courts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) => _CourtCard(court: courts[index]),
            ),
        },
      ),
    );
  }
}

class _CourtCard extends StatelessWidget {
  const _CourtCard({required this.court});

  final Court court;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CourtDetailPage(court: court),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CourtCover(sport: court.sport),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      court.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      court.sport.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: court.sport.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      court.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          court.formattedPrice,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          ' / hora',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});

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
            Icon(Icons.sports_soccer_outlined, size: 48, color: Colors.grey[400]),
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
