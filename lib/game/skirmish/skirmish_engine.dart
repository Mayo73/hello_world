import '../world/hex_coord.dart';
import '../world/world_map_data.dart';
import 'building_type.dart';
import 'faction.dart';
import 'skirmish_building.dart';
import 'skirmish_match_state.dart';
import 'skirmish_unit.dart';
import 'unit_type.dart';

class SkirmishEngine {
  const SkirmishEngine();

  static const int scoutCost = 3;
  static const int tankCost = 5;
  static WorldMapData? _cachedMap;

  SkirmishMatchState createInitialState(WorldMapData map) {
    _cachedMap = map;
    final spawns = _findSpawnCoords(map);

    return SkirmishMatchState(
      playerCredits: 6,
      enemyCredits: 6,
      turn: 1,
      activeFaction: Faction.player,
      statusMessage: 'Build up, then break the enemy HQ.',
      buildings: [
        SkirmishBuilding(
          id: 'player-hq',
          owner: Faction.player,
          type: BuildingType.headquarters,
          coord: spawns.playerHQ,
          health: 10,
        ),
        SkirmishBuilding(
          id: 'player-mine',
          owner: Faction.player,
          type: BuildingType.mine,
          coord: spawns.playerMine,
          health: 6,
        ),
        SkirmishBuilding(
          id: 'player-barracks',
          owner: Faction.player,
          type: BuildingType.barracks,
          coord: spawns.playerBarracks,
          health: 7,
        ),
        SkirmishBuilding(
          id: 'enemy-hq',
          owner: Faction.enemy,
          type: BuildingType.headquarters,
          coord: spawns.enemyHQ,
          health: 10,
        ),
        SkirmishBuilding(
          id: 'enemy-mine',
          owner: Faction.enemy,
          type: BuildingType.mine,
          coord: spawns.enemyMine,
          health: 6,
        ),
        SkirmishBuilding(
          id: 'enemy-barracks',
          owner: Faction.enemy,
          type: BuildingType.barracks,
          coord: spawns.enemyBarracks,
          health: 7,
        ),
      ],
      units: [
        SkirmishUnit(
          id: 'player-scout-1',
          owner: Faction.player,
          type: UnitType.scout,
          coord: spawns.playerUnit,
          health: UnitType.scout.maxHealth,
        ),
        SkirmishUnit(
          id: 'enemy-scout-1',
          owner: Faction.enemy,
          type: UnitType.scout,
          coord: spawns.enemyUnit,
          health: UnitType.scout.maxHealth,
        ),
      ],
    );
  }

  SkirmishMatchState selectUnit(SkirmishMatchState state, String unitId) {
    final unit = state.units.where((u) => u.id == unitId).firstOrNull;
    if (unit == null || unit.owner != Faction.player || state.activeFaction != Faction.player) {
      return state;
    }
    return state.copyWith(selectedUnitId: unitId, statusMessage: '${unit.type.displayName} selected.');
  }

  SkirmishMatchState clearSelection(SkirmishMatchState state) {
    return state.copyWith(clearSelection: true);
  }

  SkirmishMatchState recruitUnit(SkirmishMatchState state, UnitType type) {
    if (state.activeFaction != Faction.player || state.winner != null) {
      return state;
    }

    final cost = type == UnitType.scout ? scoutCost : tankCost;
    if (state.playerCredits < cost) {
      return state.copyWith(statusMessage: 'Not enough credits for ${type.displayName}.');
    }

    final barracks = state.buildings.firstWhere(
      (building) =>
          building.owner == Faction.player &&
          building.type == BuildingType.barracks &&
          !building.isDestroyed,
    );

    final spawn = _firstFreeAdjacent(
      barracks.coord,
      _cachedMap!,
      mapUnits: state.units,
      mapBuildings: state.buildings,
    );
    if (spawn == null) {
      return state.copyWith(statusMessage: 'Barracks is blocked. Clear adjacent tiles first.');
    }

    final nextId = 'player-${type.name}-${state.units.length + 1}';
    final nextUnits = [...state.units, SkirmishUnit(id: nextId, owner: Faction.player, type: type, coord: spawn, health: type.maxHealth, hasActed: true)];

    return _checkVictory(state.copyWith(
      playerCredits: state.playerCredits - cost,
      units: nextUnits,
      statusMessage: '${type.displayName} deployed near the barracks.',
    ));
  }

