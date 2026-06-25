import 'dart:math' as math;
import 'dart:ui';

abstract final class GameIconPathParser {
  static Path parse(String d) {
    final path = Path();
    final tokens = tokenize(d);
    var i = 0;
    double cx = 0;
    double cy = 0;
    double? startX;
    double? startY;
    String? lastCmd;
    String? previousDrawCmd;
    double? lastCubicControlX;
    double? lastCubicControlY;

    double nextDouble() => double.parse(tokens[i++]);

    while (i < tokens.length) {
      final token = tokens[i];
      if (_isCommand(token)) {
        lastCmd = token;
        i++;
      }
      final cmd = lastCmd!;

      switch (cmd) {
        case 'M':
          cx = nextDouble();
          cy = nextDouble();
          startX = cx;
          startY = cy;
          path.moveTo(cx, cy);
          lastCubicControlX = null;
          lastCubicControlY = null;
          previousDrawCmd = cmd;
          lastCmd = 'L';
        case 'm':
          cx += nextDouble();
          cy += nextDouble();
          startX = cx;
          startY = cy;
          path.moveTo(cx, cy);
          lastCubicControlX = null;
          lastCubicControlY = null;
          previousDrawCmd = cmd;
          lastCmd = 'l';
        case 'L':
          final x = nextDouble();
          final y = nextDouble();
          cx = x;
          cy = y;
          path.lineTo(cx, cy);
          lastCubicControlX = null;
          lastCubicControlY = null;
          previousDrawCmd = cmd;
        case 'l':
          final dx = nextDouble();
          final dy = nextDouble();
          cx += dx;
          cy += dy;
          path.lineTo(cx, cy);
          lastCubicControlX = null;
          lastCubicControlY = null;
          previousDrawCmd = cmd;
        case 'H':
          cx = nextDouble();
          path.lineTo(cx, cy);
          lastCubicControlX = null;
          lastCubicControlY = null;
          previousDrawCmd = cmd;
        case 'h':
          cx += nextDouble();
          path.lineTo(cx, cy);
          lastCubicControlX = null;
          lastCubicControlY = null;
          previousDrawCmd = cmd;
        case 'V':
          cy = nextDouble();
          path.lineTo(cx, cy);
          lastCubicControlX = null;
          lastCubicControlY = null;
          previousDrawCmd = cmd;
        case 'v':
          cy += nextDouble();
          path.lineTo(cx, cy);
          lastCubicControlX = null;
          lastCubicControlY = null;
          previousDrawCmd = cmd;
        case 'C':
          final x1 = nextDouble();
          final y1 = nextDouble();
          final x2 = nextDouble();
          final y2 = nextDouble();
          final x = nextDouble();
          final y = nextDouble();
          path.cubicTo(x1, y1, x2, y2, x, y);
          lastCubicControlX = x2;
          lastCubicControlY = y2;
          cx = x;
          cy = y;
          previousDrawCmd = cmd;
        case 'c':
          final x1 = nextDouble();
          final y1 = nextDouble();
          final x2 = nextDouble();
          final y2 = nextDouble();
          final dx = nextDouble();
          final dy = nextDouble();
          path.cubicTo(cx + x1, cy + y1, cx + x2, cy + y2, cx + dx, cy + dy);
          lastCubicControlX = cx + x2;
          lastCubicControlY = cy + y2;
          cx += dx;
          cy += dy;
          previousDrawCmd = cmd;
        case 'S':
          final x1 = _isCubicCommand(previousDrawCmd)
              ? 2 * cx - (lastCubicControlX ?? cx)
              : cx;
          final y1 = _isCubicCommand(previousDrawCmd)
              ? 2 * cy - (lastCubicControlY ?? cy)
              : cy;
          final x2 = nextDouble();
          final y2 = nextDouble();
          final x = nextDouble();
          final y = nextDouble();
          path.cubicTo(x1, y1, x2, y2, x, y);
          lastCubicControlX = x2;
          lastCubicControlY = y2;
          cx = x;
          cy = y;
          previousDrawCmd = cmd;
        case 's':
          final x1 = _isCubicCommand(previousDrawCmd)
              ? 2 * cx - (lastCubicControlX ?? cx)
              : cx;
          final y1 = _isCubicCommand(previousDrawCmd)
              ? 2 * cy - (lastCubicControlY ?? cy)
              : cy;
          final x2 = nextDouble();
          final y2 = nextDouble();
          final dx = nextDouble();
          final dy = nextDouble();
          path.cubicTo(x1, y1, cx + x2, cy + y2, cx + dx, cy + dy);
          lastCubicControlX = cx + x2;
          lastCubicControlY = cy + y2;
          cx += dx;
          cy += dy;
          previousDrawCmd = cmd;
        case 'Q':
          lastCubicControlX = null;
          lastCubicControlY = null;
          final x1 = nextDouble();
          final y1 = nextDouble();
          final x = nextDouble();
          final y = nextDouble();
          path.quadraticBezierTo(x1, y1, x, y);
          cx = x;
          cy = y;
          previousDrawCmd = cmd;
        case 'q':
          lastCubicControlX = null;
          lastCubicControlY = null;
          final x1 = nextDouble();
          final y1 = nextDouble();
          final dx = nextDouble();
          final dy = nextDouble();
          path.quadraticBezierTo(cx + x1, cy + y1, cx + dx, cy + dy);
          cx += dx;
          cy += dy;
          previousDrawCmd = cmd;
        case 'A':
          lastCubicControlX = null;
          lastCubicControlY = null;
          final rx = nextDouble();
          final ry = nextDouble();
          final xRot = nextDouble();
          final largeArc = nextDouble() != 0;
          final sweep = nextDouble() != 0;
          final x = nextDouble();
          final y = nextDouble();
          _arcTo(path, cx, cy, rx, ry, xRot, largeArc, sweep, x, y);
          cx = x;
          cy = y;
          previousDrawCmd = cmd;
        case 'a':
          lastCubicControlX = null;
          lastCubicControlY = null;
          final rx = nextDouble();
          final ry = nextDouble();
          final xRot = nextDouble();
          final largeArc = nextDouble() != 0;
          final sweep = nextDouble() != 0;
          final dx = nextDouble();
          final dy = nextDouble();
          _arcTo(path, cx, cy, rx, ry, xRot, largeArc, sweep, cx + dx, cy + dy);
          cx += dx;
          cy += dy;
          previousDrawCmd = cmd;
        case 'Z':
        case 'z':
          lastCubicControlX = null;
          lastCubicControlY = null;
          path.close();
          if (startX != null && startY != null) {
            cx = startX;
            cy = startY;
          }
          previousDrawCmd = cmd;
        default:
          lastCubicControlX = null;
          lastCubicControlY = null;
          previousDrawCmd = cmd;
          break;
      }
    }
    return path;
  }

