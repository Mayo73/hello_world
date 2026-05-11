import 'skirmish/building_type.dart';
import 'skirmish/faction.dart';
import 'skirmish/unit_type.dart';
import 'world/hex_coord.dart';
import 'world/world_tile.dart';

class SelectedTileDetails {
  const SelectedTileDetails({
    required this.coord,
    required this.biomeName,
    required this.movementText,
    required this.passabilityText,
    this.unitOwner,
    this.unitType,
    this.unitHealth,
    this.unitMaxHealth,
    this.unitReady = false,
    this.unitAttack,
    this.unitMoveAp,
    this.buildingOwner,
    this.buildingType,
    this.buildingHealth,
    this.buildingMaxHealth,
    this.buildingEffectText,
    this.buildingIncomeBonus,
    this.buildingSpawnLabel,
  });

  factory SelectedTileDetails.fromTile(
    WorldTile tile, {
    Faction? unitOwner,
    UnitType? unitType,
    int? unitHealth,
    bool unitReady = false,
    Faction? buildingOwner,
    BuildingType? buildingType,
    int? buildingHealth,
  }) {
    return SelectedTileDetails(
      coord: tile.coord,
      biomeName: tile.biome.displayName,
      movementText: tile.isPassable
          ? '${tile.movementCost ?? '-'} AP'
          : 'Unpassierbar',
      passabilityText: tile.isPassable ? 'Passierbar' : 'Blockiert',
      unitOwner: unitOwner,
      unitType: unitType,
      unitHealth: unitHealth,
      unitMaxHealth: unitType?.maxHealth,
      unitReady: unitReady,
      unitAttack: unitType?.attack,
      unitMoveAp: unitType?.movementAp,
      buildingOwner: buildingOwner,
      buildingType: buildingType,
      buildingHealth: buildingHealth,
      buildingMaxHealth: buildingType?.maxHealth,
      buildingEffectText: switch (buildingType) {
        BuildingType.headquarters => 'Critical target',
        BuildingType.mine => 'Economic node',
        BuildingType.barracks => 'Production building',
        null => null,
      },
      buildingIncomeBonus:
          buildingType == BuildingType.mine ? 1 : null,
      buildingSpawnLabel:
          buildingType == BuildingType.barracks ? 'Scout, Tank' : null,
    );
  }

  final HexCoord coord;
  final String biomeName;
  final String movementText;
  final String passabilityText;
  final Faction? unitOwner;
  final UnitType? unitType;
  final int? unitHealth;
  final int? unitMaxHealth;
  final bool unitReady;
  final int? unitAttack;
  final int? unitMoveAp;
  final Faction? buildingOwner;
  final BuildingType? buildingType;
  final int? buildingHealth;
  final int? buildingMaxHealth;
  final String? buildingEffectText;
  final int? buildingIncomeBonus;
  final String? buildingSpawnLabel;

  bool get hasInspectableTarget => unitType != null || buildingType != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SelectedTileDetails &&
        other.coord == coord &&
        other.biomeName == biomeName &&
        other.movementText == movementText &&
        other.passabilityText == passabilityText &&
        other.unitOwner == unitOwner &&
        other.unitType == unitType &&
        other.unitHealth == unitHealth &&
        other.unitMaxHealth == unitMaxHealth &&
        other.unitReady == unitReady &&
        other.unitAttack == unitAttack &&
        other.unitMoveAp == unitMoveAp &&
        other.buildingOwner == buildingOwner &&
        other.buildingType == buildingType &&
        other.buildingHealth == buildingHealth &&
        other.buildingMaxHealth == buildingMaxHealth &&
        other.buildingEffectText == buildingEffectText &&
        other.buildingIncomeBonus == buildingIncomeBonus &&
        other.buildingSpawnLabel == buildingSpawnLabel;
  }

  @override
  int get hashCode => Object.hash(
    coord,
    biomeName,
    movementText,
    passabilityText,
    unitOwner,
    unitType,
    unitHealth,
    unitMaxHealth,
    unitReady,
    unitAttack,
    unitMoveAp,
    buildingOwner,
    buildingType,
    buildingHealth,
    buildingMaxHealth,
    buildingEffectText,
    buildingIncomeBonus,
    buildingSpawnLabel,
  );
}
