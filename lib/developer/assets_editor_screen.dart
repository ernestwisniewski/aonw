import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/developer/asset_adjustment_file_store.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustments.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/assets/board_asset_cap.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/improvements/field_improvement_sprite_catalog.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite_catalog.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/assets/sprite_frame_id.dart';
import 'package:aonw/shared/assets/sprite_frames.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'assets_editor_toolbar.dart';
part 'assets_editor_preview_widgets.dart';
part 'assets_editor_frame_canvas.dart';
part 'assets_editor_frame_strip.dart';
part 'assets_editor_frame_edit_panel.dart';
part 'assets_editor_models.dart';

class AssetsEditorScreen extends StatefulWidget {
  const AssetsEditorScreen({super.key});

  @override
  State<AssetsEditorScreen> createState() => _AssetsEditorScreenState();
}

class _AssetsEditorScreenState extends State<AssetsEditorScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final Stopwatch _stopwatch;
  List<_AssetPreviewModel> _previews = const [];
  final Map<String, int> _selectedFrames = {};
  final Map<String, AnimationFrameAdjustment> _frameAdjustments = {};
  final Map<String, double> _animationFrameDurations = {};
  String? _filterId;
  double _speed = 1;
  bool _paused = false;
  bool _editMode = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    unawaited(_ticker.repeat());
    unawaited(_loadSavedAdjustments());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _previews = _buildPreviews(AppLocalizations.of(context));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableFilters = _availableFilters();
    final filteredPreviews = _filteredPreviews();

    return Scaffold(
      backgroundColor: GameUiTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _AssetsEditorToolbar(
              availableFilters: availableFilters,
              editMode: _editMode,
              filterId: _filterId,
              paused: _paused,
              previewCount: filteredPreviews.length,
              saving: _saving,
              speed: _speed,
              totalCount: _previews.length,
              onFilterChanged: (filterId) {
                setState(() => _filterId = filterId);
              },
              onBack: () => context.go('/'),
              onEditModeChanged: _setEditMode,
              onPauseChanged: _setPaused,
              onSaveAdjustments: _saveAdjustments,
              onSpeedChanged: (value) {
                setState(() => _speed = value);
              },
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _ticker,
                builder: (context, _) {
                  final elapsedSeconds =
                      _stopwatch.elapsedMicroseconds / 1000000 * _speed;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 286,
                      mainAxisExtent: _editMode ? 476 : 252,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredPreviews.length,
                    itemBuilder: (context, index) {
                      final model = filteredPreviews[index];
                      final frameDuration = _animationFrameDurationFor(model);
                      final animatedFrame = _animatedFrameFor(
                        model,
                        elapsedSeconds,
                        frameDuration: frameDuration,
                      );
                      final frame = _editMode
                          ? (_selectedFrames[model.id] ?? animatedFrame)
                          : animatedFrame;
                      final adjustmentKey = _frameAdjustmentKey(model, frame);
                      return _AssetPreviewTile(
                        adjustment:
                            _frameAdjustments[adjustmentKey] ??
                            const AnimationFrameAdjustment(),
                        editMode: _editMode,
                        frameDuration: frameDuration,
                        frameIndex: frame,
                        model: model,
                        onAdjustmentChanged: (adjustment) {
                          setState(() {
                            _frameAdjustments[adjustmentKey] = adjustment;
                          });
                        },
                        onFrameSelected: (frameIndex) {
                          setState(() {
                            _selectedFrames[model.id] = frameIndex;
                          });
                        },
                        onResetAdjustment: () {
                          setState(() {
                            _frameAdjustments.remove(adjustmentKey);
                          });
                        },
                        onAnimationFrameDurationChanged:
                            model.supportsAnimationTiming
                            ? (duration) {
                                setState(() {
                                  _setAnimationFrameDuration(model, duration);
                                });
                              }
                            : null,
                        onResetAnimationFrameDuration:
                            model.supportsAnimationTiming
                            ? () {
                                setState(() {
                                  _animationFrameDurations.remove(
                                    _animationTimingKey(model),
                                  );
                                });
                              }
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_AssetPreviewModel> _buildPreviews(AppLocalizations l10n) {
    final previews = <_AssetPreviewModel>[];
    for (final entry in UnitSpriteCatalog.definitions.entries) {
      final actions = entry.value.actions.entries.toList()
        ..sort((a, b) => a.key.index.compareTo(b.key.index));
      for (final action in actions) {
        final actionLabel = _actionLabel(action.key);
        final definition = entry.value;
        final actionDefinition = action.value;
        previews.add(
          _AssetPreviewModel(
            sequenceId: definition.sequenceIdFor(action.key),
            frameIdFor: definition.sequenceIdFor(action.key).frame,
            filterId: _unitActionFilterId(action.key),
            filterLabel: actionLabel,
            frameCount: actionDefinition.frameCount,
            frameDuration: actionDefinition.frameDuration,
            id: definition.sequenceIdFor(action.key).value,
            kindColor: _actionColor(action.key),
            kindLabel: actionLabel,
            loops: actionDefinition.loops,
            outputSize: ui.Size(
              definition.normalSize.width,
              definition.normalSize.height,
            ),
            useSourceSizeForAdjustmentScale: false,
            title: GameDisplayNames.unitType(l10n, entry.key),
          ),
        );
      }
    }

    for (final type in FieldImprovementSpriteCatalog.improvementTypes) {
      for (final eraColumn in FieldImprovementSpriteCatalog.eraColumns) {
        final frameId = FieldImprovementSpriteCatalog.frameIdFor(
          type: type,
          eraColumn: eraColumn,
        );
        final sequenceId = FieldImprovementSpriteCatalog.sequenceIdFor(
          type: type,
          eraColumn: eraColumn,
        );
        previews.add(
          _AssetPreviewModel(
            sequenceId: sequenceId,
            frameIdFor: (_) => frameId,
            filterId: _improvementFilterId,
            filterLabel: 'Improvement',
            frameCount: 1,
            frameDuration: 1,
            id: sequenceId.value,
            kindColor: _improvementColor,
            kindLabel: 'Improvement',
            loops: false,
            outputSize: BoardAssetCapStyles.improvement.topSize,
            title:
                '${GameDisplayNames.fieldImprovement(l10n, type)} - ${FieldImprovementSpriteCatalog.labelForEraColumn(eraColumn)}',
            useSourceSizeForAdjustmentScale: false,
          ),
        );
      }
    }
    for (var index = 0; index < _diceFrameCount; index++) {
      previews.add(
        _AssetPreviewModel(
          sequenceId: SpriteSequenceId('dice.frame-$index'),
          frameIdFor: (_) => SpriteFrameId('dice.$index'),
          filterId: _diceFilterId,
          filterLabel: 'Dice',
          frameCount: 1,
          frameDuration: 1,
          id: 'dice.$index',
          kindColor: _diceColor,
          kindLabel: 'Dice',
          loops: false,
          outputSize: ui.Size.zero,
          title: 'Dice ${index + 1}',
          useSourceSizeForAdjustmentScale: true,
        ),
      );
    }
    return List.unmodifiable(previews);
  }

  void _setPaused(bool paused) {
    setState(() => _paused = paused);
    if (paused) {
      _stopwatch.stop();
      _ticker.stop();
    } else {
      _stopwatch.start();
      unawaited(_ticker.repeat());
    }
  }

  void _setEditMode(bool editMode) {
    setState(() {
      _editMode = editMode;
      if (editMode) {
        _paused = true;
      }
    });
    if (editMode) {
      _stopwatch.stop();
      _ticker.stop();
    }
  }

  Future<void> _loadSavedAdjustments() async {
    final catalog = await AnimationFrameAdjustmentCatalogCache.load();
    if (!mounted) return;
    setState(() {
      _frameAdjustments
        ..clear()
        ..addAll(catalog.frames);
      _animationFrameDurations
        ..clear()
        ..addAll(catalog.animationFrameDurations);
    });
  }

  Future<void> _saveAdjustments() async {
    if (_saving) return;
    setState(() => _saving = true);
    final catalog = AnimationFrameAdjustmentCatalog(
      frames: Map.unmodifiable({
        for (final entry in _frameAdjustments.entries)
          if (!entry.value.isZero) entry.key: entry.value,
      }),
      animationFrameDurations: _savedAnimationFrameDurations(),
    );
    AssetAdjustmentSaveResult result;
    try {
      result = await saveAssetAdjustmentsJson(catalog.toPrettyJson());
      if (result.saved) {
        AnimationFrameAdjustmentCatalogCache.replace(catalog);
      }
    } on Object catch (error) {
      result = AssetAdjustmentSaveResult(
        saved: false,
        message: 'Could not save asset config: $error',
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.saved
            ? const Color(0xFF1B5E20)
            : GameUiTheme.danger,
      ),
    );
  }
}
