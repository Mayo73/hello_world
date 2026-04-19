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
