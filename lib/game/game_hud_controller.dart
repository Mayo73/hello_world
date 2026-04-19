import 'package:flutter/foundation.dart';

import 'selected_tile_details.dart';
import 'skirmish/building_type.dart';
import 'skirmish/faction.dart';
import 'skirmish/skirmish_match_state.dart';
import 'skirmish/unit_type.dart';
import 'world/world_tile.dart';

class GameHudController extends ChangeNotifier {
  int _seed = 0;
  SelectedTileDetails? _selectedTile;
  SkirmishMatchState? _matchState;

  int get seed => _seed;
  SelectedTileDetails? get selectedTile => _selectedTile;
  SkirmishMatchState? get matchState => _matchState;

  void setSeed(int seed) {
    if (_seed == seed) {
      return;
    }

    _seed = seed;
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedTile == null) {
      return;
    }

    _selectedTile = null;
    notifyListeners();
  }

  void updateSelectedTile(
    WorldTile tile, {
    Faction? unitOwner,
    UnitType? unitType,
    int? unitHealth,
    bool unitReady = false,
    Faction? buildingOwner,
    BuildingType? buildingType,
    int? buildingHealth,
  }) {
    _selectedTile = SelectedTileDetails.fromTile(
      tile,
      unitOwner: unitOwner,
      unitType: unitType,
      unitHealth: unitHealth,
      unitReady: unitReady,
      buildingOwner: buildingOwner,
      buildingType: buildingType,
      buildingHealth: buildingHealth,
    );
    notifyListeners();
  }

  void updateMatchState(SkirmishMatchState state) {
    _matchState = state;
    notifyListeners();
  }
}
