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

  test('income reflects surviving mines for each faction', () {
    final state = engine.createInitialState(map);

    expect(state.mineCountFor(Faction.player), 1);
    expect(state.mineCountFor(Faction.enemy), 1);
    expect(state.incomeFor(Faction.player), 3);
    expect(state.incomeFor(Faction.enemy), 3);

    final withoutEnemyMine = state.copyWith(
      buildings: state.buildings
          .where((building) => building.id != 'enemy-mine')
          .toList(growable: false),
    );

    expect(withoutEnemyMine.mineCountFor(Faction.enemy), 0);
    expect(withoutEnemyMine.incomeFor(Faction.enemy), 2);
  });

  test('ready unit count tracks spent units per faction', () {
    final state = engine.createInitialState(map);

    expect(state.unitCountFor(Faction.player), 1);
    expect(state.unitCountFor(Faction.enemy), 1);
    expect(state.readyUnitCountFor(Faction.player), 1);
    expect(state.readyUnitCountFor(Faction.enemy), 1);

    final spentPlayerScout = state.copyWith(
      units: state.units
          .map((unit) => unit.owner == Faction.player
              ? unit.copyWith(hasActed: true)
              : unit)
          .toList(growable: false),
    );

    expect(spentPlayerScout.unitCountFor(Faction.player), 1);
    expect(spentPlayerScout.readyUnitCountFor(Faction.player), 0);
    expect(spentPlayerScout.readyUnitCountFor(Faction.enemy), 1);
  });

  test('headquarters helper ignores destroyed HQs', () {
    final state = engine.createInitialState(map);
    final enemyHq = state.headquartersBuildingFor(Faction.enemy);

    expect(state.headquartersBuildingFor(Faction.player)?.id, 'player-hq');
    expect(enemyHq, isNotNull);
    expect(state.headquartersOf(Faction.enemy), enemyHq?.coord);

    final destroyedEnemyHq = state.copyWith(
      buildings: state.buildings
          .map((building) => building.id == 'enemy-hq'
              ? building.copyWith(health: 0)
              : building)
          .toList(growable: false),
    );

    expect(destroyedEnemyHq.headquartersBuildingFor(Faction.enemy), isNull);
    expect(destroyedEnemyHq.headquartersOf(Faction.enemy), isNull);
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

  test('barracks blockage detects when all deployment hexes are occupied', () {
    final state = engine.createInitialState(map);
    final playerBarracks = state.buildings.firstWhere(
      (building) =>
          building.owner == Faction.player &&
          building.type == BuildingType.barracks,
    );

    expect(state.isBarracksBlocked(Faction.player), isFalse);

    final blockedState = state.copyWith(
      units: [
        ...state.units,
        for (final coord in playerBarracks.coord.neighbors())
          SkirmishUnit(
            id: 'block-${coord.q}-${coord.r}',
            owner: Faction.player,
            type: UnitType.scout,
            coord: coord,
            health: 3,
          ),
      ],
    );

    expect(blockedState.isBarracksBlocked(Faction.player), isTrue);
  });

  test('recruit availability reflects turn, credits, barracks, and blockage', () {
    final state = engine.createInitialState(map);

    expect(state.canRecruitUnit(Faction.player, UnitType.scout), isTrue);
    expect(state.canRecruitUnit(Faction.player, UnitType.tank), isTrue);
    expect(state.canRecruitUnit(Faction.enemy, UnitType.scout), isFalse);

    final lowCredits = state.copyWith(playerCredits: 2);
    expect(lowCredits.canRecruitUnit(Faction.player, UnitType.scout), isFalse);

    final withoutBarracks = state.copyWith(
      buildings: state.buildings
          .where((building) =>
              !(building.owner == Faction.player &&
                  building.type == BuildingType.barracks))
          .toList(growable: false),
    );
    expect(withoutBarracks.canRecruitUnit(Faction.player, UnitType.scout), isFalse);

    final playerBarracks = state.buildings.firstWhere(
      (building) =>
          building.owner == Faction.player &&
          building.type == BuildingType.barracks,
    );
    final blockedState = state.copyWith(
      units: [
        ...state.units,
        for (final coord in playerBarracks.coord.neighbors())
          SkirmishUnit(
            id: 'block-recruit-${coord.q}-${coord.r}',
            owner: Faction.player,
            type: UnitType.scout,
            coord: coord,
            health: 3,
          ),
      ],
    );
    expect(blockedState.canRecruitUnit(Faction.player, UnitType.scout), isFalse);
  });

  test('ending turn returns control to player and advances round', () {
    final state = engine.createInitialState(map);
    final next = engine.endTurn(state, map);

    expect(next.activeFaction, Faction.player);
    expect(next.turn, 2);
  });

  test('end turn reports income gained for both sides', () {
    final state = engine.createInitialState(map);
    final next = engine.endTurn(state, map);

    expect(next.statusMessage, contains('+3 credits collected'));
    expect(next.statusMessage, contains('enemy gained +3'));
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

  test('scouts cannot move through forest as if it were plain terrain', () {
    const passableCorridor = {
      HexCoord(0, 4),
      HexCoord(1, 1),
      HexCoord(2, 1),
      HexCoord(3, 1),
      HexCoord(4, 0),
    };
    final terrainMap = WorldMapData(
      width: 5,
      height: 5,
      seed: 11,
      tiles: {
        for (var q = 0; q < 5; q++)
          for (var r = 0; r < 5; r++)
            HexCoord(q, r): WorldTile(
              coord: HexCoord(q, r),
              biome: q == 2 && r == 1
                  ? TileBiome.forest
                  : passableCorridor.contains(HexCoord(q, r))
                  ? TileBiome.plains
                  : TileBiome.mountain,
              isPassable: passableCorridor.contains(HexCoord(q, r)),
              movementCost: q == 2 && r == 1
                  ? 2
                  : passableCorridor.contains(HexCoord(q, r))
                  ? 1
                  : null,
            ),
      },
    );
    engine.createInitialState(terrainMap);

    final start = SkirmishMatchState(
      playerCredits: 0,
      enemyCredits: 0,
      turn: 1,
      activeFaction: Faction.player,
      selectedUnitId: 'player-scout',
      buildings: const [
        SkirmishBuilding(
          id: 'player-hq',
          owner: Faction.player,
          type: BuildingType.headquarters,
          coord: HexCoord(0, 4),
          health: 10,
        ),
        SkirmishBuilding(
          id: 'enemy-hq',
          owner: Faction.enemy,
          type: BuildingType.headquarters,
          coord: HexCoord(4, 0),
          health: 10,
        ),
      ],
      units: const [
        SkirmishUnit(
          id: 'player-scout',
          owner: Faction.player,
          type: UnitType.scout,
          coord: HexCoord(1, 1),
          health: 3,
        ),
      ],
    );

    final intoForest = engine.moveOrAttackSelectedUnit(start, const HexCoord(2, 1));
    expect(
      intoForest.units.firstWhere((unit) => unit.id == 'player-scout').coord,
      const HexCoord(2, 1),
    );

    final acrossForest = engine.moveOrAttackSelectedUnit(start, const HexCoord(3, 1));
    expect(
      acrossForest.units.firstWhere((unit) => unit.id == 'player-scout').coord,
      const HexCoord(1, 1),
    );
    expect(acrossForest.statusMessage, contains('blocked'));
  });

  test('tanks cannot enter forest with only 1 movement point', () {
    const passableCorridor = {
      HexCoord(0, 4),
      HexCoord(1, 1),
      HexCoord(2, 1),
      HexCoord(4, 0),
    };
    final terrainMap = WorldMapData(
      width: 5,
      height: 5,
      seed: 12,
      tiles: {
        for (var q = 0; q < 5; q++)
          for (var r = 0; r < 5; r++)
            HexCoord(q, r): WorldTile(
              coord: HexCoord(q, r),
              biome: q == 2 && r == 1
                  ? TileBiome.forest
                  : passableCorridor.contains(HexCoord(q, r))
                  ? TileBiome.plains
                  : TileBiome.mountain,
              isPassable: passableCorridor.contains(HexCoord(q, r)),
              movementCost: q == 2 && r == 1
                  ? 2
                  : passableCorridor.contains(HexCoord(q, r))
                  ? 1
                  : null,
            ),
      },
    );
    engine.createInitialState(terrainMap);

    final start = SkirmishMatchState(
      playerCredits: 0,
      enemyCredits: 0,
      turn: 1,
      activeFaction: Faction.player,
      selectedUnitId: 'player-tank',
      buildings: const [
        SkirmishBuilding(
          id: 'player-hq',
          owner: Faction.player,
          type: BuildingType.headquarters,
          coord: HexCoord(0, 4),
          health: 10,
        ),
        SkirmishBuilding(
          id: 'enemy-hq',
          owner: Faction.enemy,
          type: BuildingType.headquarters,
          coord: HexCoord(4, 0),
          health: 10,
        ),
      ],
      units: const [
        SkirmishUnit(
          id: 'player-tank',
          owner: Faction.player,
          type: UnitType.tank,
          coord: HexCoord(1, 1),
          health: 5,
        ),
      ],
    );

    final next = engine.moveOrAttackSelectedUnit(start, const HexCoord(2, 1));

    expect(
      next.units.firstWhere((unit) => unit.id == 'player-tank').coord,
      const HexCoord(1, 1),
    );
    expect(next.statusMessage, contains('blocked'));
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

  test('enemy attacks mine before barracks when HQ is not exposed', () {
    final simpleMap = WorldMapData(
      width: 7,
      height: 7,
      seed: 21,
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
          coord: HexCoord(0, 0),
          health: 10,
        ),
        SkirmishBuilding(
          id: 'player-mine',
          owner: Faction.player,
          type: BuildingType.mine,
          coord: HexCoord(3, 2),
          health: 6,
        ),
        SkirmishBuilding(
          id: 'player-barracks',
          owner: Faction.player,
          type: BuildingType.barracks,
          coord: HexCoord(2, 3),
          health: 3,
        ),
        SkirmishBuilding(
          id: 'enemy-hq',
          owner: Faction.enemy,
          type: BuildingType.headquarters,
          coord: HexCoord(6, 6),
          health: 10,
        ),
      ],
      units: const [
        SkirmishUnit(
          id: 'enemy-scout',
          owner: Faction.enemy,
          type: UnitType.scout,
          coord: HexCoord(2, 2),
          health: 3,
        ),
      ],
    );

    final next = engine.endTurn(start, simpleMap);
    final mine = next.buildings.firstWhere((building) => building.id == 'player-mine');
    final barracks = next.buildings.firstWhere((building) => building.id == 'player-barracks');

    expect(mine.health, 5);
    expect(barracks.health, 3);
  });

  test('enemy movement leans toward mines before barracks when both are viable', () {
    final simpleMap = WorldMapData(
      width: 7,
      height: 7,
      seed: 22,
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
          coord: HexCoord(0, 0),
          health: 10,
        ),
        SkirmishBuilding(
          id: 'player-mine',
          owner: Faction.player,
          type: BuildingType.mine,
          coord: HexCoord(3, 1),
          health: 6,
        ),
        SkirmishBuilding(
          id: 'player-barracks',
          owner: Faction.player,
          type: BuildingType.barracks,
          coord: HexCoord(2, 3),
          health: 7,
        ),
        SkirmishBuilding(
          id: 'enemy-hq',
          owner: Faction.enemy,
          type: BuildingType.headquarters,
          coord: HexCoord(6, 6),
          health: 10,
        ),
      ],
      units: const [
        SkirmishUnit(
          id: 'enemy-scout',
          owner: Faction.enemy,
          type: UnitType.scout,
          coord: HexCoord(4, 2),
          health: 3,
        ),
      ],
    );

    final next = engine.endTurn(start, simpleMap);
    final scout = next.units.firstWhere((unit) => unit.id == 'enemy-scout');

    expect(scout.coord, const HexCoord(4, 1));
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

  test('direct enemy turn setup resolves back to player turn', () {
    final simpleMap = WorldMapData(
      width: 7,
      height: 7,
      seed: 42,
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
      turn: 3,
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

    expect(next.activeFaction, Faction.player);
    expect(next.turn, 4);
    expect(next.statusMessage, contains('Enemy gained +2 credits'));
  });

  test('fresh enemy recruit does not act on the same turn it spawns', () {
    final simpleMap = WorldMapData(
      width: 7,
      height: 7,
      seed: 41,
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
      enemyCredits: 3,
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
      ],
    );

    final next = engine.endTurn(start, simpleMap);
    final recruited = next.units.firstWhere(
      (unit) => unit.id.startsWith('enemy-scout-'),
    );

    expect(recruited.hasActed, isTrue);
  });
}
