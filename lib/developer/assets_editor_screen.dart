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
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'assets_editor_toolbar.dart';
part 'assets_editor_preview_widgets.dart';
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
            assetPath: definition.assetPath,
            animationId: action.key.name,
            filterId: _unitActionFilterId(action.key),
            filterLabel: actionLabel,
            frameCount: actionDefinition.frameCount,
            frameDuration: actionDefinition.frameDuration,
            id: '${definition.assetPath}:${action.key.name}',
            kindColor: _actionColor(action.key),
            kindLabel: actionLabel,
            loops: actionDefinition.loops,
            outputSize: ui.Size(
              definition.normalSize.width,
              definition.normalSize.height,
            ),
            sourceRectFor: (image, frameIndex) {
              return definition.sourceRectFor(
                imageSize: Vector2(
                  image.width.toDouble(),
                  image.height.toDouble(),
                ),
                action: actionDefinition,
                column: frameIndex % definition.columns,
              );
            },
            useSourceSizeForAdjustmentScale: false,
            title: GameDisplayNames.unitType(l10n, entry.key),
          ),
        );
      }
    }

    for (final type in FieldImprovementSpriteCatalog.improvementTypes) {
      for (final eraColumn in FieldImprovementSpriteCatalog.eraColumns) {
        final assetPath = FieldImprovementSpriteCatalog.assetPathFor(type);
        previews.add(
          _AssetPreviewModel(
            animationId: FieldImprovementSpriteCatalog.adjustmentIdForVariant(
              type: type,
              eraColumn: eraColumn,
            ),
            assetPath: assetPath,
            filterId: _improvementFilterId,
            filterLabel: 'Improvement',
            frameCount: 1,
            frameDuration: 1,
            id: '$assetPath:${type.name}:era-$eraColumn',
            kindColor: _improvementColor,
            kindLabel: 'Improvement',
            loops: false,
            outputSize: BoardAssetCapStyles.improvement.topSize,
            sourceRectFor: (image, _) {
              return FieldImprovementSpriteCatalog.sourceRectFor(
                imageWidth: image.width,
                imageHeight: image.height,
                type: type,
                eraColumn: eraColumn,
              );
            },
            title:
                '${GameDisplayNames.fieldImprovement(l10n, type)} - ${FieldImprovementSpriteCatalog.labelForEraColumn(eraColumn)}',
            useSourceSizeForAdjustmentScale: false,
          ),
        );
      }
    }
    for (var index = 0; index < _diceColumns * _diceRows; index++) {
      final column = index % _diceColumns;
      final row = index ~/ _diceColumns;
      previews.add(
        _AssetPreviewModel(
          assetPath: _diceAssetPath,
          animationId: 'dice.frame-$index',
          filterId: _diceFilterId,
          filterLabel: 'Dice',
          frameCount: 1,
          frameDuration: 1,
          id: '$_diceAssetPath:frame-$index',
          kindColor: _diceColor,
          kindLabel: 'Dice',
          loops: false,
          outputSize: ui.Size.zero,
          sourceRectFor: (image, _) {
            final cellWidth = image.width / _diceColumns;
            final cellHeight = image.height / _diceRows;
            return ui.Rect.fromLTWH(
              column * cellWidth,
              row * cellHeight,
              cellWidth,
              cellHeight,
            );
          },
          title: 'Dice ${index + 1}',
          useSourceSizeForAdjustmentScale: true,
        ),
      );
    }
    return List.unmodifiable(previews);
  }

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

  List<_AssetPreviewModel> _filteredPreviews() {
    final filter = _filterId;
    if (filter == null) return _previews;
    return _previews.where((preview) => preview.filterId == filter).toList();
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

  int _animatedFrameFor(
    _AssetPreviewModel model,
    double elapsedSeconds, {
    required double frameDuration,
  }) {
    final current = (elapsedSeconds / frameDuration).floor();
    return current % math.max(model.frameCount, 1);
  }

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
