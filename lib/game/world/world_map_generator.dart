import 'dart:math' as math;

import 'hex_coord.dart';
import 'tile_biome.dart';
import 'world_gen_config.dart';
import 'world_map_data.dart';
import 'world_tile.dart';

class WorldMapGenerator {
  const WorldMapGenerator();

  WorldMapData generate({required int seed, required WorldGenConfig config}) {
    final elevations = <HexCoord, double>{};
    final moistures = <HexCoord, double>{};
    final landCoords = <HexCoord>{};

    for (var r = 0; r < config.height; r++) {
      for (var q = 0; q < config.width; q++) {
        final coord = HexCoord(q, r);
        final x = config.width == 1 ? 0.0 : q / (config.width - 1);
        final y = config.height == 1 ? 0.0 : r / (config.height - 1);
        final elevation = _elevation(seed, x, y);
        final moisture = _moisture(seed, x, y, elevation);
        elevations[coord] = elevation;
        moistures[coord] = moisture;

        if (elevation > config.seaLevel) {
          landCoords.add(coord);
        }
      }
    }

    final majorLand = _ensureMajorContinent(
      landCoords: landCoords,
      seed: seed,
      config: config,
    );
    final filteredLand = _removeTinyIslands(
      landCoords: majorLand,
      config: config,
    );

    final tiles = <HexCoord, WorldTile>{};
    for (var r = 0; r < config.height; r++) {
      for (var q = 0; q < config.width; q++) {
        final coord = HexCoord(q, r);
        final elevation = elevations[coord]!;
        final moisture = moistures[coord]!;
        final biome = filteredLand.contains(coord)
            ? _landBiome(
                elevation: elevation,
                moisture: moisture,
                config: config,
              )
            : TileBiome.ocean;

        tiles[coord] = WorldTile(
          coord: coord,
          biome: biome,
          isPassable: biome == TileBiome.plains || biome == TileBiome.forest,
          movementCost: switch (biome) {
            TileBiome.plains => 1,
            TileBiome.forest => 2,
            TileBiome.ocean || TileBiome.mountain => null,
          },
        );
      }
    }

    return WorldMapData(
      width: config.width,
      height: config.height,
      seed: seed,
      tiles: tiles,
    );
  }

  TileBiome _landBiome({
    required double elevation,
    required double moisture,
    required WorldGenConfig config,
  }) {
    if (elevation >= config.mountainLevel) {
      return TileBiome.mountain;
    }

    if (moisture >= config.forestMoistureLevel) {
      return TileBiome.forest;
    }

    return TileBiome.plains;
  }

  Set<HexCoord> _ensureMajorContinent({
    required Set<HexCoord> landCoords,
    required int seed,
    required WorldGenConfig config,
  }) {
    final candidate = Set<HexCoord>.from(landCoords);
    final largest = _largestComponent(candidate, config);
    if (largest.length >= config.minContinentSize) {
      return candidate;
    }

    for (var r = 0; r < config.height; r++) {
      for (var q = 0; q < config.width; q++) {
        final coord = HexCoord(q, r);
        final x = config.width == 1 ? 0.0 : q / (config.width - 1);
        final y = config.height == 1 ? 0.0 : r / (config.height - 1);
        final dx = (x - 0.5) / 0.55;
        final dy = (y - 0.5) / 0.65;
        final radial = math.sqrt((dx * dx) + (dy * dy));
        final bonus = _noise(seed + 991, x + 0.17, y - 0.11, 5.1) * 0.25;
        final centrality = 1.0 - radial + bonus;
        if (centrality > 0.18) {
          candidate.add(coord);
        }
      }
    }

    return candidate;
  }

  Set<HexCoord> _removeTinyIslands({
    required Set<HexCoord> landCoords,
    required WorldGenConfig config,
  }) {
    final kept = <HexCoord>{};
    final components = _landComponents(landCoords, config);
    if (components.isEmpty) {
      return kept;
    }

    final majorComponent = components.reduce(
      (best, current) => current.length > best.length ? current : best,
    );

    for (final component in components) {
      if (identical(component, majorComponent) ||
          component.length >= config.minIslandSize) {
        kept.addAll(component);
      }
    }

    return kept;
  }

