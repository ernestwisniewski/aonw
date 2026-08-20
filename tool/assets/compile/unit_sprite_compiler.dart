import 'dart:math' as math;

import 'package:aonw_core/game/domain/unit.dart';
import 'package:image/image.dart' as img;

import 'atlas_packer.dart';
import 'source_manifest.dart';
import 'sprite_compilation_context.dart';

final class UnitSpriteCompiler {
  const UnitSpriteCompiler(this.context);

  final SpriteCompilationContext context;

  Future<void> compile() async {
    _expectUnitIds();
    for (final spec in context.sources.units) {
      await _compileUnit(spec);
    }
    await _compileDice();
  }

  Future<void> _compileUnit(UnitSourceSpec spec) async {
    final source = await context.decodeVerified(
      'sprites/units/${spec.name}.png',
      spec.sha256,
    );
    final sheet = img.copyResize(
      source,
      width: spec.targetWidth,
      interpolation: img.Interpolation.average,
    );
    final frames = _unitFrames(spec, sheet);
    for (final frame in frames) {
      _validateLegacyBounds(frame, spec, sheet);
    }
    await context.writeAtlas(
      'unit_${spec.name}',
      frames,
      compression: AtlasCompression.lossless,
      gridColumns: spec.columns,
      gridRows: spec.rows,
    );
  }

  List<AtlasFrameInput> _unitFrames(UnitSourceSpec spec, img.Image sheet) {
    final frames = <AtlasFrameInput>[];
    for (final animation in spec.animations) {
      final rowFrames = <AtlasFrameInput>[];
      for (var index = 0; index < animation.sourceColumns.length; index++) {
        final sequence = 'unit.${spec.name}.${animation.action}';
        rowFrames.add(
          frameFromCell(
            id: '$sequence.$index',
            region: sequence,
            index: index,
            sheet: sheet,
            columns: spec.columns,
            rows: spec.rows,
            column: animation.sourceColumns[index],
            row: animation.row,
            sourceInset: spec.sourceInset,
            contentPadding: 18,
          ),
        );
      }
      _shareStatusAnchor(rowFrames);
      frames.addAll(rowFrames);
    }
    return frames;
  }

  void _shareStatusAnchor(List<AtlasFrameInput> frames) {
    final tops =
        frames.map((frame) => frame.statusTop).whereType<double>().toList()
          ..sort();
    final middle = tops.length ~/ 2;
    final statusTop = tops.isEmpty
        ? 0.0
        : tops.length.isOdd
        ? tops[middle]
        : (tops[middle - 1] + tops[middle]) / 2;
    for (final frame in frames) {
      frame.statusTop = statusTop;
    }
  }

  void _validateLegacyBounds(
    AtlasFrameInput frame,
    UnitSourceSpec spec,
    img.Image sheet,
  ) {
    final column = frame.gridColumn!;
    final row = frame.gridRow!;
    final width =
        _cellExtent(column, sheet.width, spec.columns) - spec.sourceInset * 2;
    final height =
        _cellExtent(row, sheet.height, spec.rows) - spec.sourceInset * 2;
    if (frame.originalWidth != width ||
        frame.originalHeight != height ||
        frame.image.width != width ||
        frame.image.height != height ||
        frame.offsetX != 0 ||
        frame.offsetYFromTop != 0) {
      throw StateError('${frame.id} changes the source grid bounds');
    }
  }

  Future<void> _compileDice() async {
    final spec = context.sources.object('dice');
    final columns = spec['columns'] as int;
    final rows = spec['rows'] as int;
    if (columns != 6 || rows != 6) {
      throw StateError('Dice atlas contract must remain 6x6');
    }
    final sheet = await context.decodeVerified(
      spec['source'] as String,
      spec['sha256'] as String,
    );
    final frames = <AtlasFrameInput>[];
    for (var index = 0; index < columns * rows; index++) {
      frames.add(
        frameFromCell(
          id: 'dice.$index',
          region: 'dice',
          index: index,
          sheet: sheet,
          columns: columns,
          rows: rows,
          column: index % columns,
          row: index ~/ columns,
        ),
      );
    }
    await context.writeAtlas(
      'dice',
      frames,
      gridColumns: columns,
      gridRows: rows,
    );
  }

  void _expectUnitIds() {
    final configured = {for (final spec in context.sources.units) spec.name};
    final expected = {for (final type in GameUnitType.values) type.name};
    final missing = expected.difference(configured);
    final extra = configured.difference(expected);
    if (missing.isNotEmpty || extra.isNotEmpty) {
      throw StateError('units mismatch; missing=$missing extra=$extra');
    }
  }

  int _cellExtent(int index, int extent, int count) => math.max(
    1,
    ((index + 1) * extent / count).round() - (index * extent / count).round(),
  );
}
