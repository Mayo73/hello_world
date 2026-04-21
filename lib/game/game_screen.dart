import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import 'game_hud_controller.dart';
import 'rts_game.dart';
import 'skirmish/building_type.dart';
import 'skirmish/faction.dart';
import 'skirmish/unit_type.dart';

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

  void _restartMatch() {
    _game.restartMatch();
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
                  final hasInspectableSelection =
                      selectedTile?.hasInspectableTarget ?? false;
                  final match = _hudController.matchState;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
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
                          IconButton(
                            onPressed: _copySeedToClipboard,
                            tooltip: 'Seed kopieren',
                            icon: const Icon(Icons.copy_rounded),
                          ),
                          FilledButton.icon(
                            key: const Key('regenerate-button'),
                            onPressed: _regenerate,
                            icon: const Icon(Icons.autorenew_rounded),
                            label: const Text('Neue Karte'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _TopBattleBar(controller: _hudController, game: _game),
                      if (match?.isFinished ?? false) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.topLeft,
                          child: DecoratedBox(
                            decoration: _panelDecoration(),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 380),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      match!.winner == Faction.player
                                          ? 'Demo won'
                                          : 'Demo lost',
                                      style: textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      match.winner == Faction.player
                                          ? 'You broke the enemy HQ. Restart this skirmish instantly or regenerate a new map for another run.'
                                          : 'The AI destroyed your HQ. Restart this skirmish to retry the same terrain or regenerate a new map to change the board.',
                                      style: textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        FilledButton.icon(
                                          onPressed: _restartMatch,
                                          icon: const Icon(Icons.replay_rounded),
                                          label: const Text('Restart skirmish'),
                                        ),
                                        FilledButton.tonalIcon(
                                          onPressed: _regenerate,
                                          icon: const Icon(Icons.autorenew_rounded),
                                          label: const Text('New map'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (hasInspectableSelection)
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: DecoratedBox(
                            decoration: _panelDecoration(),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 300),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      selectedTile!.biomeName,
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
                                    if (selectedTile.unitType != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Einheit: ${selectedTile.unitOwner?.displayName} ${selectedTile.unitType?.displayName} (${selectedTile.unitHealth} HP)',
                                        style: textTheme.bodyMedium,
                                      ),
                                      Text(
                                        selectedTile.unitReady ? 'Status: Einsatzbereit' : 'Status: Bereits gehandelt',
                                        style: textTheme.bodyMedium,
                                      ),
                                    ],
                                    if (selectedTile.buildingType != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Gebäude: ${selectedTile.buildingOwner?.displayName} ${selectedTile.buildingType?.displayName} (${selectedTile.buildingHealth} HP)',
                                        style: textTheme.bodyMedium,
                                      ),
                                    ],
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

class _TopBattleBar extends StatelessWidget {
  const _TopBattleBar({required this.controller, required this.game});

  final GameHudController controller;
  final RtsGame game;

  @override
  Widget build(BuildContext context) {
    final match = controller.matchState;
    if (match == null) return const SizedBox.shrink();

    final playerUnits = match.unitsFor(Faction.player).length;
    final enemyUnits = match.unitsFor(Faction.enemy).length;
    final selectedUnit = match.selectedUnit;
    final playerBarracks = match.buildings.firstWhere(
      (building) =>
          building.owner == Faction.player &&
          building.type == BuildingType.barracks &&
          !building.isDestroyed,
    );
    final barracksBlocked = playerBarracks.coord.neighbors().every(
      (coord) =>
          match.units.any((unit) => unit.coord == coord && !unit.isDestroyed) ||
          match.buildings.any((building) =>
              building.coord == coord && !building.isDestroyed),
    );
    final canRecruitScout =
        match.activeFaction == Faction.player &&
        !match.isFinished &&
        match.playerCredits >= 3 &&
        !barracksBlocked;
    final canRecruitTank =
        match.activeFaction == Faction.player &&
        !match.isFinished &&
        match.playerCredits >= 5 &&
        !barracksBlocked;
    final readyPlayerUnits = match
        .unitsFor(Faction.player)
        .where((unit) => !unit.hasActed)
        .length;
    final playerHq = match.buildings.firstWhere(
      (building) =>
          building.owner == Faction.player &&
          building.type == BuildingType.headquarters &&
          !building.isDestroyed,
    );
    final enemyHq = match.buildings.firstWhere(
      (building) =>
          building.owner == Faction.enemy &&
          building.type == BuildingType.headquarters &&
          !building.isDestroyed,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (match.isFinished)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: match.winner == Faction.player
                  ? const Color(0xCC1C3A24)
                  : const Color(0xCC442222),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: match.winner == Faction.player
                    ? const Color(0xAA7BFF8A)
                    : const Color(0xAAFF8A8A),
              ),
            ),
            child: Text(
              match.winner == Faction.player
                  ? 'Victory secured. Enemy HQ destroyed.'
                  : 'Defeat. Your HQ has fallen.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
        Chip(label: Text('Turn ${match.turn}')),
        Chip(label: Text(match.activeFaction == Faction.player ? 'Your turn' : 'Enemy turn')),
        Chip(label: Text('Credits ${match.playerCredits}')),
        Chip(label: Text('Enemy ${match.enemyCredits}')),
        Chip(label: Text('Units $playerUnits')),
        Chip(label: Text('Enemy units $enemyUnits')),
        Chip(label: Text('Ready $readyPlayerUnits')),
        Chip(label: Text('HQ ${playerHq.health}/${playerHq.maxHealth}')),
        Chip(label: Text('Enemy HQ ${enemyHq.health}/${enemyHq.maxHealth}')),
        if (match.phaseLabel case final phase?) Chip(label: Text(phase)),
        if (selectedUnit != null)
          Chip(
            label: Text(
              'Selected ${selectedUnit.type.displayName} ${selectedUnit.health}/${selectedUnit.maxHealth} • Reach ${selectedUnit.movementRange} • ATK ${selectedUnit.attack} • ${selectedUnit.hasActed ? 'Spent' : 'Ready'}',
            ),
          ),
        if (readyPlayerUnits == 0 &&
            match.activeFaction == Faction.player &&
            !match.isFinished)
          const Chip(label: Text('No ready units, end turn')),
        if (barracksBlocked && !match.isFinished)
          const Chip(label: Text('Barracks blocked')),
        if (match.statusMessage case final status?)
          Chip(label: Text(status)),
        FilledButton.tonalIcon(
          onPressed: canRecruitScout
              ? () => game.recruitUnit(UnitType.scout)
              : null,
          icon: const Icon(Icons.directions_run_rounded),
          label: Text(
            canRecruitScout
                ? 'Scout 3'
                : barracksBlocked
                    ? 'Scout blocked'
                    : 'Scout needs 3',
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: canRecruitTank
              ? () => game.recruitUnit(UnitType.tank)
              : null,
          icon: const Icon(Icons.shield_rounded),
          label: Text(
            canRecruitTank
                ? 'Tank 5'
                : barracksBlocked
                    ? 'Tank blocked'
                    : 'Tank needs 5',
          ),
        ),
        FilledButton.icon(
          style: readyPlayerUnits == 0 &&
                  match.activeFaction == Faction.player &&
                  !match.isFinished
              ? FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE0A93B),
                  foregroundColor: const Color(0xFF1A1304),
                )
              : null,
          onPressed: match.activeFaction == Faction.player && !match.isFinished
              ? game.endTurn
              : null,
          icon: Icon(
            readyPlayerUnits == 0 &&
                    match.activeFaction == Faction.player &&
                    !match.isFinished
                ? Icons.play_arrow_rounded
                : Icons.skip_next_rounded,
          ),
          label: Text(
            readyPlayerUnits == 0 &&
                    match.activeFaction == Faction.player &&
                    !match.isFinished
                ? 'End turn now'
                : 'End turn',
          ),
        ),
          ],
        ),
      ],
    );
  }
}
