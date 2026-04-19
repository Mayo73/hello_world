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
}
