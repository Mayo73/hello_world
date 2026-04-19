import 'dart:collection';

import 'hex_coord.dart';
import 'world_tile.dart';

class WorldMapData {
  WorldMapData({
    required this.width,
    required this.height,
    required this.seed,
    required Map<HexCoord, WorldTile> tiles,
    this.selectedCoord,
  }) : _tiles = UnmodifiableMapView<HexCoord, WorldTile>(tiles);

  final int width;
  final int height;
  final int seed;
  final HexCoord? selectedCoord;
  final UnmodifiableMapView<HexCoord, WorldTile> _tiles;

  Iterable<WorldTile> get tiles => _tiles.values;

  bool contains(HexCoord coord) {
    return coord.q >= 0 && coord.q < width && coord.r >= 0 && coord.r < height;
  }

  WorldTile? tileAt(HexCoord coord) => _tiles[coord];

  List<WorldTile> neighborsOf(HexCoord coord) {
    return coord
        .neighbors()
        .where(contains)
        .map((neighbor) => _tiles[neighbor])
        .whereType<WorldTile>()
        .toList(growable: false);
  }

  WorldMapData withSelectedCoord(HexCoord? nextSelectedCoord) {
    if (nextSelectedCoord == selectedCoord) {
      return this;
    }

    final nextTiles = Map<HexCoord, WorldTile>.from(_tiles);

    if (selectedCoord != null && nextTiles.containsKey(selectedCoord)) {
      nextTiles[selectedCoord!] = nextTiles[selectedCoord!]!.copyWith(
        isSelected: false,
      );
    }

    if (nextSelectedCoord != null && nextTiles.containsKey(nextSelectedCoord)) {
      nextTiles[nextSelectedCoord] = nextTiles[nextSelectedCoord]!.copyWith(
        isSelected: true,
      );
    }

    return WorldMapData(
      width: width,
      height: height,
      seed: seed,
      tiles: nextTiles,
      selectedCoord: nextSelectedCoord,
    );
  }
}