  SkirmishMatchState moveOrAttackSelectedUnit(SkirmishMatchState state, HexCoord targetCoord) {
    final unit = state.selectedUnit;
    if (unit == null || unit.owner != Faction.player || unit.hasActed || state.activeFaction != Faction.player) {
      return state;
    }

    if (unit.coord == targetCoord) {
      return state;
    }

    final enemyUnit = state.units.where((other) => other.coord == targetCoord && other.owner != unit.owner && !other.isDestroyed).firstOrNull;
    if (enemyUnit != null && unit.coord.distanceTo(targetCoord) <= 1) {
      final nextUnits = state.units
          .map((candidate) {
            if (candidate.id == enemyUnit.id) {
              return candidate.copyWith(health: candidate.health - unit.attack);
            }
            if (candidate.id == unit.id) {
              return candidate.copyWith(hasActed: true);
            }
            return candidate;
          })
          .where((candidate) => !candidate.isDestroyed)
          .toList(growable: false);

      return _checkVictory(state.copyWith(
        units: nextUnits,
        statusMessage: '${unit.type.displayName} hit enemy ${enemyUnit.type.displayName}.',
      ));
    }

    final enemyBuilding = state.buildings.where((building) => building.coord == targetCoord && building.owner != unit.owner && !building.isDestroyed).firstOrNull;
    if (enemyBuilding != null && unit.coord.distanceTo(targetCoord) <= 1) {
      final nextBuildings = state.buildings
          .map((candidate) => candidate.id == enemyBuilding.id ? candidate.copyWith(health: candidate.health - unit.attack) : candidate)
          .where((candidate) => !candidate.isDestroyed)
          .toList(growable: false);
      final nextUnits = state.units
          .map((candidate) => candidate.id == unit.id ? candidate.copyWith(hasActed: true) : candidate)
          .toList(growable: false);

      return _checkVictory(state.copyWith(
        buildings: nextBuildings,
        units: nextUnits,
        statusMessage: '${unit.type.displayName} damaged ${enemyBuilding.type.displayName}.',
      ));
    }

    final reachableTiles = _reachableCoords(
      unit,
      _cachedMap!,
      units: state.units,
      buildings: state.buildings,
    );
    if (!reachableTiles.contains(targetCoord)) {
      return state.copyWith(statusMessage: 'That move is blocked or out of range.');
    }

    final nextUnits = state.units
        .map((candidate) => candidate.id == unit.id ? candidate.copyWith(coord: targetCoord, hasActed: true) : candidate)
        .toList(growable: false);

    return state.copyWith(units: nextUnits, statusMessage: '${unit.type.displayName} advanced to $targetCoord.');
  }

  SkirmishMatchState endTurn(SkirmishMatchState state, WorldMapData map) {
    if (state.winner != null) {
      return state;
    }

    if (state.activeFaction == Faction.player) {
      final prepared = state.copyWith(
        activeFaction: Faction.enemy,
        clearSelection: true,
        playerCredits: state.playerCredits + _incomeFor(state, Faction.player),
        units: state.units.map((unit) => unit.owner == Faction.enemy ? unit.copyWith(hasActed: false) : unit).toList(growable: false),
        statusMessage: 'Enemy turn...',
      );
      final afterAi = _runEnemyTurn(prepared, map);
      return _checkVictory(afterAi.copyWith(
        activeFaction: Faction.player,
        turn: prepared.turn + 1,
        enemyCredits: afterAi.enemyCredits + _incomeFor(afterAi, Faction.enemy),
        units: afterAi.units.map((unit) => unit.owner == Faction.player ? unit.copyWith(hasActed: false) : unit).toList(growable: false),
        statusMessage: afterAi.winner == null ? 'Your turn. Build pressure and break the HQ.' : afterAi.statusMessage,
      ));
    }

    return state;
  }

  int _incomeFor(SkirmishMatchState state, Faction faction) {
    final mines = state.buildings.where((building) => building.owner == faction && building.type == BuildingType.mine && !building.isDestroyed).length;
    return 2 + mines;
  }

  SkirmishMatchState _runEnemyTurn(SkirmishMatchState state, WorldMapData map) {
    var current = state;

    current = _enemyRecruit(current);

    final orderedUnits = current.units.where((unit) => unit.owner == Faction.enemy && !unit.isDestroyed).toList(growable: false);
    for (final unit in orderedUnits) {
      final refreshed = current.units.where((candidate) => candidate.id == unit.id).firstOrNull;
      if (refreshed == null || refreshed.hasActed) {
        continue;
      }
      current = _enemyActWithUnit(current, refreshed, map);
    }

    return current;
  }

