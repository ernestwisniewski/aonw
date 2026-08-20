import 'dart:convert';
import 'dart:io';

import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/wonder.dart';

import 'atlas_runtime_parser.dart';
import 'source_manifest.dart';
import 'sprite_compilation_context.dart';

final class SpriteRuntimeVerifier {
  const SpriteRuntimeVerifier({
    required this.runtimeRoot,
    required this.sources,
  });

  final Directory runtimeRoot;
  final AssetSourceManifest sources;

  Future<List<String>> verify() async {
    final errors = <String>[];
    final spriteRoot = Directory('${runtimeRoot.path}/sprites');
    final manifestFile = File('${spriteRoot.path}/sprite_manifest.json');
    if (!await manifestFile.exists()) return ['missing sprite manifest'];
    final manifest = _decodeManifest(await manifestFile.readAsString());
    if (manifest['sourceManifestSha256'] != sources.sha256Digest) {
      errors.add('sprite manifest source SHA differs from source contract');
    }
    final atlases = _stringMap(manifest, 'atlases');
    final frames = _objectMap(manifest, 'frames');
    _verifyFrameIds(frames.keys.toSet(), errors);
    final usedRegions = _usedRegions(frames, atlases.keys.toSet(), errors);
    final expectedFiles = <String>{'sprite_manifest.json'};
    for (final entry in atlases.entries) {
      await _verifyAtlas(
        entry.key,
        entry.value,
        spriteRoot,
        usedRegions[entry.key] ?? const {},
        expectedFiles,
        errors,
      );
    }
    await _verifyFileSet(spriteRoot, expectedFiles, errors);
    return errors;
  }

  Map<String, dynamic> _decodeManifest(String contents) {
    final value = jsonDecode(contents);
    if (value is! Map<String, dynamic> || value['version'] != 1) {
      throw const FormatException('Unsupported sprite manifest');
    }
    return value;
  }

  Map<String, String> _stringMap(Map<String, dynamic> root, String key) {
    final value = root[key];
    if (value is! Map<String, dynamic>) {
      throw FormatException('Sprite manifest $key must be an object');
    }
    return value.cast<String, String>();
  }

  Map<String, Map<String, dynamic>> _objectMap(
    Map<String, dynamic> root,
    String key,
  ) {
    final value = root[key];
    if (value is! Map<String, dynamic>) {
      throw FormatException('Sprite manifest $key must be an object');
    }
    return value.map((id, entry) {
      if (entry is! Map<String, dynamic>) {
        throw FormatException('Invalid sprite frame: $id');
      }
      return MapEntry(id, entry);
    });
  }

  Map<String, Set<String>> _usedRegions(
    Map<String, Map<String, dynamic>> frames,
    Set<String> atlasIds,
    List<String> errors,
  ) {
    final used = <String, Set<String>>{};
    for (final entry in frames.entries) {
      final atlas = entry.value['atlas'];
      final region = entry.value['region'];
      final index = entry.value['index'];
      if (atlas is! String || region is! String || index is! int) {
        errors.add('${entry.key} has an invalid atlas reference');
        continue;
      }
      if (!atlasIds.contains(atlas)) {
        errors.add('${entry.key} references unknown atlas $atlas');
      }
      used.putIfAbsent(atlas, () => {}).add('$region#$index');
    }
    return used;
  }

  Future<void> _verifyAtlas(
    String id,
    String assetPath,
    Directory spriteRoot,
    Set<String> usedRegions,
    Set<String> expectedFiles,
    List<String> errors,
  ) async {
    final expectedPath = '$spriteRuntimeRoot/$id/$id.atlas';
    if (assetPath != expectedPath) {
      errors.add('$id atlas path is $assetPath; expected $expectedPath');
      return;
    }
    final descriptor = File('${spriteRoot.path}/$id/$id.atlas');
    if (!await descriptor.exists()) {
      errors.add('missing atlas $assetPath');
      return;
    }
    expectedFiles.add('$id/$id.atlas');
    final parsed = await const AtlasRuntimeParser().parse(descriptor, errors);
    expectedFiles.addAll(parsed.pages.map((page) => '$id/$page'));
    final unowned = parsed.regions.difference(usedRegions);
    final absent = usedRegions.difference(parsed.regions);
    if (unowned.isNotEmpty) errors.add('$id has unowned regions: $unowned');
    if (absent.isNotEmpty) errors.add('$id is missing regions: $absent');
  }

  Future<void> _verifyFileSet(
    Directory root,
    Set<String> expected,
    List<String> errors,
  ) async {
    final actual = <String>{};
    if (await root.exists()) {
      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          actual.add(
            entity.path.substring(root.path.length + 1).replaceAll('\\', '/'),
          );
        }
      }
    }
    final missing = expected.difference(actual).toList()..sort();
    final extra = actual.difference(expected).toList()..sort();
    if (missing.isNotEmpty) errors.add('missing sprite files: $missing');
    if (extra.isNotEmpty) errors.add('unexpected sprite files: $extra');
  }

  void _verifyFrameIds(Set<String> actual, List<String> errors) {
    final expected = _expectedFrameIds();
    final missing = expected.difference(actual).toList()..sort();
    final extra = actual.difference(expected).toList()..sort();
    if (missing.isNotEmpty) errors.add('missing sprite IDs: $missing');
    if (extra.isNotEmpty) errors.add('unused sprite IDs: $extra');
  }

  Set<String> _expectedFrameIds() {
    final ids = <String>{};
    for (final spec in sources.units) {
      for (final animation in spec.animations) {
        for (var index = 0; index < animation.sourceColumns.length; index++) {
          ids.add('unit.${spec.name}.${animation.action}.$index');
        }
      }
    }
    ids
      ..addAll(TechnologyId.values.map((id) => 'technology.${id.name}'))
      ..addAll(CityBuildingType.values.map((type) => 'building.${type.name}'))
      ..addAll(WonderType.values.map((type) => 'wonder.${type.name}'))
      ..addAll(List.generate(36, (index) => 'dice.$index'));
    _addCityFrames(ids);
    _addImprovementFrames(ids);
    ids.addAll(
      (sources.object('icons')['frames'] as Map<String, dynamic>).keys,
    );
    return ids;
  }

  void _addCityFrames(Set<String> ids) {
    const profiles = [
      'growthCivic',
      'tradeKnowledgeMaritime',
      'militaryFortified',
      'industryModern',
    ];
    for (final profile in profiles) {
      for (var level = 0; level < 6; level++) {
        ids.add('city.$profile.$level');
      }
    }
  }

  void _addImprovementFrames(Set<String> ids) {
    for (final type in FieldImprovementType.values) {
      for (var era = 0; era < 4; era++) {
        ids.add('improvement.${type.name}.$era');
      }
    }
  }
}
