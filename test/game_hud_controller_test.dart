import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/game/game_hud_controller.dart';
import 'package:hello_world/game/skirmish/building_type.dart';
import 'package:hello_world/game/skirmish/faction.dart';
import 'package:hello_world/game/skirmish/skirmish_match_state.dart';
import 'package:hello_world/game/skirmish/unit_type.dart';
import 'package:hello_world/game/world/hex_coord.dart';
import 'package:hello_world/game/world/tile_biome.dart';
import 'package:hello_world/game/world/world_tile.dart';

void main() {
  test('setSeed only notifies when the seed changes', () {
    final controller = GameHudController();
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.setSeed(101);
    controller.setSeed(101);
    controller.setSeed(202);

    expect(controller.seed, 202);
    expect(notifications, 2);
  });

  test('clearSelection only notifies when a selection exists', () {
    final controller = GameHudController();
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.clearSelection();

    final tile = WorldTile(
      coord: const HexCoord(2, 3),
      biome: TileBiome.plains,
      isPassable: true,
      movementCost: 1,
    );
    controller.updateSelectedTile(
      tile,
      unitOwner: Faction.player,
      unitType: UnitType.scout,
      unitHealth: 3,
    );
    controller.clearSelection();

    expect(controller.selectedTile, isNull);
    expect(notifications, 2);
  });

  test('updateSelectedTile stores derived unit and building details', () {
    final controller = GameHudController();
    final tile = WorldTile(
      coord: const HexCoord(4, 5),
      biome: TileBiome.forest,
      isPassable: true,
      movementCost: 2,
    );

    controller.updateSelectedTile(
      tile,
      unitOwner: Faction.player,
      unitType: UnitType.scout,
      unitHealth: 2,
      unitReady: true,
      buildingOwner: Faction.player,
      buildingType: BuildingType.mine,
      buildingHealth: 5,
    );

    final selected = controller.selectedTile;
    expect(selected, isNotNull);
    expect(selected?.unitType, UnitType.scout);
    expect(selected?.unitMoveAp, 2);
    expect(selected?.unitAttack, 1);
    expect(selected?.buildingType, BuildingType.mine);
    expect(selected?.buildingIncomeBonus, 1);
    expect(selected?.movementText, '2 AP');
  });

  test('updateMatchState stores the latest skirmish state and only notifies on change', () {
    final controller = GameHudController();
    var notifications = 0;
    controller.addListener(() => notifications++);

    const state = SkirmishMatchState(
      playerCredits: 7,
      enemyCredits: 4,
      turn: 3,
      activeFaction: Faction.enemy,
      units: [],
      buildings: [],
      statusMessage: 'Enemy turn in progress',
    );

    controller.updateMatchState(state);
    controller.updateMatchState(state);

    expect(controller.matchState, same(state));
    expect(notifications, 1);
  });
}
