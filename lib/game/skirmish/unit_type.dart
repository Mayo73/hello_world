enum UnitType { scout, tank }

extension UnitTypeLabels on UnitType {
  String get displayName => this == UnitType.scout ? 'Scout' : 'Tank';

  int get attack => this == UnitType.scout ? 1 : 2;

  int get maxHealth => this == UnitType.scout ? 3 : 5;
}
