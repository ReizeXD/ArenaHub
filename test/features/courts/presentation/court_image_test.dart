import 'dart:convert';
import 'dart:typed_data';

import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:arenahub/features/courts/presentation/widgets/sport_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const baseCourt = Court(
    id: 'c1',
    name: 'Arena Central',
    sport: Sport.beachTennis,
    address: 'Rua 1',
    pricePerHourInCents: 10000,
  );

  group('CourtImage', () {
    testWidgets('renderiza gradiente com ícone da modalidade quando imageUrl é vazia',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CourtImage(court: baseCourt),
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.sports_tennis_rounded), findsOneWidget);
    });

    testWidgets('renderiza Image.memory quando memoryBytes é fornecido',
        (tester) async {
      // 1x1 PNG transparente válido em bytes
      final transparentPng = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourtImage(
              court: baseCourt,
              memoryBytes: Uint8List.fromList(transparentPng),
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renderiza Image.memory a partir de uma Data URL base64',
        (tester) async {
      final transparentPng = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
      );
      final dataUrl = 'data:image/png;base64,${base64Encode(transparentPng)}';

      final courtWithDataUrl = baseCourt.copyWith(imageUrl: dataUrl);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourtImage(court: courtWithDataUrl),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });
  });
}
