import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/game/game_hud_controller.dart';
import 'package:hello_world/game/rts_game.dart';

void main() {
  test(
    'tap selects the expected tile and updates the HUD controller',
    () async {
      final hudController = GameHudController();
      final game = RtsGame(initialSeed: 1234, hudController: hudController);

      await game.onLoad();
      game.onGameResize(Vector2(1280, 720));

      final target = game.worldMap.tiles.first;
      final tapLocation = game.localCenterForTile(target.coord);
      game.handleTap(tapLocation);

      expect(game.worldMap.selectedCoord, target.coord);
      expect(hudController.selectedTile?.coord, target.coord);
    },
  );

  test('camera zoom stays within limits during scale gestures', () async {
    final hudController = GameHudController();
    final game = RtsGame(initialSeed: 22, hudController: hudController);

    await game.onLoad();
    game.onGameResize(Vector2(1280, 720));

    game.handleScaleStart(const Offset(300, 240));
    game.handleScaleUpdate(localFocalPoint: const Offset(300, 240), scale: 100);
    expect(game.zoom, RtsGame.maxZoom);

    game.handleScaleEnd();
    game.handleScaleStart(const Offset(300, 240));
    game.handleScaleUpdate(
      localFocalPoint: const Offset(300, 240),
      scale: 0.01,
    );
    expect(game.zoom, RtsGame.minZoom);
  });
}
