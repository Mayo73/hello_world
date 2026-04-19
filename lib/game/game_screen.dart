import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import 'game_hud_controller.dart';
import 'rts_game.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.seedFactory});

  final SeedFactory seedFactory;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameHudController _hudController;
  late final RtsGame _game;

  @override
  void initState() {
    super.initState();
    _hudController = GameHudController();
    _game = RtsGame(
      initialSeed: widget.seedFactory(),
      hudController: _hudController,
    );
  }

  @override
  void dispose() {
    _hudController.dispose();
    super.dispose();
  }

  Future<void> _copySeedToClipboard() async {
    await Clipboard.setData(
      ClipboardData(text: _hudController.seed.toString()),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Seed kopiert')));
  }

  void _regenerate() {
    _game.regenerate(widget.seedFactory());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const Key('game-gesture-layer'),
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _game.handleTap(details.localPosition),
              onScaleStart: (details) =>
                  _game.handleScaleStart(details.localFocalPoint),
              onScaleUpdate: (details) => _game.handleScaleUpdate(
                localFocalPoint: details.localFocalPoint,
                scale: details.scale,
              ),
              onScaleEnd: (_) => _game.handleScaleEnd(),
              child: GameWidget(game: _game),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedBuilder(
                animation: _hudController,
                builder: (context, _) {
                  final selectedTile = _hudController.selectedTile;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: _panelDecoration(),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hexfront Prototype',
                                    style: textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    'Seed: ${_hudController.seed}',
                                    key: const Key('seed-text'),
                                    style: textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                onPressed: _copySeedToClipboard,
                                tooltip: 'Seed kopieren',
                                icon: const Icon(Icons.copy_rounded),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                key: const Key('regenerate-button'),
                                onPressed: _regenerate,
                                icon: const Icon(Icons.autorenew_rounded),
                                label: const Text('Neue Karte'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: DecoratedBox(
                          decoration: _panelDecoration(),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: selectedTile == null
                                  ? Text(
                                      'Tippe auf ein Feld, um Biom, Koordinate und Bewegungskosten anzuzeigen.',
                                      style: textTheme.bodyMedium,
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          selectedTile.biomeName,
                                          style: textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Koordinate: ${selectedTile.coord}',
                                          key: const Key('selected-coord-text'),
                                          style: textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Status: ${selectedTile.passabilityText}',
                                          style: textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Bewegung: ${selectedTile.movementText}',
                                          style: textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: const Color(0xCC10181D),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0x335E7B65)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
    );
  }
}
