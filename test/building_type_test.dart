import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/game/skirmish/building_type.dart';

void main() {
  test('building types expose centralized structure metadata', () {
    expect(BuildingType.headquarters.displayName, 'HQ');
    expect(BuildingType.headquarters.maxHealth, 10);
    expect(BuildingType.headquarters.effectText, 'Critical target');
    expect(BuildingType.headquarters.incomeBonus, isNull);
    expect(BuildingType.headquarters.spawnLabel, isNull);
    expect(
      BuildingType.headquarters.tacticalHint,
      'Lose this and the match ends. Protect it while opening a path to the enemy HQ.',
    );

    expect(BuildingType.mine.displayName, 'Mine');
    expect(BuildingType.mine.maxHealth, 6);
    expect(BuildingType.mine.effectText, 'Economic node');
    expect(BuildingType.mine.incomeBonus, 1);
    expect(BuildingType.mine.spawnLabel, isNull);
    expect(
      BuildingType.mine.tacticalHint,
      'Economic node. Each surviving mine adds +1 income every turn.',
    );

    expect(BuildingType.barracks.displayName, 'Barracks');
    expect(BuildingType.barracks.maxHealth, 7);
    expect(BuildingType.barracks.effectText, 'Production building');
    expect(BuildingType.barracks.incomeBonus, isNull);
    expect(BuildingType.barracks.spawnLabel, 'Scout, Tank');
    expect(
      BuildingType.barracks.tacticalHint,
      'Production building. New scouts and tanks deploy on adjacent free tiles.',
    );
  });
}
