import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:image/image.dart' as img;

import 'atlas_packer.dart';
import 'sprite_compilation_context.dart';

final class CatalogSpriteCompiler {
  const CatalogSpriteCompiler(this.context);

  final SpriteCompilationContext context;

  Future<void> compile() async {
    await _compileTechnologies();
    await _compileBuildings();
    await _compileWonders();
    await _compileCities();
  }

  Future<void> _compileTechnologies() async {
    final spec = context.sources.object('technologies');
    final columns = spec['columns'] as int;
    final rows = spec['rows'] as int;
    final order = (spec['atlasOrder'] as List<dynamic>).cast<String>();
    _expectExact('technologies', order.toSet(), {
      for (final id in TechnologyId.values) id.name,
    });
    final source = await context.decodeVerified(
      spec['source'] as String,
      spec['sha256'] as String,
    );
    final sheet = img.copyResize(
      source,
      width: 2048,
      interpolation: img.Interpolation.average,
    );
    final frames = [
      for (var index = 0; index < order.length; index++)
        frameFromCell(
          id: 'technology.${order[index]}',
          region: 'technology.${order[index]}',
          index: -1,
          sheet: sheet,
          columns: columns,
          rows: rows,
          column: index % columns,
          row: index ~/ columns,
          sourceInset: 2,
        ),
    ];
    await context.writeAtlas(
      'technologies',
      frames,
      compression: AtlasCompression.visuallyLossless,
      gridColumns: columns,
      gridRows: rows,
    );
  }

  Future<void> _compileBuildings() async {
    final specs = context.sources.list('buildings');
    if (specs.length != 3 || CityBuildingType.values.length > 60) {
      throw StateError('Building atlas contract requires three 20-slot pages');
    }
    for (var atlasIndex = 0; atlasIndex < specs.length; atlasIndex++) {
      await _compileBuildingPage(specs[atlasIndex], atlasIndex);
    }
  }

  Future<void> _compileBuildingPage(
    Map<String, dynamic> spec,
    int atlasIndex,
  ) async {
    final columns = spec['columns'] as int;
    final rows = spec['rows'] as int;
    final sheet = await context.decodeVerified(
      spec['source'] as String,
      spec['sha256'] as String,
    );
    final frames = <AtlasFrameInput>[];
    for (var slot = 0; slot < columns * rows; slot++) {
      final typeIndex = atlasIndex * columns * rows + slot;
      if (typeIndex >= CityBuildingType.values.length) break;
      final id = 'building.${CityBuildingType.values[typeIndex].name}';
      frames.add(
        frameFromCell(
          id: id,
          region: id,
          index: -1,
          sheet: sheet,
          columns: columns,
          rows: rows,
          column: slot % columns,
          row: slot ~/ columns,
          targetWidth: 256,
        ),
      );
    }
    await context.writeAtlas(
      spec['id'] as String,
      frames,
      compression: AtlasCompression.visuallyLossless,
      gridColumns: columns,
      gridRows: rows,
    );
  }

  Future<void> _compileWonders() async {
    final spec = context.sources.object('wonders');
    final columns = spec['columns'] as int;
    final rows = spec['rows'] as int;
    final sheet = await context.decodeVerified(
      spec['source'] as String,
      spec['sha256'] as String,
    );
    final frames = [
      for (final type in WonderType.values)
        frameFromCell(
          id: 'wonder.${type.name}',
          region: 'wonder.${type.name}',
          index: -1,
          sheet: sheet,
          columns: columns,
          rows: rows,
          column: type.index % columns,
          row: type.index ~/ columns,
          targetWidth: 256,
        ),
    ];
    await context.writeAtlas(
      'wonders',
      frames,
      compression: AtlasCompression.visuallyLossless,
      gridColumns: columns,
      gridRows: rows,
    );
  }

  Future<void> _compileCities() async {
    final spec = context.sources.object('cities');
    final columns = spec['columns'] as int;
    final rows = spec['rows'] as int;
    final sheet = await context.decodeVerified(
      spec['source'] as String,
      spec['sha256'] as String,
    );
    const profiles = [
      'growthCivic',
      'tradeKnowledgeMaritime',
      'militaryFortified',
      'industryModern',
    ];
    final frames = <AtlasFrameInput>[];
    for (var profile = 0; profile < profiles.length; profile++) {
      for (var level = 0; level < columns; level++) {
        final id = 'city.${profiles[profile]}.$level';
        frames.add(
          frameFromCell(
            id: id,
            region: id,
            index: -1,
            sheet: sheet,
            columns: columns,
            rows: rows,
            column: level,
            row: profile,
          ),
        );
      }
    }
    await context.writeAtlas(
      'cities',
      frames,
      compression: AtlasCompression.visuallyLossless,
      gridColumns: columns,
      gridRows: rows,
    );
  }

  void _expectExact(String label, Set<String> actual, Set<String> expected) {
    final missing = expected.difference(actual);
    final extra = actual.difference(expected);
    if (missing.isNotEmpty || extra.isNotEmpty) {
      throw StateError('$label mismatch; missing=$missing extra=$extra');
    }
  }
}
