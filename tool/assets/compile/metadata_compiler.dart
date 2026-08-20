import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'source_manifest.dart';

final class MetadataCompiler {
  const MetadataCompiler({
    required this.sources,
    required this.workspace,
    required this.outputRoot,
  });

  final AssetSourceManifest sources;
  final Directory workspace;
  final Directory outputRoot;

  Future<void> compile() async {
    if (await outputRoot.exists()) await outputRoot.delete(recursive: true);
    await outputRoot.create(recursive: true);
    final source = File(
      '${workspace.path}/${sources.animationAdjustmentsPath}',
    );
    if (!await source.exists()) {
      throw StateError('Missing animation adjustment authoring source');
    }
    final bytes = await source.readAsBytes();
    final digest = sha256.convert(bytes).toString();
    if (digest != sources.animationAdjustmentsSha256) {
      throw StateError('Animation adjustment authoring SHA-256 mismatch');
    }
    _validate(jsonDecode(utf8.decode(bytes)));
    await File(
      '${outputRoot.path}/animation_frame_adjustments.json',
    ).writeAsBytes(bytes, flush: true);
  }

  void _validate(Object? value) {
    if (value is! Map<String, dynamic> || value['version'] != 2) {
      throw const FormatException('Animation adjustments must use version 2');
    }
    _validateKeys(value['frames'], frame: true);
    _validateKeys(value['animations'], frame: false);
  }

  void _validateKeys(Object? value, {required bool frame}) {
    if (value is! Map<String, dynamic>) {
      throw FormatException(
        'Animation adjustment ${frame ? 'frames' : 'animations'} must be an object',
      );
    }
    final pattern = frame
        ? RegExp(r'^unit\.[^.]+\.[^.]+\|[0-9]+$')
        : RegExp(r'^unit\.[^.]+\.[^.]+$');
    for (final key in value.keys) {
      if (!pattern.hasMatch(key) || key.contains('assets/')) {
        throw FormatException('Non-semantic animation adjustment key: $key');
      }
    }
  }
}
