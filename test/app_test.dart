import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/main.dart';

void main() {
  testWidgets('app shows game HUD and regenerates with a new seed', (
    WidgetTester tester,
  ) async {
    final seeds = [101, 202].iterator;

    int nextSeed() {
      seeds.moveNext();
      return seeds.current;
    }

    await tester.pumpWidget(MyApp(seedFactory: nextSeed));
    await tester.pump();

    expect(find.text('Hexfront Prototype'), findsOneWidget);
    expect(find.byKey(const Key('seed-text')), findsOneWidget);
    expect(find.textContaining('Seed: 101'), findsOneWidget);
    expect(find.textContaining('Tippe auf ein Feld'), findsNothing);

    await tester.tap(find.byKey(const Key('regenerate-button')));
    await tester.pump();

    expect(find.textContaining('Seed: 202'), findsOneWidget);
    expect(find.byType(GestureDetector), findsWidgets);
  });
}
