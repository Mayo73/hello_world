import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/main.dart';

Future<void> _tapGameHex(
  WidgetTester tester,
  Offset position,
) async {
  final gesture = await tester.startGesture(position);
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

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

  testWidgets('selected unit panel shows combat and movement stats', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(seedFactory: () => 101));
    await tester.pump();

    final gameArea = find.byKey(const Key('game-gesture-layer'));
    final gameRect = tester.getRect(gameArea);
    await _tapGameHex(
      tester,
      Offset(gameRect.center.dx - 85, gameRect.center.dy + 45),
    );

    expect(find.textContaining('Commander Scout'), findsOneWidget);
    expect(find.text('Move 2 AP'), findsOneWidget);
    expect(find.text('ATK 1'), findsOneWidget);
  });

  testWidgets('selected building panel shows structure effects', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(seedFactory: () => 101));
    await tester.pump();

    final gameArea = find.byKey(const Key('game-gesture-layer'));
    final gameRect = tester.getRect(gameArea);
    await _tapGameHex(
      tester,
      Offset(gameRect.center.dx - 36, gameRect.center.dy + 44),
    );

    expect(find.textContaining('Commander Mine'), findsOneWidget);
    expect(find.text('Economic node'), findsOneWidget);
    expect(find.text('Income +1'), findsOneWidget);
  });

  testWidgets('selected barracks panel shows production effect', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(seedFactory: () => 101));
    await tester.pump();

    final gameArea = find.byKey(const Key('game-gesture-layer'));
    final gameRect = tester.getRect(gameArea);
    await _tapGameHex(
      tester,
      Offset(gameRect.center.dx - 109, gameRect.center.dy + 94),
    );

    expect(find.textContaining('Commander Barracks'), findsOneWidget);
    expect(find.text('Production building'), findsOneWidget);
    expect(find.text('Deploys Scout, Tank'), findsOneWidget);
  });
}
