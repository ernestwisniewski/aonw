import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

import 'source_manifest.dart';

class UiAssetCompiler {
  const UiAssetCompiler({
    required this.sources,
    required this.sourceRoot,
    required this.outputRoot,
  });

  final AssetSourceManifest sources;
  final Directory sourceRoot;
  final Directory outputRoot;

  Future<void> compile() async {
    if (await outputRoot.exists()) await outputRoot.delete(recursive: true);
    await outputRoot.create(recursive: true);
    final spec = sources.object('ui');
    final sourcePath = spec['logoSource'] as String;
    final bytes = await File('${sourceRoot.path}/$sourcePath').readAsBytes();
    final actualSha = sha256.convert(bytes).toString();
    final expectedSha = spec['logoSha256'] as String;
    if (actualSha != expectedSha) {
      throw StateError('$sourcePath SHA-256 mismatch');
    }
    final source = img.decodeImage(bytes)?.convert(numChannels: 4);
    if (source == null) throw StateError('Cannot decode $sourcePath');
    final logo = img.copyResize(
      source,
      width: 768,
      interpolation: img.Interpolation.average,
    );
    if (logo.width != 768 || logo.height != 512) {
      throw StateError('Compiled logo must preserve the 768x512 aspect ratio');
    }
    await File(
      '${outputRoot.path}/logo.webp',
    ).writeAsBytes(img.encodeWebP(logo), flush: true);
  }
}
