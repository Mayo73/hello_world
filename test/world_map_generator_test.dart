import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/game/world/hex_coord.dart';
import 'package:hello_world/game/world/tile_biome.dart';
import 'package:hello_world/game/world/world_gen_config.dart';
import 'package:hello_world/game/world/world_map_data.dart';
import 'package:hello_world/game/world/world_map_generator.dart';

void main() {
  const generator = WorldMapGenerator();
  const config = WorldGenConfig();

  test('generator is deterministic for a fixed seed', () {
    final mapA = generator.generate(seed: 4242, config: config);
    final mapB = generator.generate(seed: 4242, config: config);

    final biomesA = mapA.tiles
        .map((tile) => tile.biome)
        .toList(growable: false);
    final biomesB = mapB.tiles
        .map((tile) => tile.biome)
        .toList(growable: false);

    expect(biomesA, biomesB);
  });

  test('neighbors stay within bounds', () {
    final map = generator.generate(seed: 11, config: config);

    for (final tile in map.tiles) {
      final neighbors = map.neighborsOf(tile.coord);
      for (final neighbor in neighbors) {
        expect(map.contains(neighbor.coord), isTrue);
      }
    }
  });

  test('map contains land, water, and a major continent', () {
    final map = generator.generate(seed: 7001, config: config);
    final oceanCount = map.tiles
        .where((tile) => tile.biome == TileBiome.ocean)
        .length;
    final landTiles = map.tiles
        .where((tile) => tile.biome != TileBiome.ocean)
        .toList();

    expect(oceanCount, greaterThan(0));
    expect(landTiles, isNotEmpty);

    final largestCluster = _largestLandCluster(map);
    expect(largestCluster, greaterThanOrEqualTo(config.minContinentSize));
  });

  test('terrain rules match biome expectations', () {
    final map = generator.generate(seed: 7001, config: config);

    for (final tile in map.tiles) {
      switch (tile.biome) {
        case TileBiome.ocean:
          expect(tile.isPassable, isFalse);
          expect(tile.movementCost, isNull);
        case TileBiome.mountain:
          expect(tile.isPassable, isFalse);
          expect(tile.movementCost, isNull);
        case TileBiome.plains:
          expect(tile.isPassable, isTrue);
          expect(tile.movementCost, 1);
        case TileBiome.forest:
          expect(tile.isPassable, isTrue);
          expect(tile.movementCost, 2);
      }
    }
  });
}

int _largestLandCluster(WorldMapData map) {
  final remaining = <HexCoord>{
    for (final tile in map.tiles)
      if (tile.biome != TileBiome.ocean) tile.coord,
  };
  var largest = 0;

  while (remaining.isNotEmpty) {
    final start = remaining.first;
    final open = <HexCoord>[start];
    var size = 0;
    remaining.remove(start);

    while (open.isNotEmpty) {
      final current = open.removeLast();
      size++;

      for (final neighbor in map.neighborsOf(current)) {
        if (neighbor.biome == TileBiome.ocean ||
            !remaining.remove(neighbor.coord)) {
          continue;
        }

        open.add(neighbor.coord);
      }
    }

    if (size > largest) {
      largest = size;
    }
  }

  return largest;
}
