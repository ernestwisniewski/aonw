import 'package:aonw/editor/dialogs/editor_dialogs.dart';
import 'package:aonw/editor/domain/map_draft.dart';
import 'package:aonw/editor/engine/editor_state.dart';
import 'package:aonw/editor/engine/editor_world.dart';
import 'package:aonw/editor/providers/editor_providers.dart';
import 'package:aonw/editor/services/map_exporter.dart';
import 'package:aonw/editor/services/map_saver.dart';
import 'package:aonw/editor/widgets/editor_bottom_toolbar.dart';
import 'package:aonw/editor/widgets/editor_options_overlay.dart';
import 'package:aonw/editor/widgets/editor_top_bar.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/map/application/map_image_source.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw/map/widgets/dice_roll_test_overlay.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_screen_header.dart';
import 'package:aonw/shared/widgets/viewport_gesture_layer.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'map_editor_screen_lifecycle.dart';
part 'map_editor_screen_persistence_support.dart';

class MapEditorScreen extends ConsumerStatefulWidget {
  final MapSelection? selection;

  const MapEditorScreen({this.selection, super.key});

  @override
  ConsumerState<MapEditorScreen> createState() => _MapEditorScreenState();
}

class _MapEditorScreenState extends ConsumerState<MapEditorScreen> {
  EditorWorld? _game;
  MapDraft? _activeDraft;
  MapImageSource? _activeImageSource;
  String? _pendingImageSourcePath;
  bool _pendingImageSliceMode = false;
  MapViewMode _viewMode = MapViewMode.tile;
  bool _hasGraphicMode = false;
  bool _showDiceRollTestOverlay = false;
  bool _isInitializing = true;
  Object? _loadError;
  double _defaultZoom = 1.0;

