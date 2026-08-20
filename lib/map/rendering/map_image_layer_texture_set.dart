part of 'map_image_layer.dart';

extension _MapImageLayerTextureSet on MapImageLayer {
  Future<void> _loadTextureSet(
    String manifestPath, {
    required int generation,
    ValueChanged<double>? onProgress,
  }) async {
    onProgress?.call(0);
    _clearTextureSet();
    final set = await _textureRepository.loadSet(manifestPath);
    _rejectSupersededSet(set, generation);
    await _activateTextureSet(set);
    _rejectSupersededSet(set, generation);
    onProgress?.call(1);
  }

  Future<void> _importSavedTextureSet(
    SavedMapImageSource source, {
    required int generation,
    ValueChanged<double>? onProgress,
  }) async {
    _clearTextureSet();
    final set = await _textureRepository.importSaved(
      source,
      _savedTextureLayout(),
      onProgress: onProgress,
    );
    _rejectSupersededSet(set, generation);
    await _activateTextureSet(set);
    _rejectSupersededSet(set, generation);
    onProgress?.call(1);
  }

  void _rejectSupersededSet(MapTextureSet set, int generation) {
    if (generation == _loadGeneration) return;
    if (identical(_textureSet, set)) {
      _textureSet = null;
      _textureClipPath = null;
    }
    _textureRepository.disposeSet(set);
    throw StateError('${set.id} texture load was superseded');
  }

  Future<void> _activateTextureSet(MapTextureSet set) async {
    final worldSizeMatches =
        (set.worldSize.width - size.x).abs() < 0.01 &&
        (set.worldSize.height - size.y).abs() < 0.01;
    if (set.cols != _cols || set.rows != _rows || !worldSizeMatches) {
      _textureRepository.disposeSet(set);
      throw StateError(
        '${set.id} texture geometry ${set.cols}x${set.rows} '
        '${set.worldSize} does not match map geometry '
        '${_cols}x$_rows ${Size(size.x, size.y)}',
      );
    }
    if (set.pages.isEmpty) {
      _textureRepository.disposeSet(set);
      throw StateError('${set.id} texture set has no pages');
    }
    _textureSet = set;
    _textureClipPath = _combinedGridClipPath();
    try {
      await _textureRepository.loadPage(set.pages.first);
    } catch (_) {
      if (identical(_textureSet, set)) {
        _textureSet = null;
        _textureClipPath = null;
      }
      _textureRepository.disposeSet(set);
      rethrow;
    }
  }

  void _renderTextureSet(Canvas canvas, MapTextureSet set) {
    final clipBounds = canvas.getLocalClipBounds();
    canvas.save();
    final clipPath = _textureClipPath;
    if (clipPath != null) canvas.clipPath(clipPath);
    for (final page in set.pages) {
      if (clipBounds.isFinite && !page.destination.overlaps(clipBounds)) {
        continue;
      }
      final image = _textureRepository.cachedPage(page);
      if (image == null) {
        _requestTexturePage(page);
        continue;
      }
      canvas.drawImageRect(
        image,
        ui.Offset.zero & page.pixelSize,
        page.destination,
        MapImageLayer._imagePaint,
      );
    }
    canvas.restore();
  }

  void _requestTexturePage(MapTexturePage page) {
    final key = page.cacheKey;
    if (_failedTexturePages.contains(key)) return;
    if (_pendingTexturePages.add(key)) {
      unawaited(
        _textureRepository
            .loadPage(page)
            .then<void>(
              (_) => _pendingTexturePages.remove(key),
              onError: (Object error, StackTrace stackTrace) {
                _pendingTexturePages.remove(key);
                _failedTexturePages.add(key);
                FlutterError.reportError(
                  FlutterErrorDetails(
                    exception: error,
                    stack: stackTrace,
                    library: 'map texture rendering',
                    context: ErrorDescription(
                      'while loading map texture page $key',
                    ),
                  ),
                );
              },
            ),
      );
    }
  }

  void _clearTextureSet() {
    final set = _textureSet;
    if (set != null) _textureRepository.disposeSet(set);
    _textureSet = null;
    _textureClipPath = null;
    _pendingTexturePages.clear();
    _failedTexturePages.clear();
  }
}
