import 'dart:async';
import 'dart:math' as math;

import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_component.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_option.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map_pill.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_marker_layer.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';

typedef ActionPaletteWorkerOptionCallback =
    void Function(String unitId, String optionId);
typedef ActionPaletteWorkerCallback = void Function(String unitId);
typedef ActionPaletteMovePreviewCallback = void Function(int col, int row);

class ActionPaletteLayer extends Component with LayerAttachment {
  ActionPaletteLayer({
    required this.onPreviewWorkerImprovement,
    required this.onConfirmWorkerImprovement,
    required this.onCancelWorkerActionSelection,
    required this.onConfirmMovePreview,
    this.turnCostLabelBuilder,
    this.confirmationLabelBuilder,
    this.confirmationLabel,
  });

  static const double _unitVerticalOffset = 82;

  final ActionPaletteWorkerOptionCallback onPreviewWorkerImprovement;
  final ActionPaletteWorkerCallback onConfirmWorkerImprovement;
  final ActionPaletteWorkerCallback onCancelWorkerActionSelection;
  final ActionPaletteMovePreviewCallback onConfirmMovePreview;
  final String Function(int turns)? turnCostLabelBuilder;
  final String Function(int turns)? confirmationLabelBuilder;
  final String? confirmationLabel;

  ActionPaletteComponent? _component;
  MapPillComponent? _movePreviewPill;
  String? _paletteKey;
  String? _movePreviewPillKey;

  ActionPaletteComponent? get componentForTesting => _component;

  MapPillComponent? get movePreviewPillForTesting => _movePreviewPill;

  bool get visibleForTesting => _component != null || _movePreviewPill != null;

  Vector2? get positionForTesting =>
      _component?.position.clone() ?? _movePreviewPill?.position.clone();

  void sync({
    required Component parent,
    required GameState state,
    required List<ActionPaletteOption> options,
  }) {
    ensureAttachedTo(parent);
    final pending = state.pendingAction;
    if (pending is PendingWorkerActionSelection) {
      _clearMovePreviewPill();
      _syncWorker(
        parent: parent,
        state: state,
        pending: pending,
        options: options,
      );
      return;
    }

    _clearWorker();
    _syncMovePreviewPill(parent: parent, state: state);
  }

  void _syncWorker({
    required Component parent,
    required GameState state,
    required PendingWorkerActionSelection pending,
    required List<ActionPaletteOption> options,
  }) {
    if (options.isEmpty) {
      _clearWorker();
      return;
    }

    final worker = _workerFor(state, pending.unitId);
    if (worker == null ||
        worker.workerJob != null ||
        worker.workerAssignment != null ||
        !state.canControlUnit(worker)) {
      _clearWorker();
      return;
    }

    final owner = attachedOwner;
    final previewedOptionId = pending.improvementType?.name;
    final position = _worldPositionFor(worker);
    final existing = _component;
    final paletteKey = 'worker:${worker.id}';
    if (existing != null && _paletteKey == paletteKey) {
      existing
        ..position = position
        ..updateOptions(options)
        ..updatePreviewed(previewedOptionId);
      return;
    }

    _clearWorker();
    final unitId = worker.id;
    final component = ActionPaletteComponent(
      options: options,
      previewedOptionId: previewedOptionId,
      onPreview: (optionId) => onPreviewWorkerImprovement(unitId, optionId),
      onConfirm: (_) => onConfirmWorkerImprovement(unitId),
      onCancel: () => onCancelWorkerActionSelection(unitId),
    )..position = position;
    _component = component;
    _paletteKey = paletteKey;
    unawaited(Future<void>.value(owner.add(component)));
  }

  void _syncMovePreviewPill({
    required Component parent,
    required GameState state,
  }) {
    final preview = state.movePreview;
    if (preview == null) {
      _clearMovePreviewPill();
      return;
    }

    final unit = _unitFor(state, preview.unitId);
    if (unit == null || !state.canControlUnit(unit)) {
      _clearMovePreviewPill();
      return;
    }

    final owner = attachedOwner;
    final selected = state.selectedUnitId == preview.unitId;
    final confirmsMove = state.moveCommandActive && selected;
    final position = UnitMarkerLayer.worldPositionFor(
      preview.targetCol,
      preview.targetRow,
    );
    final componentKey =
        'move:${preview.unitId}:${preview.targetCol}:${preview.targetRow}:'
        '${confirmsMove ? 'confirm' : 'cost'}';
    final label = confirmsMove
        ? _moveConfirmationLabel(preview, unit)
        : _moveTurnCostLabel(preview, unit);
    void confirmMovePreview() {
      onConfirmMovePreview(preview.targetCol, preview.targetRow);
    }

    final existing = _movePreviewPill;
    if (existing != null && _movePreviewPillKey == componentKey) {
      existing
        ..position = position
        ..updatePresentation(
          label: label,
          tone: _pillToneFor(preview),
          onTap: confirmsMove ? confirmMovePreview : null,
        );
      return;
    }

    _clearMovePreviewPill();
    final component = MapPillComponent(
      label: label,
      tone: _pillToneFor(preview),
      onTap: confirmsMove ? confirmMovePreview : null,
    )..position = position;
    _movePreviewPill = component;
    _movePreviewPillKey = componentKey;
    unawaited(Future<void>.value(owner.add(component)));
  }

  void clear() {
    _clearWorker();
    _clearMovePreviewPill();
  }

  @override
  void onRemove() {
    clear();
    super.onRemove();
  }

  void _clearWorker() {
    _component?.removeFromParent();
    _component = null;
    _paletteKey = null;
  }

  void _clearMovePreviewPill() {
    _movePreviewPill?.removeFromParent();
    _movePreviewPill = null;
    _movePreviewPillKey = null;
  }

  GameUnit? _workerFor(GameState state, String unitId) {
    for (final unit in state.units) {
      if (unit.id == unitId && unit.type == GameUnitType.worker) {
        return unit;
      }
    }
    return null;
  }

  Vector2 _worldPositionFor(GameUnit unit) {
    return UnitMarkerLayer.worldPositionFor(unit.col, unit.row) +
        Vector2(0, -_unitVerticalOffset);
  }

  GameUnit? _unitFor(GameState state, String unitId) {
    for (final unit in state.units) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }

  String _moveConfirmationLabel(UnitMovementPlan preview, GameUnit unit) {
    final turns = _turnsForPreview(preview, unit);
    final localized = confirmationLabelBuilder?.call(turns);
    if (localized != null && localized.isNotEmpty) return localized;
    return '${confirmationLabel ?? 'Confirm'} (${_formatTurnCost(turns)})';
  }

  String _moveTurnCostLabel(UnitMovementPlan preview, GameUnit unit) {
    final turns = _turnsForPreview(preview, unit);
    return _formatTurnCost(turns);
  }

  int _turnsForPreview(UnitMovementPlan preview, GameUnit unit) {
    if (preview.totalCost <= 0) return 0;
    final movementPerTurn = math.max(
      1,
      UnitMovementBalance.maxMovementPointsForType(unit.type),
    );
    return (preview.totalCost / movementPerTurn).ceil();
  }

  MapPillTone _pillToneFor(UnitMovementPlan preview) {
    return preview.canMoveNow ? MapPillTone.gold : MapPillTone.warning;
  }

  String _formatTurnCost(int turns) {
    return turnCostLabelBuilder?.call(turns) ??
        (turns == 1 ? '1 turn' : '$turns turns');
  }
}
