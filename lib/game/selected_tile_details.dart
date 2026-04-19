import 'world/hex_coord.dart';
import 'world/tile_biome.dart';
import 'world/world_tile.dart';

class SelectedTileDetails {
  const SelectedTileDetails({
    required this.coord,
    required this.biomeName,
    required this.movementText,
    required this.passabilityText,
  });

  factory SelectedTileDetails.fromTile(WorldTile tile) {
    return SelectedTileDetails(
      coord: tile.coord,
      biomeName: tile.biome.displayName,
      movementText: tile.isPassable
          ? '${tile.movementCost ?? '-'} AP'
          : 'Unpassierbar',
      passabilityText: tile.isPassable ? 'Passierbar' : 'Blockiert',
    );
  }

  final HexCoord coord;
  final String biomeName;
  final String movementText;
  final String passabilityText;
}
