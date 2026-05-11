import '../world/hex_coord.dart';
import 'building_type.dart';
import 'faction.dart';

class SkirmishBuilding {
  const SkirmishBuilding({
    required this.id,
    required this.owner,
    required this.type,
    required this.coord,
    required this.health,
  });

  final String id;
  final Faction owner;
  final BuildingType type;
  final HexCoord coord;
  final int health;

  bool get isDestroyed => health <= 0;

  int get maxHealth => type.maxHealth;

  SkirmishBuilding copyWith({int? health}) {
    return SkirmishBuilding(
      id: id,
      owner: owner,
      type: type,
      coord: coord,
      health: health ?? this.health,
    );
  }
}
