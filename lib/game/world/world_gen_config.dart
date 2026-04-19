class WorldGenConfig {
  const WorldGenConfig({
    this.width = 36,
    this.height = 24,
    this.seaLevel = 0.48,
    this.mountainLevel = 0.82,
    this.forestMoistureLevel = 0.58,
    this.minContinentSize = 90,
    this.minIslandSize = 8,
  });

  final int width;
  final int height;
  final double seaLevel;
  final double mountainLevel;
  final double forestMoistureLevel;
  final int minContinentSize;
  final int minIslandSize;
}
