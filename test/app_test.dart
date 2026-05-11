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
    expect(find.text('Scout 3'), findsOneWidget);
    expect(find.text('Tank 5'), findsOneWidget);
    expect(find.text('End turn'), findsOneWidget);
    expect(find.text('No ready units, end turn'), findsNothing);
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

  testWidgets('recruit buttons reflect reduced credits after deployment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(seedFactory: () => 101));
    await tester.pump();

    await tester.tap(find.text('Tank 5'));
    await tester.pump();

    expect(find.text('Credits 1'), findsOneWidget);
    expect(find.text('Scout needs 3'), findsOneWidget);
    expect(find.text('Tank needs 5'), findsOneWidget);
    expect(find.textContaining('Tank deployed near the barracks.'), findsOneWidget);
  });

  testWidgets('end turn switches battle bar to enemy-turn messaging', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(seedFactory: () => 101));
    await tester.pump();

    await tester.tap(find.text('End turn'));
    await tester.pump();

    expect(find.text('Enemy turn'), findsOneWidget);
    expect(find.text('Scout blocked'), findsOneWidget);
    expect(find.text('Tank blocked'), findsOneWidget);
    expect(find.textContaining('enemy gained +3'), findsOneWidget);
    expect(find.text('End turn'), findsOneWidget);
  });

  testWidgets('spending the only ready unit highlights end turn', (
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
    await _tapGameHex(
      tester,
      Offset(gameRect.center.dx - 33, gameRect.center.dy + 47),
    );

    expect(find.text('Ready 0'), findsOneWidget);
    expect(find.text('No ready units, end turn'), findsOneWidget);
    expect(find.text('End turn now'), findsOneWidget);
    expect(find.textContaining('Commander Scout moved.'), findsOneWidget);
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
    expect(find.text('HP 3/3'), findsOneWidget);
    expect(find.text('Move 2 AP'), findsOneWidget);
    expect(find.text('ATK 1'), findsOneWidget);
    expect(
      find.textContaining('Fast skirmisher. Best for flanks'),
      findsOneWidget,
    );
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
    expect(find.text('HP 6/6'), findsOneWidget);
    expect(find.text('Economic node'), findsOneWidget);
    expect(find.text('Income +1'), findsOneWidget);
    expect(
      find.textContaining('Each surviving mine adds +1 income every turn'),
      findsOneWidget,
    );
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
    expect(find.text('HP 7/7'), findsOneWidget);
    expect(find.text('Production building'), findsOneWidget);
    expect(find.text('Deploys Scout, Tank'), findsOneWidget);
    expect(
      find.textContaining('New scouts and tanks deploy on adjacent free tiles'),
      findsOneWidget,
    );
  });

  testWidgets('selected HQ panel shows critical target effect', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(seedFactory: () => 101));
    await tester.pump();

    final gameArea = find.byKey(const Key('game-gesture-layer'));
    final gameRect = tester.getRect(gameArea);
    await _tapGameHex(
      tester,
      Offset(gameRect.center.dx - 88, gameRect.center.dy - 8),
    );

    expect(find.textContaining('Commander HQ'), findsOneWidget);
    expect(find.text('HP 10/10'), findsOneWidget);
    expect(find.text('Critical target'), findsOneWidget);
    expect(
      find.textContaining('Protect it while opening a path to the enemy HQ'),
      findsOneWidget,
    );
  });
}
