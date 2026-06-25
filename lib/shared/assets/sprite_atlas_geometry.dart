import 'dart:math' as math;
import 'dart:ui' as ui;

abstract final class SpriteAtlasGeometry {
  static ui.Rect cellRectFor({
    required int imageWidth,
    required int imageHeight,
    required int columns,
    required int rows,
    required int column,
    required int row,
  }) {
    assert(imageWidth > 0);
    assert(imageHeight > 0);
    assert(columns > 0);
    assert(rows > 0);

    final safeColumn = column.clamp(0, columns - 1).toInt();
    final safeRow = row.clamp(0, rows - 1).toInt();
    final left = (safeColumn * imageWidth / columns).round();
    final right = ((safeColumn + 1) * imageWidth / columns).round();
    final top = (safeRow * imageHeight / rows).round();
    final bottom = ((safeRow + 1) * imageHeight / rows).round();

    return ui.Rect.fromLTRB(
      left.toDouble(),
      top.toDouble(),
      math.max(left + 1, right).toDouble(),
      math.max(top + 1, bottom).toDouble(),
    );
  }

  static ui.Rect sourceRectFor({
    required int imageWidth,
    required int imageHeight,
    required int columns,
    required int rows,
    required int column,
    required int row,
    required double sourceInset,
  }) {
    final cell = cellRectFor(
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      columns: columns,
      rows: rows,
      column: column,
      row: row,
    );
    final inset = resolvedInsetFor(
      width: cell.width,
      height: cell.height,
      requestedInset: sourceInset,
    );

    return ui.Rect.fromLTWH(
      cell.left + inset,
      cell.top + inset,
      math.max(1, cell.width - inset * 2),
      math.max(1, cell.height - inset * 2),
    );
  }

  static double resolvedInsetFor({
    required double width,
    required double height,
    required double requestedInset,
  }) {
    final maxInset = math.min(width, height) / 2 - 0.5;
    return math.min(requestedInset, math.max(0, maxInset));
  }
}
