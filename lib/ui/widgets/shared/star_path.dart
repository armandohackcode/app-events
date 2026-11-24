import 'dart:ui';

/// Builds a 4-point sparkle star path centered at ([cx], [cy]) with outer [radius].
Path buildFourPointStarPath(
  double cx,
  double cy,
  double radius, {
  double innerFactor = 0.2,
}) {
  final c = radius * innerFactor;
  return Path()
    ..moveTo(cx, cy - radius)
    ..quadraticBezierTo(cx + c, cy - c, cx + radius, cy)
    ..quadraticBezierTo(cx + c, cy + c, cx, cy + radius)
    ..quadraticBezierTo(cx - c, cy + c, cx - radius, cy)
    ..quadraticBezierTo(cx - c, cy - c, cx, cy - radius)
    ..close();
}

final Path _unitStarSharpPath = buildFourPointStarPath(
  0,
  0,
  1.0,
  innerFactor: 0.18,
);

/// Draws a 4-point sparkle star using a cached unit path to avoid per-frame allocations.
void drawScaledFourPointStar(
  Canvas canvas,
  Paint paint,
  double cx,
  double cy,
  double radius,
) {
  canvas
    ..save()
    ..translate(cx, cy)
    ..scale(radius)
    ..drawPath(_unitStarSharpPath, paint)
    ..restore();
}
