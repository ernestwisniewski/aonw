part of 'assets_editor_screen.dart';

class _AssetPreviewModel {
  const _AssetPreviewModel({
    required this.animationId,
    required this.assetPath,
    required this.filterId,
    required this.filterLabel,
    required this.frameCount,
    required this.frameDuration,
    required this.id,
    required this.kindColor,
    required this.kindLabel,
    required this.loops,
    required this.outputSize,
    required this.sourceRectFor,
    required this.title,
    this.useSourceSizeForAdjustmentScale = true,
  });

  final String animationId;
  final String assetPath;
  final String filterId;
  final String filterLabel;
  final int frameCount;
  final double frameDuration;
  final String id;
  final Color kindColor;
  final String kindLabel;
  final bool loops;
  final ui.Size outputSize;
  final FutureOr<ui.Rect> Function(ui.Image image, int frameIndex)
  sourceRectFor;
  final String title;
  final bool useSourceSizeForAdjustmentScale;

  bool get supportsAnimationTiming => frameCount > 1;

  ui.Size adjustmentBaseSizeFor(ui.Rect sourceRect) =>
      useSourceSizeForAdjustmentScale ? sourceRect.size : outputSize;
}

class _AssetFilter {
  const _AssetFilter(this.id, this.label);

  final String id;
  final String label;
}

extension _AssetsEditorAdjustmentQueries on _AssetsEditorScreenState {
  List<_AssetFilter> _availableFilters() {
    final filters = <String, _AssetFilter>{};
    for (final preview in _previews) {
      filters.putIfAbsent(
        preview.filterId,
        () => _AssetFilter(preview.filterId, preview.filterLabel),
      );
    }
    return filters.values.toList()
      ..sort((a, b) => _filterOrder(a.id).compareTo(_filterOrder(b.id)));
  }

  List<_AssetPreviewModel> _filteredPreviews() => _filterId == null
      ? _previews
      : _previews.where((it) => it.filterId == _filterId).toList();

  int _animatedFrameFor(
    _AssetPreviewModel model,
    double elapsedSeconds, {
    required double frameDuration,
  }) =>
      (elapsedSeconds / frameDuration).floor() % math.max(model.frameCount, 1);

  String _frameAdjustmentKey(_AssetPreviewModel model, int frameIndex) =>
      AnimationFrameAdjustmentCatalog.frameKey(
        assetPath: model.assetPath,
        animationId: model.animationId,
        frameIndex: frameIndex,
      );

  double _animationFrameDurationFor(_AssetPreviewModel model) {
    final key = _animationTimingKey(model);
    final override = _animationFrameDurations[key];
    if (override != null && override.isFinite && override > 0) {
      return override;
    }
    return model.frameDuration;
  }

  void _setAnimationFrameDuration(
    _AssetPreviewModel model,
    double frameDuration,
  ) {
    final key = _animationTimingKey(model);
    if (_sameDuration(frameDuration, model.frameDuration)) {
      _animationFrameDurations.remove(key);
    } else {
      _animationFrameDurations[key] = frameDuration;
    }
  }

  String _animationTimingKey(_AssetPreviewModel model) =>
      AnimationFrameAdjustmentCatalog.animationKey(
        assetPath: model.assetPath,
        animationId: model.animationId,
      );

  Map<String, double> _savedAnimationFrameDurations() {
    final durations = <String, double>{
      for (final entry in _animationFrameDurations.entries)
        if (entry.value.isFinite && entry.value > 0) entry.key: entry.value,
    };
    for (final model in _previews) {
      if (!model.supportsAnimationTiming) continue;
      final duration = _animationFrameDurationFor(model);
      if (!_sameDuration(duration, model.frameDuration)) {
        durations[_animationTimingKey(model)] = duration;
      } else {
        durations.remove(_animationTimingKey(model));
      }
    }
    return Map.unmodifiable(durations);
  }
}

abstract final class _SpriteImageCache {
  static final Map<String, Future<ui.Image>> _images = {};

  static Future<ui.Image> load(String assetPath) {
    return _images.putIfAbsent(assetPath, () async {
      final bytes = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    });
  }
}

class _LoadedAssetFrame {
  const _LoadedAssetFrame({required this.sourceRect});

  final ui.Rect sourceRect;
}

abstract final class _AssetFrameLoader {
  static final Map<String, Future<_LoadedAssetFrame>> _frames = {};

  static Future<_LoadedAssetFrame> load(
    _AssetPreviewModel model,
    ui.Image image,
    int frameIndex,
  ) {
    final key = '${model.id}:$frameIndex:${image.width}x${image.height}';
    return _frames.putIfAbsent(key, () async {
      final sourceRect = await model.sourceRectFor(image, frameIndex);
      return _LoadedAssetFrame(sourceRect: sourceRect);
    });
  }
}

const String _improvementFilterId = 'improvement';
const String _diceFilterId = 'dice';
const String _diceAssetPath = 'assets/sprites/dice.png';
const int _diceColumns = 6;
const int _diceRows = 6;
const double _animationTotalDurationMin = 0.2;
const double _animationTotalDurationMax = 8.0;
const Color _improvementColor = Color(0xFF7AA65A);
const Color _diceColor = Color(0xFFCDAF74);

String _unitActionFilterId(UnitSpriteAction action) => action.name;

int _filterOrder(String filterId) {
  if (filterId == _improvementFilterId) {
    return UnitSpriteAction.values.length;
  }
  if (filterId == _diceFilterId) return UnitSpriteAction.values.length + 1;
  final index = UnitSpriteAction.values.indexWhere(
    (action) => action.name == filterId,
  );
  return index == -1 ? UnitSpriteAction.values.length + 2 : index;
}

String _actionLabel(UnitSpriteAction action) => switch (action) {
  UnitSpriteAction.idle => 'Idle',
  UnitSpriteAction.walk => 'Walk',
  UnitSpriteAction.attack => 'Attack',
  UnitSpriteAction.work => 'Work',
  UnitSpriteAction.die => 'Die',
};

Color _actionColor(UnitSpriteAction action) => switch (action) {
  UnitSpriteAction.idle => const Color(0xFF5EA6D8),
  UnitSpriteAction.walk => const Color(0xFF7CB36A),
  UnitSpriteAction.attack => const Color(0xFFD2675F),
  UnitSpriteAction.work => const Color(0xFFD1AA4F),
  UnitSpriteAction.die => const Color(0xFFA56CC1),
};

bool _sameDuration(double a, double b) => (a - b).abs() < 0.000001;
