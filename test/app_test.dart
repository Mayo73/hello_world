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
    expect(find.textContaining('Seed 101'), findsOneWidget);
    expect(find.text('Income +3'), findsOneWidget);
    expect(find.text('Mines 1'), findsOneWidget);
    expect(find.text('Enemy +3'), findsOneWidget);
    expect(find.text('Enemy mines 1'), findsOneWidget);
    expect(find.textContaining('Tippe auf ein Feld'), findsNothing);
    expect(find.textContaining('Mines raise your income each turn'), findsNothing);

    await tester.tap(find.byKey(const Key('regenerate-button')));
    await tester.pump();

    expect(find.textContaining('Seed 202'), findsOneWidget);
    expect(find.byType(GestureDetector), findsWidgets);
  });

  testWidgets('quick help explains terrain and income rules on demand', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(seedFactory: () => 303));
    await tester.pump();

    expect(find.text('Quick help'), findsNothing);

    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Quick help'), findsOneWidget);
    expect(find.textContaining('Forest tiles cost 2 AP'), findsOneWidget);
    expect(find.textContaining('Mines raise your income each turn'), findsOneWidget);
    expect(find.textContaining('destroy the enemy HQ first'), findsOneWidget);
  });
}
