import 'package:aonw_core/game/domain/city.dart';

import 'atlas_packer.dart';
import 'sprite_compilation_context.dart';

final class ImprovementIconSpriteCompiler {
  const ImprovementIconSpriteCompiler(this.context);

  final SpriteCompilationContext context;

  Future<void> compile() async {
    await _compileImprovements();
    await _compileIcons();
  }

  Future<void> _compileImprovements() async {
    final specs = context.sources.list('improvements');
    final configured = <String>{};
    for (var sheetIndex = 0; sheetIndex < specs.length; sheetIndex++) {
      final spec = specs[sheetIndex];
      final types = (spec['types'] as List<dynamic>).cast<String>();
      configured.addAll(types);
      await _compileImprovementSheet(spec, types, sheetIndex + 1);
    }
    final expected = {
      for (final type in FieldImprovementType.values) type.name,
    };
    final missing = expected.difference(configured);
    final extra = configured.difference(expected);
    if (missing.isNotEmpty || extra.isNotEmpty) {
      throw StateError('improvements mismatch; missing=$missing extra=$extra');
    }
  }

  Future<void> _compileImprovementSheet(
    Map<String, dynamic> spec,
    List<String> types,
    int sheetNumber,
  ) async {
    final columns = spec['columns'] as int;
    final rows = spec['rows'] as int;
    final sheet = await context.decodeVerified(
      spec['source'] as String,
      spec['sha256'] as String,
    );
    final frames = <AtlasFrameInput>[];
    for (var era = 0; era < rows; era++) {
      for (var column = 0; column < types.length; column++) {
        final id = 'improvement.${types[column]}.$era';
        frames.add(
          frameFromCell(
            id: id,
            region: id,
            index: -1,
            sheet: sheet,
            columns: columns,
            rows: rows,
            column: column,
            row: era,
          ),
        );
      }
    }
    await context.writeAtlas(
      'improvements_$sheetNumber',
      frames,
      compression: AtlasCompression.visuallyLossless,
      gridColumns: columns,
      gridRows: rows,
    );
  }

  Future<void> _compileIcons() async {
    final spec = context.sources.object('icons');
    final configured = (spec['frames'] as Map<String, dynamic>)
        .cast<String, String>();
    final bySource = <String, List<String>>{};
    for (final entry in configured.entries) {
      bySource.putIfAbsent(entry.value, () => []).add(entry.key);
    }
    final frames = <AtlasFrameInput>[];
    final regions = <String, String>{};
    for (final source in bySource.keys.toList()..sort()) {
      final image = await context.decode(source);
      if (image.width != 128 || image.height != 128) {
        throw StateError('$source must remain 128x128');
      }
      final region = 'map.icon.${_basename(source)}';
      regions[source] = region;
      frames.add(
        AtlasFrameInput(
          id: bySource[source]!.first,
          region: region,
          index: -1,
          image: image,
          originalWidth: 128,
          originalHeight: 128,
          offsetX: 0,
          offsetYFromTop: 0,
        ),
      );
    }
    final output = await context.writeAtlas('icons_map', frames);
    if (output.frameEntries.length != bySource.length) {
      throw StateError('Icon region de-duplication failed');
    }
    for (final entry in configured.entries) {
      context.setFrame(entry.key, {
        'atlas': 'icons_map',
        'region': regions[entry.value]!,
        'index': -1,
      });
    }
  }

  String _basename(String path) {
    final name = path.substring(path.lastIndexOf('/') + 1);
    final dot = name.lastIndexOf('.');
    return dot == -1 ? name : name.substring(0, dot);
  }
}
