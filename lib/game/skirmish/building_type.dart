enum BuildingType { headquarters, mine, barracks }

extension BuildingTypeLabels on BuildingType {
  String get displayName {
    switch (this) {
      case BuildingType.headquarters:
        return 'HQ';
      case BuildingType.mine:
        return 'Mine';
      case BuildingType.barracks:
        return 'Barracks';
    }
  }

  int get maxHealth {
    switch (this) {
      case BuildingType.headquarters:
        return 10;
      case BuildingType.mine:
        return 6;
      case BuildingType.barracks:
        return 7;
    }
  }

  String get effectText {
    switch (this) {
      case BuildingType.headquarters:
        return 'Critical target';
      case BuildingType.mine:
        return 'Economic node';
      case BuildingType.barracks:
        return 'Production building';
    }
  }

  int? get incomeBonus => this == BuildingType.mine ? 1 : null;

  String? get spawnLabel => this == BuildingType.barracks ? 'Scout, Tank' : null;
}
