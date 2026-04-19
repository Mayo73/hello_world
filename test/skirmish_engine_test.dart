import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/game/skirmish/faction.dart';
import 'package:hello_world/game/skirmish/skirmish_engine.dart';
import 'package:hello_world/game/skirmish/unit_type.dart';
import 'package:hello_world/game/world/world_gen_config.dart';
import 'package:hello_world/game/world/world_map_generator.dart';

void main() {
  final map = const WorldMapGenerator().generate(
    seed: 4242,
    config: const WorldGenConfig(),
  );
  final engine = const SkirmishEngine();

  test('initial skirmish spawns both factions with HQ, mine, barracks, and units', () {
    final state = engine.createInitialState(map);

    expect(state.buildings.where((b) => b.owner == Faction.player).length, 3);
    expect(state.buildings.where((b) => b.owner == Faction.enemy).length, 3);
    expect(state.units.where((u) => u.owner == Faction.player).length, 1);
    expect(state.units.where((u) => u.owner == Faction.enemy).length, 1);
  });

  test('player can recruit a scout', () {
    final state = engine.createInitialState(map);
    final next = engine.recruitUnit(state, UnitType.scout);

    expect(next.playerCredits, lessThan(state.playerCredits));
    expect(next.units.where((u) => u.owner == Faction.player).length, 2);
  });

  test('ending turn returns control to player and advances round', () {
    final state = engine.createInitialState(map);
    final next = engine.endTurn(state, map);

    expect(next.activeFaction, Faction.player);
    expect(next.turn, 2);
  });
}
