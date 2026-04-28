import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/game/skirmish/building_type.dart';
import 'package:hello_world/game/skirmish/faction.dart';
import 'package:hello_world/game/skirmish/skirmish_building.dart';
import 'package:hello_world/game/skirmish/skirmish_engine.dart';
import 'package:hello_world/game/skirmish/skirmish_match_state.dart';
import 'package:hello_world/game/skirmish/skirmish_unit.dart';
import 'package:hello_world/game/skirmish/unit_type.dart';
import 'package:hello_world/game/world/hex_coord.dart';
import 'package:hello_world/game/world/tile_biome.dart';
import 'package:hello_world/game/world/world_gen_config.dart';
import 'package:hello_world/game/world/world_map_data.dart';
import 'package:hello_world/game/world/world_map_generator.dart';
import 'package:hello_world/game/world/world_tile.dart';

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

  test('player recruitment fails cleanly when barracks is destroyed', () {
    final state = engine.createInitialState(map);
    final withoutBarracks = state.copyWith(
      buildings: state.buildings
          .where((building) =>
              !(building.owner == Faction.player &&
                  building.type == BuildingType.barracks))
          .toList(growable: false),
    );

    final next = engine.recruitUnit(withoutBarracks, UnitType.scout);

    expect(next.units.length, withoutBarracks.units.length);
    expect(next.playerCredits, withoutBarracks.playerCredits);
    expect(next.statusMessage, contains('barracks'));
  });

  test('ending turn returns control to player and advances round', () {
    final state = engine.createInitialState(map);
    final next = engine.endTurn(state, map);

    expect(next.activeFaction, Faction.player);
    expect(next.turn, 2);
  });

  test('enemy scout uses full movement range on open ground', () {
    final simpleMap = WorldMapData(
      width: 7,
      height: 7,
      seed: 1,
      tiles: {
        for (var q = 0; q < 7; q++)
          for (var r = 0; r < 7; r++)
            HexCoord(q, r): WorldTile(
              coord: HexCoord(q, r),
              biome: TileBiome.plains,
              isPassable: true,
              movementCost: 1,
            ),
      },
    );
    engine.createInitialState(simpleMap);

    final start = SkirmishMatchState(
      playerCredits: 0,
      enemyCredits: 0,
      turn: 1,
      activeFaction: Faction.player,
      buildings: const [
        SkirmishBuilding(
          id: 'player-hq',
          owner: Faction.player,
          type: BuildingType.headquarters,
          coord: HexCoord(1, 3),
          health: 10,
        ),
        SkirmishBuilding(
          id: 'enemy-hq',
          owner: Faction.enemy,
          type: BuildingType.headquarters,
          coord: HexCoord(6, 3),
          health: 10,
        ),
      ],
      units: const [
        SkirmishUnit(
          id: 'enemy-scout',
          owner: Faction.enemy,
          type: UnitType.scout,
          coord: HexCoord(5, 3),
          health: 3,
        ),
      ],
    );

    final next = engine.endTurn(start, simpleMap);
    final movedScout = next.units.firstWhere((unit) => unit.id == 'enemy-scout');

    expect(movedScout.coord, const HexCoord(3, 3));
  });

  test('enemy attack prioritizes the weaker adjacent player unit', () {
    final simpleMap = WorldMapData(
      width: 7,
      height: 7,
      seed: 2,
      tiles: {
        for (var q = 0; q < 7; q++)
          for (var r = 0; r < 7; r++)
            HexCoord(q, r): WorldTile(
              coord: HexCoord(q, r),
              biome: TileBiome.plains,
              isPassable: true,
              movementCost: 1,
            ),
      },
    );
    engine.createInitialState(simpleMap);

    final start = SkirmishMatchState(
      playerCredits: 0,
      enemyCredits: 0,
      turn: 1,
      activeFaction: Faction.player,
      buildings: const [
        SkirmishBuilding(
          id: 'player-hq',
          owner: Faction.player,
          type: BuildingType.headquarters,
          coord: HexCoord(1, 3),
          health: 10,
        ),
        SkirmishBuilding(
          id: 'enemy-hq',
          owner: Faction.enemy,
          type: BuildingType.headquarters,
          coord: HexCoord(6, 3),
          health: 10,
        ),
      ],
      units: const [
        SkirmishUnit(
          id: 'enemy-tank',
          owner: Faction.enemy,
          type: UnitType.tank,
          coord: HexCoord(3, 3),
          health: 5,
        ),
        SkirmishUnit(
          id: 'player-healthy',
          owner: Faction.player,
          type: UnitType.scout,
          coord: HexCoord(2, 3),
          health: 3,
        ),
        SkirmishUnit(
          id: 'player-weak',
          owner: Faction.player,
          type: UnitType.scout,
          coord: HexCoord(3, 2),
          health: 1,
        ),
      ],
    );

    final next = engine.endTurn(start, simpleMap);

    expect(next.units.any((unit) => unit.id == 'player-weak'), isFalse);
    expect(next.units.any((unit) => unit.id == 'player-healthy'), isTrue);
  });

  test('enemy recruitment prefers scouts when outnumbered', () {
    final simpleMap = WorldMapData(
      width: 7,
      height: 7,
      seed: 3,
      tiles: {
        for (var q = 0; q < 7; q++)
          for (var r = 0; r < 7; r++)
            HexCoord(q, r): WorldTile(
              coord: HexCoord(q, r),
              biome: TileBiome.plains,
              isPassable: true,
              movementCost: 1,
            ),
      },
    );
    engine.createInitialState(simpleMap);

    final start = SkirmishMatchState(
      playerCredits: 0,
      enemyCredits: 5,
      turn: 1,
      activeFaction: Faction.enemy,
      buildings: const [
        SkirmishBuilding(
          id: 'player-hq',
          owner: Faction.player,
          type: BuildingType.headquarters,
          coord: HexCoord(1, 3),
          health: 10,
        ),
        SkirmishBuilding(
          id: 'enemy-hq',
          owner: Faction.enemy,
          type: BuildingType.headquarters,
          coord: HexCoord(6, 3),
          health: 10,
        ),
        SkirmishBuilding(
          id: 'enemy-barracks',
          owner: Faction.enemy,
          type: BuildingType.barracks,
          coord: HexCoord(5, 4),
          health: 7,
        ),
      ],
      units: const [
        SkirmishUnit(
          id: 'enemy-scout',
          owner: Faction.enemy,
          type: UnitType.scout,
          coord: HexCoord(6, 2),
          health: 3,
        ),
        SkirmishUnit(
          id: 'player-1',
          owner: Faction.player,
          type: UnitType.scout,
          coord: HexCoord(2, 3),
          health: 3,
        ),
        SkirmishUnit(
          id: 'player-2',
          owner: Faction.player,
          type: UnitType.scout,
          coord: HexCoord(2, 4),
          health: 3,
        ),
        SkirmishUnit(
          id: 'player-3',
          owner: Faction.player,
          type: UnitType.scout,
          coord: HexCoord(3, 3),
          health: 3,
        ),
      ],
    );

    final next = engine.endTurn(start, simpleMap);
    final recruited = next.units.where((unit) => unit.owner == Faction.enemy).toList();

    expect(recruited.any((unit) => unit.id.startsWith('enemy-scout-')), isTrue);
    expect(recruited.any((unit) => unit.id.startsWith('enemy-tank-')), isFalse);
  });

  test('enemy recruitment opens with a tank when uncontested', () {
    final simpleMap = WorldMapData(
      width: 7,
      height: 7,
      seed: 4,
      tiles: {
        for (var q = 0; q < 7; q++)
          for (var r = 0; r < 7; r++)
            HexCoord(q, r): WorldTile(
              coord: HexCoord(q, r),
              biome: TileBiome.plains,
              isPassable: true,
              movementCost: 1,
            ),
      },
    );
    engine.createInitialState(simpleMap);

    final start = SkirmishMatchState(
      playerCredits: 0,
      enemyCredits: 5,
      turn: 1,
      activeFaction: Faction.enemy,
      buildings: const [
        SkirmishBuilding(
          id: 'player-hq',
          owner: Faction.player,
          type: BuildingType.headquarters,
          coord: HexCoord(1, 3),
          health: 10,
        ),
        SkirmishBuilding(
          id: 'enemy-hq',
          owner: Faction.enemy,
          type: BuildingType.headquarters,
          coord: HexCoord(6, 3),
          health: 10,
        ),
        SkirmishBuilding(
          id: 'enemy-barracks',
          owner: Faction.enemy,
          type: BuildingType.barracks,
          coord: HexCoord(5, 4),
          health: 7,
        ),
      ],
      units: const [
        SkirmishUnit(
          id: 'enemy-scout',
          owner: Faction.enemy,
          type: UnitType.scout,
          coord: HexCoord(6, 2),
          health: 3,
        ),
        SkirmishUnit(
          id: 'player-1',
          owner: Faction.player,
          type: UnitType.scout,
          coord: HexCoord(1, 2),
          health: 3,
        ),
      ],
    );

    final next = engine.endTurn(start, simpleMap);
    final recruited = next.units.where((unit) => unit.owner == Faction.enemy).toList();

    expect(recruited.any((unit) => unit.id.startsWith('enemy-tank-')), isTrue);
  });
}
