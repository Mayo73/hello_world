enum UnitType { scout, tank }

extension UnitTypeLabels on UnitType {
  String get displayName => this == UnitType.scout ? 'Scout' : 'Tank';

  int get recruitCost => this == UnitType.scout ? 3 : 5;

  int get attack => this == UnitType.scout ? 1 : 2;

  int get maxHealth => this == UnitType.scout ? 3 : 5;

  int get movementAp => this == UnitType.scout ? 2 : 1;

  String get tacticalHint => this == UnitType.scout
      ? 'Fast skirmisher. Best for flanks, screening, and finishing weakened targets.'
      : 'Slow heavy unit. Stronger hit, better for breaking lines and HQ pressure.';
}
