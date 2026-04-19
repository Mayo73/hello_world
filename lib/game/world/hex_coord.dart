import 'dart:math' as math;
import 'dart:ui';

class HexCoord {
  const HexCoord(this.q, this.r);

  static const List<HexCoord> directions = [
    HexCoord(1, 0),
    HexCoord(1, -1),
    HexCoord(0, -1),
    HexCoord(-1, 0),
    HexCoord(-1, 1),
    HexCoord(0, 1),
  ];

  final int q;
  final int r;

  int get s => -q - r;

  List<HexCoord> neighbors() {
    return directions.map((direction) => this + direction).toList();
  }

  int distanceTo(HexCoord other) {
    final dq = (q - other.q).abs();
    final dr = (r - other.r).abs();
    final ds = (s - other.s).abs();
    return math.max(dq, math.max(dr, ds));
  }

  Offset toPixel(double hexRadius) {
    final x = hexRadius * math.sqrt(3) * (q + (r / 2));
    final y = hexRadius * 1.5 * r;
    return Offset(x, y);
  }

  static HexCoord fromPixel(Offset position, double hexRadius) {
    final q = ((math.sqrt(3) / 3) * position.dx - position.dy / 3) / hexRadius;
    final r = ((2 / 3) * position.dy) / hexRadius;
    return _cubeRound(q, r);
  }

  static HexCoord _cubeRound(double q, double r) {
    final s = -q - r;

    var roundedQ = q.round();
    var roundedR = r.round();
    var roundedS = s.round();

    final qDiff = (roundedQ - q).abs();
    final rDiff = (roundedR - r).abs();
    final sDiff = (roundedS - s).abs();

    if (qDiff > rDiff && qDiff > sDiff) {
      roundedQ = -roundedR - roundedS;
    } else if (rDiff > sDiff) {
      roundedR = -roundedQ - roundedS;
    } else {
      roundedS = -roundedQ - roundedR;
    }

    return HexCoord(roundedQ, roundedR);
  }

  HexCoord operator +(HexCoord other) => HexCoord(q + other.q, r + other.r);

  @override
  bool operator ==(Object other) {
    return other is HexCoord && q == other.q && r == other.r;
  }

  @override
  int get hashCode => Object.hash(q, r);

  @override
  String toString() => '($q, $r)';
}
