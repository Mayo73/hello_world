enum TileBiome { ocean, plains, forest, mountain }

extension TileBiomeLabels on TileBiome {
  String get displayName {
    switch (this) {
      case TileBiome.ocean:
        return 'Ozean';
      case TileBiome.plains:
        return 'Ebene';
      case TileBiome.forest:
        return 'Wald';
      case TileBiome.mountain:
        return 'Gebirge';
    }
  }
}
