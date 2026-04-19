import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/extensions.dart';

import 'game_hud_controller.dart';
import 'world/hex_coord.dart';
import 'world/tile_biome.dart';
import 'world/world_gen_config.dart';
import 'world/world_map_data.dart';
import 'world/world_map_generator.dart';
import 'world/world_tile.dart';

class RtsGame extends FlameGame {
  RtsGame({
    required int initialSeed,
    required this.hudController,
    WorldGenConfig? config,
    WorldMapGenerator? generator,
  }) : _config = config ?? const WorldGenConfig(),
       _generator = generator ?? const WorldMapGenerator(),
       _seed = initialSeed;

  static const double minZoom = 0.55;
  static const double maxZoom = 2.2;
  static const double hexRadius = 28;

  final GameHudController hudController;
  final WorldGenConfig _config;
  final WorldMapGenerator _generator;

  late WorldMapData _worldMap;
  int _seed;
  double _zoom = 1;
  Offset _cameraOffset = Offset.zero;
  Offset? _lastFocalPoint;
  double _gestureStartZoom = 1;
  Vector2 _viewportSize = Vector2.zero();
  bool _hasViewport = false;
  bool _worldReady = false;

  WorldMapData get worldMap => _worldMap;
  double get zoom => _zoom;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _loadSeed(_seed);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _viewportSize = size.clone();
    _hasViewport = true;
    if (_worldReady) {
      _resetCamera();
    }
  }

  void regenerate(int seed) {
    _loadSeed(seed);
  }

  void handleTap(Offset localPosition) {
    if (!_worldReady || !_hasViewport) {
      return;
    }

    final coord = HexCoord.fromPixel(_screenToWorld(localPosition), hexRadius);
    if (!_worldMap.contains(coord)) {
      return;
    }

    _worldMap = _worldMap.withSelectedCoord(coord);
    final tile = _worldMap.tileAt(coord);
    if (tile != null) {
      hudController.updateSelectedTile(tile);
    }
  }

  void handleScaleStart(Offset localFocalPoint) {
    _lastFocalPoint = localFocalPoint;
    _gestureStartZoom = _zoom;
  }

  void handleScaleUpdate({
    required Offset localFocalPoint,
    required double scale,
  }) {
    if (!_worldReady || !_hasViewport) {
      return;
    }

    final previousFocalPoint = _lastFocalPoint;
    if (previousFocalPoint != null) {
      final delta = localFocalPoint - previousFocalPoint;
      _cameraOffset = _cameraOffset.translate(
        delta.dx / _zoom,
        delta.dy / _zoom,
      );
    }
    _lastFocalPoint = localFocalPoint;

    final targetZoom = (_gestureStartZoom * scale).clamp(minZoom, maxZoom);
    if ((targetZoom - _zoom).abs() < 0.0001) {
      return;
    }

    final worldBeforeZoom = _screenToWorld(
      localFocalPoint,
      zoomOverride: _zoom,
      cameraOverride: _cameraOffset,
    );

    _zoom = targetZoom;

    final worldAfterZoom = _screenToWorld(
      localFocalPoint,
      zoomOverride: _zoom,
      cameraOverride: _cameraOffset,
    );

    final correction = worldBeforeZoom - worldAfterZoom;
    _cameraOffset = _cameraOffset.translate(correction.dx, correction.dy);
  }

  void handleScaleEnd() {
    _lastFocalPoint = null;
    _gestureStartZoom = _zoom;
  }

  Offset localCenterForTile(HexCoord coord) {
    final world = coord.toPixel(hexRadius);
    return _worldToScreen(world);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(
      Offset.zero & Size(_viewportSize.x, _viewportSize.y),
      Paint()..color = const Color(0xFF162128),
    );

    if (!_worldReady) {
      return;
    }

    canvas.save();
    final screenCenter = Offset(_viewportSize.x / 2, _viewportSize.y / 2);
    canvas.translate(screenCenter.dx, screenCenter.dy);
    canvas.scale(_zoom);
    canvas.translate(_cameraOffset.dx, _cameraOffset.dy);

    for (final tile in _worldMap.tiles) {
      _drawTile(canvas, tile);
    }

    canvas.restore();
  }

  void _loadSeed(int seed) {
    _seed = seed;
    _worldMap = _generator.generate(seed: seed, config: _config);
    _worldReady = true;
    hudController.setSeed(seed);
    hudController.clearSelection();

    if (_hasViewport) {
      _resetCamera();
    }
  }

  void _resetCamera() {
    final mapCenter = Offset(
      (math.sqrt(3) * hexRadius * (_config.width - 1)) / 2 +
          (math.sqrt(3) * hexRadius * (_config.height - 1)) / 4,
      (1.5 * hexRadius * (_config.height - 1)) / 2,
    );

    _zoom = 1;
    _cameraOffset = Offset(-mapCenter.dx, -mapCenter.dy);
    _gestureStartZoom = _zoom;
    _lastFocalPoint = null;
  }

  void _drawTile(Canvas canvas, WorldTile tile) {
    final center = tile.coord.toPixel(hexRadius);
    final path = _hexPath(center, hexRadius);
    final fillColor = switch (tile.biome) {
      TileBiome.ocean => const Color(0xFF24526B),
      TileBiome.plains => const Color(0xFF7BA05B),
      TileBiome.forest => const Color(0xFF35583C),
      TileBiome.mountain => const Color(0xFF8C8175),
    };

    final fillPaint = Paint()..color = fillColor;
    final borderPaint = Paint()
      ..color = tile.isSelected
          ? const Color(0xFFF6D37B)
          : const Color(0xAA10161B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = tile.isSelected ? 3.6 : 1.1;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    if (tile.isSelected) {
      canvas.drawCircle(
        center,
        hexRadius * 0.22,
        Paint()..color = const Color(0xCCFFF1B2),
      );
    }
  }

  Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (math.pi / 180) * ((60 * i) - 30);
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    return path;
  }

  Offset _screenToWorld(
    Offset localPosition, {
    double? zoomOverride,
    Offset? cameraOverride,
  }) {
    final currentZoom = zoomOverride ?? _zoom;
    final currentCamera = cameraOverride ?? _cameraOffset;
    final screenCenter = Offset(_viewportSize.x / 2, _viewportSize.y / 2);
    final centered = localPosition - screenCenter;
    return Offset(
      centered.dx / currentZoom - currentCamera.dx,
      centered.dy / currentZoom - currentCamera.dy,
    );
  }

  Offset _worldToScreen(Offset worldPosition) {
    final screenCenter = Offset(_viewportSize.x / 2, _viewportSize.y / 2);
    return Offset(
      screenCenter.dx + _zoom * (_cameraOffset.dx + worldPosition.dx),
      screenCenter.dy + _zoom * (_cameraOffset.dy + worldPosition.dy),
    );
  }
}
