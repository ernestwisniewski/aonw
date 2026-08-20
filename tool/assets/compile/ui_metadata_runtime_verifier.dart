import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

final class UiMetadataRuntimeVerifier {
  const UiMetadataRuntimeVerifier(this.runtimeRoot);

  final Directory runtimeRoot;

  Future<List<String>> verify() async {
    final errors = <String>[];
    await _verifyUi(errors);
    await _verifyMetadata(errors);
    return errors;
  }

  Future<void> _verifyUi(List<String> errors) async {
    final root = Directory('${runtimeRoot.path}/ui');
    final files = await _relativeFiles(root);
    if (!_sameSet(files, const {'logo.webp'})) {
      errors.add('runtime UI files must be exactly [logo.webp], found $files');
      return;
    }
    final image = img.decodeWebP(
      await File('${root.path}/logo.webp').readAsBytes(),
    );
    if (image == null || image.width != 768 || image.height != 512) {
      errors.add('runtime logo must be a decodable 768x512 WebP');
    }
  }

  Future<void> _verifyMetadata(List<String> errors) async {
    final root = Directory('${runtimeRoot.path}/metadata');
    const name = 'animation_frame_adjustments.json';
    final files = await _relativeFiles(root);
    if (!_sameSet(files, const {name})) {
      errors.add(
        'runtime metadata files must be exactly [$name], found $files',
      );
      return;
    }
    final value = jsonDecode(await File('${root.path}/$name').readAsString());
    if (value is! Map<String, dynamic> || value['version'] != 2) {
      errors.add('runtime animation adjustments must use version 2');
    }
  }

  Future<Set<String>> _relativeFiles(Directory root) async {
    final files = <String>{};
    if (!await root.exists()) return files;
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        files.add(
          entity.path.substring(root.path.length + 1).replaceAll('\\', '/'),
        );
      }
    }
    return files;
  }

  bool _sameSet(Set<String> left, Set<String> right) =>
      left.length == right.length && left.containsAll(right);
}
