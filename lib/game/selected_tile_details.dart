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
    this.buildingOwner,
    this.buildingType,
    this.buildingHealth,
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
      buildingOwner: buildingOwner,
      buildingType: buildingType,
      buildingHealth: buildingHealth,
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
  final Faction? buildingOwner;
  final BuildingType? buildingType;
  final int? buildingHealth;
}