  SkirmishMatchState _enemyRecruit(SkirmishMatchState state) {
    final barracks = state.buildings.where((building) => building.owner == Faction.enemy && building.type == BuildingType.barracks && !building.isDestroyed).firstOrNull;
    if (barracks == null) {
      return state;
    }

    final spawn = _firstFreeAdjacent(
      barracks.coord,
      _cachedMap!,
      mapUnits: state.units,
      mapBuildings: state.buildings,
    );
    if (spawn == null) {
      return state;
    }

    final nextType = state.enemyCredits >= tankCost ? UnitType.tank : (state.enemyCredits >= scoutCost ? UnitType.scout : null);
    if (nextType == null) {
      return state;
    }

    final cost = nextType == UnitType.tank ? tankCost : scoutCost;
    final nextId = 'enemy-${nextType.name}-${state.units.length + 1}';
    return state.copyWith(
      enemyCredits: state.enemyCredits - cost,
      units: [...state.units, SkirmishUnit(id: nextId, owner: Faction.enemy, type: nextType, coord: spawn, health: nextType.maxHealth)],
      statusMessage: 'Enemy reinforced ${nextType.displayName.toLowerCase()}s.',
    );
  }

  SkirmishMatchState _enemyActWithUnit(SkirmishMatchState state, SkirmishUnit unit, WorldMapData map) {
    final playerHq = state.headquartersOf(Faction.player);
    if (playerHq == null) return state.copyWith(winner: Faction.enemy, statusMessage: 'Raider AI overran your command.');

    final adjacentTargets = <HexCoord>[...unit.coord.neighbors()];
    for (final coord in adjacentTargets) {
      final playerUnit = state.units.where((candidate) => candidate.coord == coord && candidate.owner == Faction.player && !candidate.isDestroyed).firstOrNull;
      if (playerUnit != null) {
        final nextUnits = state.units
            .map((candidate) {
              if (candidate.id == playerUnit.id) return candidate.copyWith(health: candidate.health - unit.attack);
              if (candidate.id == unit.id) return candidate.copyWith(hasActed: true);
              return candidate;
            })
            .where((candidate) => !candidate.isDestroyed)
            .toList(growable: false);
        return _checkVictory(state.copyWith(units: nextUnits, statusMessage: 'Enemy ${unit.type.displayName.toLowerCase()} struck your line.'));
      }

      final playerBuilding = state.buildings.where((candidate) => candidate.coord == coord && candidate.owner == Faction.player && !candidate.isDestroyed).firstOrNull;
      if (playerBuilding != null) {
        final nextBuildings = state.buildings
            .map((candidate) => candidate.id == playerBuilding.id ? candidate.copyWith(health: candidate.health - unit.attack) : candidate)
            .where((candidate) => !candidate.isDestroyed)
            .toList(growable: false);
        final nextUnits = state.units
            .map((candidate) => candidate.id == unit.id ? candidate.copyWith(hasActed: true) : candidate)
            .toList(growable: false);
        return _checkVictory(state.copyWith(buildings: nextBuildings, units: nextUnits, statusMessage: 'Enemy ${unit.type.displayName.toLowerCase()} hit your ${playerBuilding.type.displayName}.'));
      }
    }

    final moveOptions = unit.coord
        .neighbors()
        .where((coord) => map.contains(coord))
        .where((coord) => (map.tileAt(coord)?.isPassable ?? false))
        .where((coord) => !_isOccupied(coord, units: state.units, buildings: state.buildings))
        .toList(growable: false);
    if (moveOptions.isEmpty) {
      return state.copyWith(units: state.units.map((candidate) => candidate.id == unit.id ? candidate.copyWith(hasActed: true) : candidate).toList(growable: false));
    }

    moveOptions.sort((a, b) => a.distanceTo(playerHq).compareTo(b.distanceTo(playerHq)));
    final destination = moveOptions.first;
    return state.copyWith(
      units: state.units.map((candidate) => candidate.id == unit.id ? candidate.copyWith(coord: destination, hasActed: true) : candidate).toList(growable: false),
      statusMessage: 'Enemy ${unit.type.displayName.toLowerCase()} is pushing forward.',
    );
  }

  SkirmishMatchState _checkVictory(SkirmishMatchState state) {
    final playerHqAlive = state.buildings.any((building) => building.owner == Faction.player && building.type == BuildingType.headquarters && !building.isDestroyed);
    final enemyHqAlive = state.buildings.any((building) => building.owner == Faction.enemy && building.type == BuildingType.headquarters && !building.isDestroyed);

    if (!enemyHqAlive) {
      return state.copyWith(winner: Faction.player, statusMessage: 'Victory. Enemy HQ destroyed.');
    }
    if (!playerHqAlive) {
      return state.copyWith(winner: Faction.enemy, statusMessage: 'Defeat. Your HQ has fallen.');
    }
    return state;
  }

