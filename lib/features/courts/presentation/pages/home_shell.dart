import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'courts_page.dart';
import 'my_bookings_page.dart';

/// Moldura de quem está logado: cabeçalho, abas e a navegação entre elas.
///
/// Usa `IndexedStack` para que trocar de aba não descarte o estado da outra —
/// a lista de quadras não recarrega toda vez que se volta para ela.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.session});

  final AuthSession session;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final GlobalKey<MyBookingsPageState> _bookingsKey =
      GlobalKey<MyBookingsPageState>();

  int _index = 0;

  static const List<String> _subtitles = [
    'Escolha uma quadra para reservar',
    'Seus horários reservados',
  ];

  void _onTabSelected(int index) {
    setState(() => _index = index);

    // Ao voltar para as reservas, recarrega: pode ter sido feita uma reserva
    // na outra aba desde a última vez.
    if (index == 1) _bookingsKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Olá, ${widget.session.user.firstName}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              _subtitles[_index],
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout_rounded, color: Colors.black54),
            onPressed: () => context.read<AuthController>().signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            const CourtsPage(),
            MyBookingsPage(key: _bookingsKey, session: widget.session),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTabSelected,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF10B981).withValues(alpha: 0.14),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined),
            selectedIcon: Icon(Icons.sports_soccer_rounded),
            label: 'Quadras',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note_rounded),
            label: 'Reservas',
          ),
        ],
      ),
    );
  }
}
