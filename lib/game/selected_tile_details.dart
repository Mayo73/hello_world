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
    this.unitReady = false,
    this.unitAttack,
    this.unitMoveAp,
    this.buildingOwner,
    this.buildingType,
    this.buildingHealth,
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
      unitReady: unitReady,
      unitAttack: unitType?.attack,
      unitMoveAp: unitType == null ? null : (unitType == UnitType.scout ? 2 : 1),
      buildingOwner: buildingOwner,
      buildingType: buildingType,
      buildingHealth: buildingHealth,
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
  final bool unitReady;
  final int? unitAttack;
  final int? unitMoveAp;
  final Faction? buildingOwner;
  final BuildingType? buildingType;
  final int? buildingHealth;
  final String? buildingEffectText;
  final int? buildingIncomeBonus;
  final String? buildingSpawnLabel;

  bool get hasInspectableTarget => unitType != null || buildingType != null;
}
