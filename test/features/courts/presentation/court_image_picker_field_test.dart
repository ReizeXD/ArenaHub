import 'dart:convert';
import 'dart:typed_data';

import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:arenahub/features/courts/presentation/widgets/court_image_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final transparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
  );

  group('CourtImagePickerField (#41)', () {
    testWidgets('exibe placeholder com convite quando não há foto',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourtImagePickerField(
              sport: Sport.futsal,
              onImagePicked: (bytes, mime) {},
            ),
          ),
        ),
      );

      expect(find.text('Adicionar foto da quadra'), findsOneWidget);
      expect(find.text('Câmera ou galeria (PNG/JPG)'), findsOneWidget);
      expect(find.byIcon(Icons.add_a_photo_rounded), findsOneWidget);
      expect(find.text('Trocar foto'), findsNothing);
    });

    testWidgets('ao tocar no campo, abre modal com opções Câmera e Galeria',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourtImagePickerField(
              sport: Sport.society,
              onImagePicked: (bytes, mime) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Adicionar foto da quadra'));
      await tester.pumpAndSettle();

      expect(find.text('Foto da Quadra'), findsOneWidget);
      expect(find.text('Tirar Foto com a Câmera'), findsOneWidget);
      expect(find.text('Escolher da Galeria'), findsOneWidget);
      expect(find.text('Remover Foto'), findsNothing);
    });

    testWidgets('exibe badge Trocar foto quando initialBytes for fornecido',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourtImagePickerField(
              sport: Sport.beachTennis,
              initialBytes: Uint8List.fromList(transparentPng),
              onImagePicked: (bytes, mime) {},
            ),
          ),
        ),
      );

      expect(find.text('Trocar foto'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('com foto ativa, modal exibe opção Remover Foto e dispara callback com null',
        (tester) async {
      Uint8List? pickedBytes = Uint8List.fromList(transparentPng);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourtImagePickerField(
              sport: Sport.volleyball,
              initialBytes: pickedBytes,
              onImagePicked: (bytes, _) {
                pickedBytes = bytes;
              },
            ),
          ),
        ),
      );

      // Abre o modal de opções
      await tester.tap(find.byType(CourtImagePickerField));
      await tester.pumpAndSettle();

      expect(find.text('Remover Foto'), findsOneWidget);

      // Clica em remover
      await tester.tap(find.text('Remover Foto'));
      await tester.pumpAndSettle();

      expect(pickedBytes, isNull);
      expect(find.text('Adicionar foto da quadra'), findsOneWidget);
    });
  });
}