  List<Set<HexCoord>> _landComponents(
    Set<HexCoord> landCoords,
    WorldGenConfig config,
  ) {
    final remaining = Set<HexCoord>.from(landCoords);
    final components = <Set<HexCoord>>[];

    while (remaining.isNotEmpty) {
      final start = remaining.first;
      final open = <HexCoord>[start];
      final component = <HexCoord>{start};
      remaining.remove(start);

      while (open.isNotEmpty) {
        final current = open.removeLast();
        for (final neighbor in current.neighbors()) {
          if (!_isWithinBounds(neighbor, config) ||
              !remaining.contains(neighbor)) {
            continue;
          }

          remaining.remove(neighbor);
          component.add(neighbor);
          open.add(neighbor);
        }
      }

      components.add(component);
    }

    return components;
  }

  Set<HexCoord> _largestComponent(
    Set<HexCoord> landCoords,
    WorldGenConfig config,
  ) {
    final components = _landComponents(landCoords, config);
    if (components.isEmpty) {
      return const <HexCoord>{};
    }

    return components.reduce(
      (best, current) => current.length > best.length ? current : best,
    );
  }

  bool _isWithinBounds(HexCoord coord, WorldGenConfig config) {
    return coord.q >= 0 &&
        coord.q < config.width &&
        coord.r >= 0 &&
        coord.r < config.height;
  }

  double _elevation(int seed, double x, double y) {
    final dx = (x - 0.5) / 0.62;
    final dy = (y - 0.5) / 0.78;
    final radial = math.sqrt((dx * dx) + (dy * dy));
    final landFalloff = (1.0 - radial).clamp(-1.0, 1.0);

    final continental = _noise(seed + 11, x, y, 2.2);
    final detail = _noise(seed + 23, x + 0.31, y - 0.19, 6.4);
    final ridges = _noise(seed + 47, x - 0.08, y + 0.22, 3.7);

    return (landFalloff * 0.82) +
        (continental * 0.42) +
        (detail * 0.12) +
        (ridges * 0.14) -
        0.08;
  }

  double _moisture(int seed, double x, double y, double elevation) {
    final humidBands = _noise(seed + 101, x + 0.41, y + 0.73, 3.8);
    final coastBias = (0.85 - elevation).clamp(0.0, 1.0);
    final interiorBias = (1.0 - (y - 0.5).abs() * 1.6).clamp(0.0, 1.0);

    return (humidBands * 0.6) + (coastBias * 0.25) + (interiorBias * 0.15);
  }

  double _noise(int seed, double x, double y, double frequency) {
    final scaledX = x * frequency;
    final scaledY = y * frequency;

    final x0 = scaledX.floor();
    final y0 = scaledY.floor();
    final x1 = x0 + 1;
    final y1 = y0 + 1;

    final tx = scaledX - x0;
    final ty = scaledY - y0;
    final sx = _smoothStep(tx);
    final sy = _smoothStep(ty);

    final n00 = _hashToUnit(seed, x0, y0);
    final n10 = _hashToUnit(seed, x1, y0);
    final n01 = _hashToUnit(seed, x0, y1);
    final n11 = _hashToUnit(seed, x1, y1);

    final nx0 = _lerp(n00, n10, sx);
    final nx1 = _lerp(n01, n11, sx);
    return _lerp(nx0, nx1, sy);
  }

  double _hashToUnit(int seed, int x, int y) {
    var value = seed ^ (x * 374761393) ^ (y * 668265263);
    value = (value ^ (value >> 13)) * 1274126177;
    value ^= value >> 16;
    final normalized = (value & 0x7fffffff) / 0x7fffffff;
    return normalized * 2 - 1;
  }

  double _smoothStep(double t) => t * t * (3 - (2 * t));

  double _lerp(double a, double b, double t) => a + ((b - a) * t);
}
