import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/game/selected_tile_details.dart';
import 'package:hello_world/game/skirmish/building_type.dart';
import 'package:hello_world/game/skirmish/faction.dart';
import 'package:hello_world/game/world/hex_coord.dart';
import 'package:hello_world/game/world/tile_biome.dart';
import 'package:hello_world/game/world/world_tile.dart';

void main() {
  test('fromTile marks impassable terrain as blocked and unpassable', () {
    final tile = WorldTile(
      coord: const HexCoord(7, 4),
      biome: TileBiome.mountain,
      isPassable: false,
      movementCost: null,
    );

    final details = SelectedTileDetails.fromTile(tile);

    expect(details.coord, const HexCoord(7, 4));
    expect(details.biomeName, TileBiome.mountain.displayName);
    expect(details.movementText, 'Unpassierbar');
    expect(details.passabilityText, 'Blockiert');
    expect(details.hasInspectableTarget, isFalse);
  });

  test('fromTile derives headquarters inspection details', () {
    final tile = WorldTile(
      coord: const HexCoord(1, 1),
      biome: TileBiome.plains,
      isPassable: true,
      movementCost: 1,
    );

    final details = SelectedTileDetails.fromTile(
      tile,
      buildingOwner: Faction.player,
      buildingType: BuildingType.headquarters,
      buildingHealth: 8,
    );

    expect(details.hasInspectableTarget, isTrue);
    expect(details.buildingType, BuildingType.headquarters);
    expect(details.buildingHealth, 8);
    expect(details.buildingMaxHealth, 10);
    expect(details.buildingEffectText, 'Critical target');
    expect(details.buildingIncomeBonus, isNull);
    expect(details.buildingSpawnLabel, isNull);
    expect(details.movementText, '1 AP');
    expect(details.passabilityText, 'Passierbar');
  });

  test('fromTile derives tank combat details', () {
    final tile = WorldTile(
      coord: const HexCoord(5, 2),
      biome: TileBiome.forest,
      isPassable: true,
      movementCost: 2,
    );

    final details = SelectedTileDetails.fromTile(
      tile,
      unitOwner: Faction.enemy,
      unitType: UnitType.tank,
      unitHealth: 4,
      unitReady: false,
    );

    expect(details.hasInspectableTarget, isTrue);
    expect(details.unitOwner, Faction.enemy);
    expect(details.unitType, UnitType.tank);
    expect(details.unitHealth, 4);
    expect(details.unitMaxHealth, 5);
    expect(details.unitReady, isFalse);
    expect(details.unitAttack, 2);
    expect(details.unitMoveAp, 1);
    expect(details.buildingType, isNull);
    expect(details.movementText, '2 AP');
    expect(details.passabilityText, 'Passierbar');
  });
}