  static List<String> tokenize(String d) {
    var spaced = d.replaceAllMapped(
      RegExp(r'([MmLlHhVvCcSsQqAaZz])'),
      (match) => ' ${match.group(1)} ',
    );
    spaced = spaced.replaceAllMapped(
      RegExp(r'(\d|\.)-'),
      (match) => '${match.group(1)} -',
    );
    return spaced
        .split(RegExp(r'[\s,]+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  static final _commandRegExp = RegExp(r'^[MmLlHhVvCcSsQqAaZz]$');

  static bool _isCommand(String value) =>
      value.length == 1 && _commandRegExp.hasMatch(value);

  static bool _isCubicCommand(String? value) =>
      value == 'C' || value == 'c' || value == 'S' || value == 's';

  static void _arcTo(
    Path path,
    double x1,
    double y1,
    double rx,
    double ry,
    double xAxisRotation,
    bool largeArcFlag,
    bool sweepFlag,
    double x2,
    double y2,
  ) {
    if (rx == 0 || ry == 0) {
      path.lineTo(x2, y2);
      return;
    }
    rx = rx.abs();
    ry = ry.abs();

    final dx = (x1 - x2) / 2;
    final dy = (y1 - y2) / 2;
    final x1p = dx;
    final y1p = dy;

    final x1pSq = x1p * x1p;
    final y1pSq = y1p * y1p;
    var rxSq = rx * rx;
    var rySq = ry * ry;
    final lambda = x1pSq / rxSq + y1pSq / rySq;
    if (lambda > 1) {
      final sqrtLambda = math.sqrt(lambda);
      rx *= sqrtLambda;
      ry *= sqrtLambda;
      rxSq = rx * rx;
      rySq = ry * ry;
    }

    final numerator = rxSq * rySq - rxSq * y1pSq - rySq * x1pSq;
    final denominator = rxSq * y1pSq + rySq * x1pSq;
    final sqrtTerm = denominator == 0
        ? 0.0
        : math.sqrt((numerator / denominator).abs());
    final sign = largeArcFlag == sweepFlag ? -1.0 : 1.0;
    final cxp = sign * sqrtTerm * (rx * y1p / ry);
    final cyp = sign * sqrtTerm * (-(ry * x1p / rx));

    final cx = cxp + (x1 + x2) / 2;
    final cy = cyp + (y1 + y2) / 2;

    final ux = (x1p - cxp) / rx;
    final uy = (y1p - cyp) / ry;
    final vx = (-x1p - cxp) / rx;
    final vy = (-y1p - cyp) / ry;

    final startAngle = _vectorAngle(1, 0, ux, uy);
    var sweepAngle = _vectorAngle(ux, uy, vx, vy);

    if (!sweepFlag && sweepAngle > 0) {
      sweepAngle -= 2 * math.pi;
    } else if (sweepFlag && sweepAngle < 0) {
      sweepAngle += 2 * math.pi;
    }

    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: rx * 2,
      height: ry * 2,
    );
    path.arcTo(rect, startAngle, sweepAngle, false);
  }

  static double _vectorAngle(double ux, double uy, double vx, double vy) {
    final dot = ux * vx + uy * vy;
    final length = math.sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy));
    if (length == 0) return 0;
    final cosAngle = (dot / length).clamp(-1.0, 1.0);
    final angle = math.acos(cosAngle);
    return ux * vy - uy * vx < 0 ? -angle : angle;
  }
}
