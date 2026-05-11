import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/game/selected_tile_details.dart';
import 'package:hello_world/game/skirmish/building_type.dart';
import 'package:hello_world/game/skirmish/faction.dart';
import 'package:hello_world/game/skirmish/unit_type.dart';
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
    expect(details.buildingMaxHealth, BuildingType.headquarters.maxHealth);
    expect(details.buildingEffectText, BuildingType.headquarters.effectText);
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
    expect(details.unitMoveAp, UnitType.tank.movementAp);
    expect(details.buildingType, isNull);
    expect(details.movementText, '2 AP');
    expect(details.passabilityText, 'Passierbar');
  });

  test('fromTile derives scout movement from centralized unit rule', () {
    final tile = WorldTile(
      coord: const HexCoord(3, 6),
      biome: TileBiome.plains,
      isPassable: true,
      movementCost: 1,
    );

    final details = SelectedTileDetails.fromTile(
      tile,
      unitOwner: Faction.player,
      unitType: UnitType.scout,
      unitHealth: 3,
      unitReady: true,
    );

    expect(details.unitType, UnitType.scout);
    expect(details.unitAttack, UnitType.scout.attack);
    expect(details.unitMaxHealth, UnitType.scout.maxHealth);
    expect(details.unitMoveAp, UnitType.scout.movementAp);
    expect(details.unitReady, isTrue);
  });

  test('fromTile derives mine and barracks building descriptors from building type', () {
    final mineTile = WorldTile(
      coord: const HexCoord(2, 2),
      biome: TileBiome.plains,
      isPassable: true,
      movementCost: 1,
    );
    final barracksTile = WorldTile(
      coord: const HexCoord(4, 4),
      biome: TileBiome.plains,
      isPassable: true,
      movementCost: 1,
    );

    final mineDetails = SelectedTileDetails.fromTile(
      mineTile,
      buildingOwner: Faction.player,
      buildingType: BuildingType.mine,
      buildingHealth: 6,
    );
    final barracksDetails = SelectedTileDetails.fromTile(
      barracksTile,
      buildingOwner: Faction.player,
      buildingType: BuildingType.barracks,
      buildingHealth: 7,
    );

    expect(mineDetails.buildingEffectText, BuildingType.mine.effectText);
    expect(mineDetails.buildingIncomeBonus, BuildingType.mine.incomeBonus);
    expect(mineDetails.buildingSpawnLabel, isNull);
    expect(barracksDetails.buildingEffectText, BuildingType.barracks.effectText);
    expect(barracksDetails.buildingIncomeBonus, isNull);
    expect(barracksDetails.buildingSpawnLabel, BuildingType.barracks.spawnLabel);
  });

  test('value equality reflects derived tile details', () {
    final tile = WorldTile(
      coord: const HexCoord(5, 2),
      biome: TileBiome.forest,
      isPassable: true,
      movementCost: 2,
    );

    final first = SelectedTileDetails.fromTile(
      tile,
      unitOwner: Faction.enemy,
      unitType: UnitType.tank,
      unitHealth: 4,
      unitReady: false,
    );
    final second = SelectedTileDetails.fromTile(
      tile,
      unitOwner: Faction.enemy,
      unitType: UnitType.tank,
      unitHealth: 4,
      unitReady: false,
    );
    final changed = SelectedTileDetails.fromTile(
      tile,
      unitOwner: Faction.enemy,
      unitType: UnitType.tank,
      unitHealth: 3,
      unitReady: false,
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first, isNot(changed));
  });
}
