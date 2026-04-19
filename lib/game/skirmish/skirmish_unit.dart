import '../world/hex_coord.dart';
import 'faction.dart';
import 'unit_type.dart';

class SkirmishUnit {
  const SkirmishUnit({
    required this.id,
    required this.owner,
    required this.type,
    required this.coord,
    required this.health,
    this.hasActed = false,
  });

  final String id;
  final Faction owner;
  final UnitType type;
  final HexCoord coord;
  final int health;
  final bool hasActed;

  bool get isDestroyed => health <= 0;

  int get movementRange => type == UnitType.scout ? 2 : 1;

  int get attack => type.attack;

  int get maxHealth => type.maxHealth;

  SkirmishUnit copyWith({HexCoord? coord, int? health, bool? hasActed}) {
    return SkirmishUnit(
      id: id,
      owner: owner,
      type: type,
      coord: coord ?? this.coord,
      health: health ?? this.health,
      hasActed: hasActed ?? this.hasActed,
    );
  }
}
