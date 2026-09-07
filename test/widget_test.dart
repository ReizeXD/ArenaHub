import 'package:flutter_test/flutter_test.dart';
import 'package:arenahub/main.dart';

void main() {
  testWidgets('ArenaHub login page smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ArenaHubApp());

    // Verify that the title and key elements are rendered.
    expect(find.text('ArenaHub'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
  });
}
