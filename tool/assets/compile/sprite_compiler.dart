import 'dart:io';

import 'catalog_sprite_compiler.dart';
import 'improvement_icon_sprite_compiler.dart';
import 'source_manifest.dart';
import 'sprite_compilation_context.dart';
import 'unit_sprite_compiler.dart';

final class SpriteCompiler {
  const SpriteCompiler({
    required this.sources,
    required this.sourceRoot,
    required this.outputRoot,
  });

  final AssetSourceManifest sources;
  final Directory sourceRoot;
  final Directory outputRoot;

  Future<void> compile() async {
    final context = SpriteCompilationContext(
      sources: sources,
      sourceRoot: sourceRoot,
      outputRoot: outputRoot,
    );
    await context.prepare();
    await UnitSpriteCompiler(context).compile();
    await CatalogSpriteCompiler(context).compile();
    await ImprovementIconSpriteCompiler(context).compile();
    await context.writeManifest();
  }
}
