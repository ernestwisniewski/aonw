import 'dart:convert';

import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustment_catalog.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustment_external_loader.dart';
import 'package:flutter/services.dart';

abstract final class AnimationFrameAdjustmentCatalogCache {
  static AnimationFrameAdjustmentCatalog? _catalog;

  static Future<AnimationFrameAdjustmentCatalog> load({
    AssetBundle? bundle,
    bool forceReload = false,
  }) async {
    if (!forceReload) {
      final cached = _catalog;
      if (cached != null) return cached;
    }

    final resolvedBundle = bundle ?? rootBundle;
    final externalJson = await loadExternalAnimationFrameAdjustmentsJson();
    if (externalJson != null) {
      try {
        final decoded = jsonDecode(externalJson);
        final catalog = AnimationFrameAdjustmentCatalog.fromJson(decoded);
        _catalog = catalog;
        return catalog;
      } on Object {
        // Fall back to the bundled asset when the desktop override is invalid.
      }
    }

    try {
      final raw = await resolvedBundle.loadString(
        AnimationFrameAdjustmentCatalog.assetPath,
      );
      final decoded = jsonDecode(raw);
      final catalog = AnimationFrameAdjustmentCatalog.fromJson(decoded);
      _catalog = catalog;
      return catalog;
    } on Object {
      const empty = AnimationFrameAdjustmentCatalog.empty();
      _catalog = empty;
      return empty;
    }
  }

  static void replace(AnimationFrameAdjustmentCatalog catalog) {
    _catalog = catalog;
  }

  static void clearForTesting() {
    _catalog = null;
  }
}
