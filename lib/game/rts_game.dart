import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/painting.dart';

import 'game_hud_controller.dart';
import 'skirmish/building_type.dart';
import 'skirmish/faction.dart';
import 'skirmish/skirmish_engine.dart';
import 'skirmish/skirmish_building.dart';
import 'skirmish/skirmish_match_state.dart';
import 'skirmish/skirmish_unit.dart';
import 'skirmish/unit_type.dart';
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
  final SkirmishEngine _skirmishEngine = const SkirmishEngine();

  late WorldMapData _worldMap;
  late SkirmishMatchState _matchState;
  int _seed;
  double _zoom = 1;
  Offset _cameraOffset = Offset.zero;
  Offset? _lastFocalPoint;
  double _gestureStartZoom = 1;
  Vector2 _viewportSize = Vector2.zero();
  bool _hasViewport = false;
  bool _worldReady = false;

  WorldMapData get worldMap => _worldMap;
  SkirmishMatchState get matchState => _matchState;
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
      final unit = _unitAt(coord);
      final building = _buildingAt(coord);
      if (unit?.owner == Faction.player && _matchState.activeFaction == Faction.player) {
        _matchState = _skirmishEngine.selectUnit(_matchState, unit!.id);
      } else if (_matchState.selectedUnit != null) {
        _matchState = _skirmishEngine.moveOrAttackSelectedUnit(_matchState, coord);
      } else {
        _matchState = _skirmishEngine.clearSelection(_matchState);
      }
      _pushHudSelection(tileAt: tile, unit: _unitAt(coord), building: _buildingAt(coord));
      hudController.updateMatchState(_matchState);
    }
  }

  void recruitUnit(UnitType type) {
    _matchState = _skirmishEngine.recruitUnit(_matchState, type);
    hudController.updateMatchState(_matchState);
    _syncSelectionFromMatch();
  }

  void endTurn() {
    _matchState = _skirmishEngine.endTurn(_matchState, _worldMap);
    hudController.updateMatchState(_matchState);
    _syncSelectionFromMatch();
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

    _drawSelectedUnitIntent(canvas);

    for (final building in _matchState.buildings) {
      _drawBuilding(canvas, building);
    }

    for (final unit in _matchState.units) {
      _drawUnit(canvas, unit);
    }

    canvas.restore();
  }

  void _loadSeed(int seed) {
    _seed = seed;
    _worldMap = _generator.generate(seed: seed, config: _config);
    _matchState = _skirmishEngine.createInitialState(_worldMap);
    _worldReady = true;
    hudController.setSeed(seed);
    hudController.clearSelection();
    hudController.updateMatchState(_matchState);

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

  void _drawSelectedUnitIntent(Canvas canvas) {
    final selectedUnit = _matchState.selectedUnit;
    if (selectedUnit == null ||
        selectedUnit.owner != Faction.player ||
        selectedUnit.hasActed ||
        _matchState.activeFaction != Faction.player) {
      return;
    }

    final reachableTiles = _reachableTilesFor(selectedUnit);

    for (final tile in _worldMap.tiles) {
      if (!tile.isPassable || tile.coord == selectedUnit.coord) {
        continue;
      }

      final distance = selectedUnit.coord.distanceTo(tile.coord);
      final unit = _unitAt(tile.coord);
      final building = _buildingAt(tile.coord);
      final center = tile.coord.toPixel(hexRadius);

      if (unit != null && unit.owner != selectedUnit.owner && distance <= 1) {
        canvas.drawCircle(
          center,
          hexRadius * 0.18,
          Paint()..color = const Color(0x99FF7B7B),
        );
        continue;
      }

      if (building != null && building.owner != selectedUnit.owner && distance <= 1) {
        canvas.drawCircle(
          center,
          hexRadius * 0.18,
          Paint()..color = const Color(0x99FFB347),
        );
        continue;
      }

      if (unit == null && building == null && reachableTiles.contains(tile.coord)) {
        final path = _hexPath(center, hexRadius * 0.58);
        canvas.drawPath(
          path,
          Paint()..color = const Color(0x335ED3FF),
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = const Color(0xAA8AE7FF),
        );
      }
    }
  }

  void _drawBuilding(Canvas canvas, SkirmishBuilding building) {
    final center = building.coord.toPixel(hexRadius);
    final color = building.owner == Faction.player
        ? const Color(0xFF6ED3FF)
        : const Color(0xFFFF7B7B);
    final type = building.type;
    final rect = Rect.fromCenter(
      center: center,
      width: hexRadius * 1.0,
      height: hexRadius * 0.85,
    );
    final paint = Paint()..color = color;
    switch (type) {
      case BuildingType.headquarters:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(8)),
          paint,
        );
      case BuildingType.mine:
        canvas.drawOval(rect, paint);
      case BuildingType.barracks:
        canvas.drawRect(rect, paint);
    }

    _drawHealthBar(
      canvas,
      center: center.translate(0, -hexRadius * 0.62),
      width: hexRadius * 0.9,
      health: building.health,
      maxHealth: building.maxHealth,
    );
    _drawBuildingLabel(canvas, building, center);
  }

  void _drawBuildingLabel(
    Canvas canvas,
    SkirmishBuilding building,
    Offset center,
  ) {
    final text = switch (building.type) {
      BuildingType.headquarters => 'HQ',
      BuildingType.mine => 'MIN',
      BuildingType.barracks => 'BAR',
    };
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: building.owner == Faction.player
              ? const Color(0xFF06141C)
              : const Color(0xFF2A0A0A),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        center.dx - (painter.width / 2),
        center.dy - (painter.height / 2),
      ),
    );
  }

  void _drawUnit(Canvas canvas, SkirmishUnit unit) {
    final center = unit.coord.toPixel(hexRadius);
    final fill = Paint()
      ..color = unit.owner == Faction.player
          ? const Color(0xFFF6D37B)
          : const Color(0xFFFFA259);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit.id == _matchState.selectedUnitId ? 3 : 1.4
      ..color = unit.id == _matchState.selectedUnitId
          ? const Color(0xFFFFFFFF)
          : const Color(0xAA10161B);

    final radius = unit.type == UnitType.scout ? hexRadius * 0.22 : hexRadius * 0.3;
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, outline);
    if (!unit.hasActed && unit.owner == Faction.player && _matchState.activeFaction == Faction.player) {
      canvas.drawCircle(center, radius + 6, Paint()..color = const Color(0x33FFFFFF));
    }

    _drawHealthBar(
      canvas,
      center: center.translate(0, -radius - 10),
      width: hexRadius * 0.72,
      health: unit.health,
      maxHealth: unit.maxHealth,
    );
    _drawUnitLabel(canvas, unit, center);
  }

  void _drawUnitLabel(
    Canvas canvas,
    SkirmishUnit unit,
    Offset center,
  ) {
    final text = unit.type == UnitType.scout ? 'S' : 'T';
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: unit.owner == Faction.player
              ? const Color(0xFF2F2200)
              : const Color(0xFF351400),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        center.dx - (painter.width / 2),
        center.dy - (painter.height / 2),
      ),
    );
  }

  void _drawHealthBar(
    Canvas canvas, {
    required Offset center,
    required double width,
    required int health,
    required int maxHealth,
  }) {
    final clampedRatio = (health / maxHealth).clamp(0.0, 1.0);
    final rect = Rect.fromCenter(center: center, width: width, height: 6);
    final fillRect = Rect.fromLTWH(rect.left, rect.top, rect.width * clampedRatio, rect.height);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(999)),
      Paint()..color = const Color(0xAA11181D),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(fillRect, const Radius.circular(999)),
      Paint()
        ..color = clampedRatio > 0.55
            ? const Color(0xFF7BFF8A)
            : clampedRatio > 0.3
                ? const Color(0xFFFFD166)
                : const Color(0xFFFF6B6B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(999)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x66333B42),
    );
  }

  void _pushHudSelection({required WorldTile tileAt, SkirmishUnit? unit, SkirmishBuilding? building}) {
    hudController.updateSelectedTile(
      tileAt,
      unitOwner: unit?.owner,
      unitType: unit?.type,
      unitHealth: unit?.health,
      unitReady: unit != null && !unit.hasActed,
      buildingOwner: building?.owner,
      buildingType: building?.type,
      buildingHealth: building?.health,
    );
  }

  void _syncSelectionFromMatch() {
    final selectedCoord = _worldMap.selectedCoord;
    if (selectedCoord == null) return;
    final tile = _worldMap.tileAt(selectedCoord);
    if (tile == null) return;
    _pushHudSelection(tileAt: tile, unit: _unitAt(selectedCoord), building: _buildingAt(selectedCoord));
  }

  Set<HexCoord> _reachableTilesFor(SkirmishUnit unit) {
    final visited = <HexCoord>{unit.coord};
    final frontier = <({HexCoord coord, int steps})>[(coord: unit.coord, steps: 0)];
    final reachable = <HexCoord>{};

    while (frontier.isNotEmpty) {
      final current = frontier.removeAt(0);
      if (current.steps >= unit.movementRange) {
        continue;
      }

      for (final neighbor in current.coord.neighbors()) {
        if (!_worldMap.contains(neighbor) || visited.contains(neighbor)) {
          continue;
        }
        visited.add(neighbor);

        final tile = _worldMap.tileAt(neighbor);
        if (!(tile?.isPassable ?? false) ||
            _unitAt(neighbor) != null ||
            _buildingAt(neighbor) != null) {
          continue;
        }

        reachable.add(neighbor);
        frontier.add((coord: neighbor, steps: current.steps + 1));
      }
    }

    return reachable;
  }

  SkirmishUnit? _unitAt(HexCoord coord) {
    for (final unit in _matchState.units) {
      if (unit.coord == coord && !unit.isDestroyed) return unit;
    }
    return null;
  }

  SkirmishBuilding? _buildingAt(HexCoord coord) {
    for (final building in _matchState.buildings) {
      if (building.coord == coord && !building.isDestroyed) return building;
    }
    return null;
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
