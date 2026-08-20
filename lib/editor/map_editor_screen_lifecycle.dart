part of 'map_editor_screen.dart';

extension _MapEditorScreenLifecycle on _MapEditorScreenState {
  Future<void> _initializeEditor() async {
    _updateState(() {
      _isInitializing = true;
      _loadError = null;
    });

    try {
      if (widget.selection case final selection?) {
        final mapRepository = ref.read(mapRepositoryProvider);
        final sourceMap = await mapRepository.loadMap(selection);
        final imageSource = await mapRepository.resolveImageSource(selection);
        if (!mounted) return;

        final draft = MapDraft.fromWorldMap(sourceMap);
        ref.read(editorMapProvider.notifier).load(draft);
        _updateState(() {
          _activeImageSource = imageSource;
          _pendingImageSourcePath = null;
          _pendingImageSliceMode = false;
          _hasGraphicMode = imageSource != null;
          _viewMode = imageSource != null
              ? MapViewMode.graphic
              : MapViewMode.tile;
          _defaultZoom = draft.defaultZoom;
        });
      } else {
        final created = await _promptForNewMap();
        if (!mounted || !created) return;
      }
    } catch (error) {
      if (!mounted) return;
      _updateState(() => _loadError = error);
    } finally {
      if (mounted) {
        _updateState(() => _isInitializing = false);
      }
    }
  }

  Future<bool> _promptForNewMap() async {
    final config = await showNewMapDialog(context);
    if (!mounted) return false;
    if (config == null) {
      context.go('/editor');
      return false;
    }

    ref
        .read(editorMapProvider.notifier)
        .create(config.cols, config.rows, config.defaultTerrain);
    _updateState(() {
      _activeImageSource = null;
      _pendingImageSourcePath = null;
      _pendingImageSliceMode = false;
      _viewMode = MapViewMode.tile;
      _hasGraphicMode = false;
    });
    return true;
  }

  void _ensureGame(
    MapDraft? draft,
    EditorState editorState,
    HexDisplaySettings displaySettings,
  ) {
    if (draft == null) return;
    if (!identical(_activeDraft, draft)) {
      _activeDraft = draft;
      _game = EditorWorld(
        draft: draft,
        editorState: editorState,
        imageSource: _activeImageSource,
        initialViewMode: _viewMode,
        onTileSelected: _onTileSelected,
        onDefaultZoomChanged: (zoom) => _updateState(() => _defaultZoom = zoom),
        displaySettings: displaySettings,
      );
    }
    _game?.editorState = editorState;
    _game?.viewMode = _viewMode;
    _game?.displaySettings = displaySettings;
  }

  /// Called by EditorGrid when a tile is tapped.
  /// Syncs the toolbar to the tile's current terrain/resource/height.
  void _onTileSelected(int col, int row) {
    final draft = ref.read(editorMapProvider);
    if (draft == null) return;
    final tile = draft.tileAt(col, row);
    final editorState = ref.read(editorStateProvider);
    _syncingFromTile = true;
    ref
        .read(editorStateProvider.notifier)
        .syncToTile(
          terrains: tile?.terrainTags ?? editorState.selectedTerrains.toList(),
          resources: tile?.resources ?? const [],
          objectiveType: _objectiveTypeAt(draft, col, row),
          height: tile?.height ?? 0,
        );
    _syncingFromTile = false;
    // Do NOT repaint here — tapping only selects, does not modify the tile.
    // repaintSelected() is called only when the user changes the toolbar.
  }

  MapObjectiveType? _objectiveTypeAt(MapDraft draft, int col, int row) {
    for (final objective in draft.objectives) {
      if (objective.hex.col == col && objective.hex.row == row) {
        return objective.type;
      }
    }
    return null;
  }

  void _withGame(void Function(EditorWorld game) action) {
    final game = _game;
    if (game == null) return;
    game.editorState = ref.read(editorStateProvider);
    action(game);
  }

  void _setViewMode(MapViewMode value) {
    if (value == MapViewMode.graphic && !_hasGraphicMode) return;
    _updateState(() {
      _viewMode = value;
    });
    _game?.viewMode = value;
  }

  void _resizeMap(void Function(EditorWorld game) action) {
    _withGame((game) {
      action(game);
      game.resizeImageLayer(game.draft.cols, game.draft.rows);
    });
    _updateState(() {});
  }
}
