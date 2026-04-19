import 'hex_coord.dart';
import 'tile_biome.dart';

class WorldTile {
  const WorldTile({
    required this.coord,
    required this.biome,
    required this.isPassable,
    required this.movementCost,
    this.isSelected = false,
  });

  final HexCoord coord;
  final TileBiome biome;
  final bool isPassable;
  final int? movementCost;
  final bool isSelected;

  WorldTile copyWith({bool? isSelected}) {
    return WorldTile(
      coord: coord,
      biome: biome,
      isPassable: isPassable,
      movementCost: movementCost,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
