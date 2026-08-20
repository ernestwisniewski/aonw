import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

import 'atlas_packer.dart';
import 'source_manifest.dart';

const String spriteRuntimeRoot = 'assets/runtime/sprites';

final class SpriteCompilationContext {
  SpriteCompilationContext({
    required this.sources,
    required this.sourceRoot,
    required this.outputRoot,
  });

  final AssetSourceManifest sources;
  final Directory sourceRoot;
  final Directory outputRoot;
  final Map<String, String> _atlases = {};
  final Map<String, Map<String, Object>> _frames = {};

  Future<void> prepare() async {
    if (await outputRoot.exists()) await outputRoot.delete(recursive: true);
    await outputRoot.create(recursive: true);
  }

  Future<AtlasOutput> writeAtlas(
    String atlasId,
    List<AtlasFrameInput> frames, {
    AtlasCompression compression = AtlasCompression.lossless,
    int? gridColumns,
    int? gridRows,
  }) async {
    final output = await writeAtlasFiles(
      atlasId: atlasId,
      frames: frames,
      outputRoot: outputRoot,
      compression: compression,
      gridColumns: gridColumns,
      gridRows: gridRows,
    );
    _atlases[atlasId] = '$spriteRuntimeRoot/$atlasId/$atlasId.atlas';
    _frames.addAll(output.frameEntries);
    return output;
  }

  void setFrame(String id, Map<String, Object> frame) {
    _frames[id] = frame;
  }

  Future<void> writeManifest() async {
    final sortedAtlases = Map.fromEntries(
      _atlases.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final sortedFrames = Map.fromEntries(
      _frames.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final json = <String, Object>{
      'version': 1,
      'sourceManifestSha256': sources.sha256Digest,
      'contracts': {
        'maxPageSize': maxAtlasPageSize,
        'padding': atlasPadding,
        'rotation': false,
        'premultiplyAlpha': false,
        'filterQuality': 'medium',
      },
      'atlases': sortedAtlases,
      'frames': sortedFrames,
    };
    await File('${outputRoot.path}/sprite_manifest.json').writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n',
      flush: true,
    );
  }

  Future<img.Image> decodeVerified(String path, String expectedSha) async {
    final file = File('${sourceRoot.path}/$path');
    if (!await file.exists()) throw StateError('Missing asset master: $path');
    final bytes = await file.readAsBytes();
    final actualSha = sha256.convert(bytes).toString();
    if (actualSha != expectedSha) {
      throw StateError('$path SHA-256 mismatch: $actualSha != $expectedSha');
    }
    return _decodeFile(path, file, bytes);
  }

  Future<img.Image> decode(String path) async {
    final file = File('${sourceRoot.path}/$path');
    if (!await file.exists()) throw StateError('Missing asset master: $path');
    return _decodeFile(path, file, await file.readAsBytes());
  }

  Future<img.Image> _decodeFile(
    String path,
    File source,
    Uint8List bytes,
  ) async {
    if (path.toLowerCase().endsWith('.webp')) {
      await _requireDwebp();
      bytes = await _decodeWebp(path, source);
    }
    final image = img.decodeImage(bytes);
    if (image == null) throw StateError('Cannot decode $path');
    return image.convert(numChannels: 4);
  }

  Future<Uint8List> _decodeWebp(String path, File source) async {
    final basename = path.substring(path.lastIndexOf('/') + 1).split('.').first;
    final decodedFile = File('${outputRoot.path}/.decoded-$basename.png');
    final result = await Process.run('dwebp', [
      '-quiet',
      source.path,
      '-o',
      decodedFile.path,
    ], runInShell: false);
    if (result.exitCode != 0) {
      throw StateError('dwebp failed for $path: ${result.stderr}');
    }
    try {
      return await decodedFile.readAsBytes();
    } finally {
      if (await decodedFile.exists()) await decodedFile.delete();
    }
  }
}

Future<void>? _dwebpCheck;

Future<void> _requireDwebp() => _dwebpCheck ??= () async {
  final result = await Process.run('dwebp', ['-version'], runInShell: false);
  final output = result.stdout is String ? result.stdout as String : '';
  final version = output.split('\n').first.trim();
  if (result.exitCode != 0 || version != requiredCwebpVersion) {
    throw StateError('dwebp $requiredCwebpVersion is required, found $version');
  }
}();
