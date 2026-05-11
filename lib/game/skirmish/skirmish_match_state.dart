import '../world/hex_coord.dart';
import 'building_type.dart';
import 'faction.dart';
import 'skirmish_building.dart';
import 'skirmish_unit.dart';

class SkirmishMatchState {
  const SkirmishMatchState({
    required this.playerCredits,
    required this.enemyCredits,
    required this.turn,
    required this.activeFaction,
    required this.units,
    required this.buildings,
    this.selectedUnitId,
    this.winner,
    this.statusMessage,
    this.phaseLabel,
  });

  final int playerCredits;
  final int enemyCredits;
  final int turn;
  final Faction activeFaction;
  final List<SkirmishUnit> units;
  final List<SkirmishBuilding> buildings;
  final String? selectedUnitId;
  final Faction? winner;
  final String? statusMessage;
  final String? phaseLabel;

  bool get isFinished => winner != null;

  SkirmishUnit? get selectedUnit {
    for (final unit in units) {
      if (unit.id == selectedUnitId) return unit;
    }
    return null;
  }

  int creditsFor(Faction faction) =>
      faction == Faction.player ? playerCredits : enemyCredits;

  Iterable<SkirmishBuilding> buildingsFor(Faction faction) =>
      buildings.where((building) => building.owner == faction && !building.isDestroyed);

  Iterable<SkirmishUnit> unitsFor(Faction faction) =>
      units.where((unit) => unit.owner == faction && !unit.isDestroyed);

  int mineCountFor(Faction faction) =>
      buildingsFor(faction)
          .where((building) => building.type == BuildingType.mine)
          .length;

  int incomeFor(Faction faction) => 2 + mineCountFor(faction);

  int readyUnitCountFor(Faction faction) =>
      unitsFor(faction).where((unit) => !unit.hasActed).length;

  bool hasActiveBarracks(Faction faction) =>
      buildingsFor(faction).any((building) => building.type == BuildingType.barracks);

  bool isBarracksBlocked(Faction faction) {
    final barracks = buildingsFor(faction)
        .where((building) => building.type == BuildingType.barracks)
        .firstOrNull;
    if (barracks == null) {
      return false;
    }

    return barracks.coord.neighbors().every(
      (coord) =>
          units.any((unit) => unit.coord == coord && !unit.isDestroyed) ||
          buildings.any(
            (building) => building.coord == coord && !building.isDestroyed,
          ),
    );
  }

  bool canRecruitUnit(Faction faction, UnitType unitType) {
    if (activeFaction != faction || isFinished) {
      return false;
    }

    return hasActiveBarracks(faction) &&
        !isBarracksBlocked(faction) &&
        creditsFor(faction) >= unitType.recruitCost;
  }

  SkirmishMatchState copyWith({
    int? playerCredits,
    int? enemyCredits,
    int? turn,
    Faction? activeFaction,
    List<SkirmishUnit>? units,
    List<SkirmishBuilding>? buildings,
    String? selectedUnitId,
    bool clearSelection = false,
    Faction? winner,
    bool clearWinner = false,
    String? statusMessage,
    String? phaseLabel,
  }) {
    return SkirmishMatchState(
      playerCredits: playerCredits ?? this.playerCredits,
      enemyCredits: enemyCredits ?? this.enemyCredits,
      turn: turn ?? this.turn,
      activeFaction: activeFaction ?? this.activeFaction,
      units: units ?? this.units,
      buildings: buildings ?? this.buildings,
      selectedUnitId: clearSelection ? null : (selectedUnitId ?? this.selectedUnitId),
      winner: clearWinner ? null : (winner ?? this.winner),
      statusMessage: statusMessage ?? this.statusMessage,
      phaseLabel: phaseLabel ?? this.phaseLabel,
    );
  }

  HexCoord? headquartersOf(Faction faction) {
    for (final building in buildings) {
      if (building.owner == faction &&
          building.type == BuildingType.headquarters &&
          !building.isDestroyed) {
        return building.coord;
      }
    }
    return null;
  }
}
