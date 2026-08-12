// Smoke test — vérifie que l'app démarre et affiche l'écran Splash sans
// planter. Le splash lance un appel réseau (tryAutoLogin) : on se contente
// d'un `pump()` simple pour ne pas attendre cet appel dans le test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cityflow_app/main.dart';

void main() {
  testWidgets('CityFlowApp démarre sur l\'écran Splash', (WidgetTester tester) async {
    await tester.pumpWidget(const CityFlowApp());
    await tester.pump();

    expect(find.text('CityFlow '), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
  });
}
