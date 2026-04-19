import 'package:flutter/foundation.dart';

import 'selected_tile_details.dart';
import 'world/world_tile.dart';

class GameHudController extends ChangeNotifier {
  int _seed = 0;
  SelectedTileDetails? _selectedTile;

  int get seed => _seed;
  SelectedTileDetails? get selectedTile => _selectedTile;

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

  void updateSelectedTile(WorldTile tile) {
    _selectedTile = SelectedTileDetails.fromTile(tile);
    notifyListeners();
  }
}