  bool _syncingFromTile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeEditor());
  }

  void _updateState(VoidCallback update) => setState(update);

  Future<void> _handleExport() async {
    final draft = ref.read(editorMapProvider);
    if (draft == null) return;

    final initialFilename = draft.mapName?.isNotEmpty == true
        ? draft.mapName!
        : 'map';
    final result = await showExportMapDialog(
      context,
      initialFilename: initialFilename,
    );
    if (!mounted || result == null) return;

    try {
      switch (result.destination) {
        case ExportMapDestination.share:
          await MapExporter.share(draft, result.filename);
        case ExportMapDestination.saveToDisk:
          final savedPath = await MapExporter.saveToDisk(
            draft,
            result.filename,
          );
          if (!mounted) return;
          if (savedPath != null) {
            _showSnackBar('Saved to $savedPath');
          }
      }
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Export failed: $error');
    }
  }

  Future<void> _handleReplaceImage() async {
    final pickedPath = await MapSaver.pickImage();
    if (!mounted || pickedPath == null) return;
    final shouldSaveAsSlices = _pendingImageSourcePath != null
        ? _pendingImageSliceMode
        : _activeImageSource is SavedMapSliceSetSource;
    final options = await showMapImageUploadOptionsDialog(
      context,
      imageSourcePath: pickedPath,
      initialSliceImage: shouldSaveAsSlices,
    );
    if (!mounted || options == null) return;
    final draft = ref.read(editorMapProvider);
    final mapName = draft?.mapName;
    var persistedImmediately = false;

    try {
      MapImageSource imageSource;
      if (draft != null && mapName != null && mapName.trim().isNotEmpty) {
        imageSource = await _saveMapImage(
          sourcePath: pickedPath,
          mapName: mapName,
          draft: draft,
          sliceImage: options.sliceImage,
        );
        persistedImmediately = true;
      } else {
        imageSource = SavedMapSingleImageSource(pickedPath);
      }
      await _game?.loadImageOverlay(imageSource);
      if (!mounted) return;
      setState(() {
        _activeImageSource = imageSource;
        _pendingImageSourcePath = persistedImmediately ? null : pickedPath;
        _pendingImageSliceMode = persistedImmediately
            ? false
            : options.sliceImage;
        _hasGraphicMode = true;
        _viewMode = MapViewMode.graphic;
      });
      _game?.viewMode = MapViewMode.graphic;
      _showSnackBar(
        persistedImmediately ? 'Map image saved' : 'Map image replaced',
      );
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Image import failed: $error');
      return;
    }
  }

  Future<void> _handleSave() async {
    final draft = ref.read(editorMapProvider);
    if (draft == null) return;

    final saveRequest = await showSaveMapDialog(
      context,
      initialName: draft.mapName ?? 'map',
    );
    if (!mounted || saveRequest == null) return;

    draft.mapName = saveRequest.name; // MapSaver.save() sanitizes internally

    try {
      await MapSaver.save(draft);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Save failed: $error');
      return;
    }

    final safeName = draft.mapName!; // read back sanitized name after save

    MapImageSource? savedImageSource;
    final saveDialogImageSelected = saveRequest.imageSourcePath != null;
    final imageSourcePath =
        saveRequest.imageSourcePath ?? _pendingImageSourcePath;
    if (imageSourcePath != null) {
      try {
        final sliceImage = saveDialogImageSelected
            ? saveRequest.sliceImage
            : _pendingImageSliceMode;
        savedImageSource = await _saveMapImage(
          sourcePath: imageSourcePath,
          mapName: safeName,
          draft: draft,
          sliceImage: sliceImage,
        );
      } catch (error) {
        if (!mounted) return;
        _showSnackBar('Map "$safeName" saved, but image import failed: $error');
        return;
      }
    }

    if (!mounted) return;
    _showSnackBar('Map "$safeName" saved');

    final resolvedImageSource =
        savedImageSource ?? await MapSaver.resolveImageSource(safeName);
    if (!mounted) return;

    setState(() {
      _activeImageSource = resolvedImageSource;
      _pendingImageSourcePath = null;
      _pendingImageSliceMode = false;
      _hasGraphicMode = resolvedImageSource != null;
    });

    if (resolvedImageSource != null) {
      await _game?.loadImageOverlay(resolvedImageSource);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = ref.watch(editorMapProvider);
    final editorState = ref.watch(editorStateProvider);
    ref.watch(hexDisplayDefaultsBootstrapProvider);
    final displaySettings = ref.watch(hexDisplayProvider);

    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: GameUiTheme.bg,
        body: Center(
          child: CircularProgressIndicator(color: GameUiTheme.textSecondary),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: GameUiTheme.bg,
        body: GameUiEmptyState(
          icon: Icons.error_outline,
          title: l10n.editorOpenMapErrorTitle,
          message: '$_loadError',
          action: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _initializeEditor,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(GameText.actionLabel(l10n.retryAction)),
                style: GameUiTheme.outlinedButtonStyle(
                  foreground: GameUiTheme.goldLight,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.go('/editor'),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: Text(GameText.actionLabel(l10n.backAction)),
                style: GameUiTheme.textButtonStyle(
                  foreground: GameUiTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // When the user changes the toolbar, repaint the selected tile.
    // Suppressed when syncing from tile tap to avoid overwriting with stale state.
    ref.listen(editorStateProvider, (prev, next) {
      if (prev != next && !_syncingFromTile) {
        _game?.editorState = next;
        _game?.repaintSelected();
      }
    });

    _ensureGame(draft, editorState, displaySettings);
    final game = _game;

    return Scaffold(
      backgroundColor: GameUiTheme.bg,
      body: Stack(
        children: [
          if (game != null)
            Positioned.fill(
              child: ViewportGestureLayer(
                game: game,
                child: GameWidget(game: game),
              ),
            ),
          if (_showDiceRollTestOverlay)
            const Positioned.fill(child: DiceRollTestOverlay()),
          Column(
            children: [
              EditorTopBar(
                draft: draft,
                onAddColumn: () => _resizeMap((game) => game.addColumn()),
                onRemoveColumn: () => _resizeMap((game) => game.removeColumn()),
                onAddRow: () => _resizeMap((game) => game.addRow()),
                onRemoveRow: () => _resizeMap((game) => game.removeRow()),
                onReplaceImage: _handleReplaceImage,
                onSave: _handleSave,
                onExport: _handleExport,
                onClose: () => context.go('/editor'),
              ),
              const Spacer(),
              if (draft != null)
                EditorBottomToolbar(
                  editorState: editorState,
                  displaySettings: displaySettings,
                  defaultZoom: _defaultZoom,
                  onDefaultZoomChanged: (zoom) {
                    _game?.defaultZoom = zoom;
                  },
                ),
            ],
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: EditorOptionsOverlay(
                  viewMode: _viewMode,
                  allowGraphicMode: _hasGraphicMode,
                  onViewModeChanged: _setViewMode,
                  onSave: _handleSave,
                  showTerrain: displaySettings.showTerrain,
                  showResources: displaySettings.showResources,
                  showHeightBadge: displaySettings.showHeightBadge,
                  showCitySites: displaySettings.showCitySites,
                  showCityGrowth: displaySettings.showCityGrowth,
                  showDiceRollTest: _showDiceRollTestOverlay,
                  onToggleTerrain: () =>
                      ref.read(hexDisplayProvider.notifier).toggleTerrain(),
                  onToggleResources: () =>
                      ref.read(hexDisplayProvider.notifier).toggleResources(),
                  onToggleHeightBadge: () =>
                      ref.read(hexDisplayProvider.notifier).toggleHeightBadge(),
                  onToggleCitySites: () =>
                      ref.read(hexDisplayProvider.notifier).toggleCitySites(),
                  onToggleCityGrowth: () =>
                      ref.read(hexDisplayProvider.notifier).toggleCityGrowth(),
                  onToggleDiceRollTest: () {
                    setState(() {
                      _showDiceRollTestOverlay = !_showDiceRollTestOverlay;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
