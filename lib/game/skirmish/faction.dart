enum Faction { player, enemy }

extension FactionLabels on Faction {
  String get displayName => this == Faction.player ? 'Commander' : 'Raider AI';
}