  Set<HexCoord> _reachableCoords(
    SkirmishUnit unit,
    WorldMapData map, {
    required List<SkirmishUnit> units,
    required List<SkirmishBuilding> buildings,
  }) {
    final visited = <HexCoord>{unit.coord};
    final frontier = <({HexCoord coord, int steps})>[(coord: unit.coord, steps: 0)];
    final reachable = <HexCoord>{};

    while (frontier.isNotEmpty) {
      final current = frontier.removeAt(0);
      if (current.steps >= unit.movementRange) {
        continue;
      }

      for (final neighbor in current.coord.neighbors()) {
        if (!map.contains(neighbor) || visited.contains(neighbor)) {
          continue;
        }
        visited.add(neighbor);

        if (!(map.tileAt(neighbor)?.isPassable ?? false) ||
            _isOccupied(neighbor, units: units, buildings: buildings)) {
          continue;
        }

        reachable.add(neighbor);
        frontier.add((coord: neighbor, steps: current.steps + 1));
      }
    }

    return reachable;
  }

  bool _isOccupied(HexCoord coord, {required List<SkirmishUnit> units, required List<SkirmishBuilding> buildings}) {
    return units.any((unit) => unit.coord == coord && !unit.isDestroyed) || buildings.any((building) => building.coord == coord && !building.isDestroyed);
  }

  HexCoord? _firstFreeAdjacent(
    HexCoord origin,
    WorldMapData map, {
    required List<SkirmishUnit> mapUnits,
    required List<SkirmishBuilding> mapBuildings,
  }) {
    for (final coord in origin.neighbors()) {
      if (map.contains(coord) &&
          (map.tileAt(coord)?.isPassable ?? false) &&
          !_isOccupied(coord, units: mapUnits, buildings: mapBuildings)) {
        return coord;
      }
    }
    return null;
  }

  _SpawnCoords _findSpawnCoords(WorldMapData map) {
    final passable = map.tiles.where((tile) => tile.isPassable).toList(growable: false)
      ..sort((a, b) => a.coord.q == b.coord.q ? a.coord.r.compareTo(b.coord.r) : a.coord.q.compareTo(b.coord.q));

    final playerHQ = passable.firstWhere((tile) => tile.coord.q < map.width ~/ 3 && tile.coord.r > map.height ~/ 3).coord;
    final enemyHQ = passable.lastWhere((tile) => tile.coord.q > (map.width * 2) ~/ 3 && tile.coord.r < (map.height * 2) ~/ 3).coord;

    final playerMine = _findNearbyPassable(
      map,
      playerHQ,
      avoid: {playerHQ},
      preferFarther: false,
    );
    final playerBarracks = _findNearbyPassable(
      map,
      playerHQ,
      avoid: {playerHQ, playerMine},
      preferFarther: true,
    );
    final playerUnit = _findNearbyPassable(
      map,
      playerHQ,
      avoid: {playerHQ, playerMine, playerBarracks},
      preferFarther: true,
    );
    final enemyMine = _findNearbyPassable(
      map,
      enemyHQ,
      avoid: {enemyHQ},
      preferFarther: false,
    );
    final enemyBarracks = _findNearbyPassable(
      map,
      enemyHQ,
      avoid: {enemyHQ, enemyMine},
      preferFarther: true,
    );
    final enemyUnit = _findNearbyPassable(
      map,
      enemyHQ,
      avoid: {enemyHQ, enemyMine, enemyBarracks},
      preferFarther: true,
    );

    return _SpawnCoords(
      playerHQ: playerHQ,
      playerMine: playerMine,
      playerBarracks: playerBarracks,
      playerUnit: playerUnit,
      enemyHQ: enemyHQ,
      enemyMine: enemyMine,
      enemyBarracks: enemyBarracks,
      enemyUnit: enemyUnit,
    );
  }

  HexCoord _findNearbyPassable(
    WorldMapData map,
    HexCoord anchor, {
    required Set<HexCoord> avoid,
    required bool preferFarther,
  }) {
    final blocked = {...avoid};
    final candidates = map.tiles
        .where((tile) => tile.isPassable && !blocked.contains(tile.coord))
        .toList(growable: false);
    candidates.sort((a, b) {
      final da = a.coord.distanceTo(anchor);
      final db = b.coord.distanceTo(anchor);
      return preferFarther ? db.compareTo(da) : da.compareTo(db);
    });
    return candidates.first.coord;
  }
}

class _SpawnCoords {
  const _SpawnCoords({
    required this.playerHQ,
    required this.playerMine,
    required this.playerBarracks,
    required this.playerUnit,
    required this.enemyHQ,
    required this.enemyMine,
    required this.enemyBarracks,
    required this.enemyUnit,
  });

  final HexCoord playerHQ;
  final HexCoord playerMine;
  final HexCoord playerBarracks;
  final HexCoord playerUnit;
  final HexCoord enemyHQ;
  final HexCoord enemyMine;
  final HexCoord enemyBarracks;
  final HexCoord enemyUnit;
}
