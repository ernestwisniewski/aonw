import 'dart:convert';
import 'dart:ui' as ui;

import 'package:aonw/shared/assets/atlas_store.dart';
import 'package:aonw/shared/assets/sprite_frame_id.dart';
import 'package:aonw/shared/assets/texture_packer_sprite_frame_repository.dart';
import 'package:flutter/services.dart';

final class WebpAssetProbeResult {
  const WebpAssetProbeResult({
    required this.atlasCount,
    required this.frameCount,
    required this.pageCount,
  });

  final int atlasCount;
  final int frameCount;
  final int pageCount;
}

Future<WebpAssetProbeResult> probeBundledWebpAssets({
  AssetBundle? bundle,
}) async {
  final assetBundle = bundle ?? rootBundle;
  final manifestContents = await assetBundle.loadString(
    TexturePackerSpriteFrameRepository.manifestPath,
  );
  final manifest = jsonDecode(manifestContents);
  if (manifest is! Map<String, dynamic> || manifest['version'] != 1) {
    throw const FormatException('Unsupported sprite manifest');
  }
  final atlases = (manifest['atlases'] as Map<String, dynamic>)
      .cast<String, String>();
  final frames = (manifest['frames'] as Map<String, dynamic>)
      .cast<String, Map<String, dynamic>>();
  final repository = TexturePackerSpriteFrameRepository(
    store: AtlasStore(bundle: assetBundle),
  );
  var pageCount = 0;
  try {
    for (final atlas in atlases.entries) {
      final pagePaths = await _atlasPagePaths(assetBundle, atlas.value);
      if (pagePaths.isEmpty) {
        throw StateError('${atlas.key} has no WebP pages');
      }
      for (final pagePath in pagePaths) {
        await _decodeWebp(assetBundle, pagePath);
        pageCount++;
      }
      final frameIds = frames.entries
          .where((entry) => entry.value['atlas'] == atlas.key)
          .map((entry) => SpriteFrameId(entry.key))
          .toList(growable: false);
      if (frameIds.isEmpty) {
        throw StateError('${atlas.key} has no semantic frames');
      }
      for (final id in frameIds) {
        final frame = await repository.load(id);
        if (frame.source.isEmpty ||
            frame.originalSize.isEmpty ||
            !frame.statusTop.isFinite) {
          throw StateError('$id has invalid decoded geometry');
        }
      }
      repository.disposeAtlas(atlas.key);
    }
    await _decodeLogo(assetBundle);
    return WebpAssetProbeResult(
      atlasCount: atlases.length,
      frameCount: frames.length,
      pageCount: pageCount,
    );
  } finally {
    repository.dispose();
  }
}

Future<List<String>> _atlasPagePaths(
  AssetBundle bundle,
  String atlasPath,
) async {
  final descriptor = await bundle.loadString(atlasPath);
  final parent = atlasPath.substring(0, atlasPath.lastIndexOf('/'));
  return const LineSplitter()
      .convert(descriptor)
      .map((line) => line.trim())
      .where((line) => line.endsWith('.webp'))
      .map((name) => '$parent/$name')
      .toList(growable: false);
}

Future<void> _decodeWebp(AssetBundle bundle, String path) async {
  if (!path.startsWith('assets/runtime/sprites/') || !path.endsWith('.webp')) {
    throw FormatException('Unexpected atlas page path: $path');
  }
  final data = await bundle.load(path);
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
  try {
    final frame = await codec.getNextFrame();
    try {
      if (frame.image.width <= 0 ||
          frame.image.height <= 0 ||
          frame.image.width > 2048 ||
          frame.image.height > 2048) {
        throw StateError(
          '$path decoded to ${frame.image.width}x${frame.image.height}',
        );
      }
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

Future<void> _decodeLogo(AssetBundle bundle) async {
  const path = 'assets/runtime/ui/logo.webp';
  final data = await bundle.load(path);
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
  try {
    final frame = await codec.getNextFrame();
    try {
      if (frame.image.width != 768 || frame.image.height != 512) {
        throw StateError(
          '$path decoded to ${frame.image.width}x${frame.image.height}',
        );
      }
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}
