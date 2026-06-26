import 'dart:async';
import 'dart:math' as math;

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/turn.dart';
import 'package:aonw/game/presentation/formatters/combat_modifier_labels.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/providers/game_state_provider.dart';
import 'package:aonw/game/presentation/providers/hud_command_dispatcher_provider.dart';
import 'package:aonw/game/presentation/providers/map_inspection_provider.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/worker_action_panel_view_model.dart';
import 'package:aonw/game/presentation/widgets/hud/action_deck/hud_action_line.dart';
import 'package:aonw/game/presentation/widgets/hud/combat/hud_combat_preview.dart';
import 'package:aonw/game/presentation/widgets/hud/command/hud_command_line.dart';
import 'package:aonw/game/presentation/widgets/hud/command/hud_command_line_view_model.dart';
import 'package:aonw/game/presentation/widgets/hud/layout/hud_layout_metrics.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/selection/hud_selection_context_line.dart';
import 'package:aonw/game/presentation/widgets/hud/turn/turn_action_hint.dart';
import 'package:aonw/game/presentation/widgets/onboarding/first_turn_coachmark_targets.dart';
import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/selection_info/selection_info.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/player_color_theme.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'hud_action_deck_detail_modal.dart';
part 'hud_action_deck_combat_modal.dart';
part 'hud_action_deck_combat_dialog.dart';
part 'hud_action_deck_combat_explanation.dart';
part 'hud_action_deck_combat_forecast.dart';
part 'hud_action_deck_combat_hp_ring.dart';
part 'hud_action_deck_commands.dart';
part 'hud_action_deck_compact_widgets.dart';
part 'hud_action_deck_auto_flow.dart';
part 'hud_action_deck_auto_flow_decisions.dart';
part 'hud_action_deck_auto_flow_manual_targets.dart';
part 'hud_action_deck_auto_flow_predicates.dart';
part 'hud_action_deck_auto_flow_research.dart';
part 'hud_action_deck_auto_flow_signature.dart';
part 'hud_action_deck_layout.dart';

class HudActionDeck extends ConsumerStatefulWidget {
  const HudActionDeck({
    required this.animatingUnitIdsListenable,
    required this.gameSave,
    required this.activePlayerId,
    required this.activePlayerCanAct,
    required this.gameState,
    required this.readyToEndTurn,
    this.remainingActionCount = 0,
    this.currentActionIndex = -1,
    this.turnActionOptions = const [],
    required this.actionHintLabel,
    required this.nextActionObjectiveAdvice,
    required this.selection,
    required this.openSelectionDetailChipId,
    required this.selectionActions,
    required this.cityFoundingDraft,
    required this.combatPreview,
    required this.cityRuleset,
    required this.technologyRuleset,
    required this.useBottomGlobalActions,
    required this.mainGlobalActions,
    required this.activityLogAvailable,
    required this.activityLogModeActive,
    this.showSelectionInfo = true,
    this.selectionDetailPeek = false,
    this.panelOpen = false,
    this.cityProductionPanelOpen = false,
    required this.onToggleSelectionDetail,
    required this.onCloseSelectionDetail,
    super.key,
  });

  static const double actionLineHeight = SelectionActionBar.actionChipHeight;
  static const double commandLineHeight =
      HudActionDeckMetrics.commandLineHeight;
  static const double verticalPadding =
      HudSelectionContextMetrics.verticalPadding;
  static const double wideMaxWidth = 840;
  static const double panelOpenMaxWidth = 520;
  static const double compactLandscapeMaxWidth = 760;
  static const double compactCommandLineWidth = 148;
  static const double compactLandscapeSideMenuReserve = 64;
  static const double collapsedHeight =
      commandLineHeight + verticalPadding * 2 + 10;
  static const double expandedBottomPadding = 188;
  final ValueListenable<Set<String>> animatingUnitIdsListenable;
  final GameSave gameSave;
  final String activePlayerId;
  final bool activePlayerCanAct;
  final GameState? gameState;
  final bool readyToEndTurn;
  final int remainingActionCount;
  final int currentActionIndex;
  final List<HudTurnActionOption> turnActionOptions;
  final String? actionHintLabel;
  final GameObjectiveAdvice? nextActionObjectiveAdvice;
  final SelectionViewModel? selection;
  final String? openSelectionDetailChipId;
  final List<Widget> selectionActions;
  final CityFoundingDraft? cityFoundingDraft;
  final HudCombatPreview? combatPreview;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final bool useBottomGlobalActions;
  final List<Widget> mainGlobalActions;
  final bool activityLogAvailable;
  final bool activityLogModeActive;
  final bool showSelectionInfo;
  final bool selectionDetailPeek;
  final bool panelOpen;
  final bool cityProductionPanelOpen;
  final ValueChanged<String> onToggleSelectionDetail;
  final VoidCallback onCloseSelectionDetail;

  @override
  ConsumerState<HudActionDeck> createState() => _HudActionDeckState();
}

class _HudActionDeckState extends ConsumerState<HudActionDeck> {
  late final ValueNotifier<_SelectionDetailModalModel?> _detailNotifier;
  late final ValueNotifier<HudCombatPreview?> _combatPreviewNotifier;
  bool _detailModalOpen = false;
  bool _combatModalOpen = false;
  bool _autoActionFlowEnabled = false;
  bool _autoTurnFlowEnabled = false;
  bool _autoTurnFlowQueued = false;
  bool _autoTurnFlowInFlight = false;
  bool _autoTurnFlowPrimed = false;
  bool _autoTurnFlowAdvancedThisTurn = false;
  bool _compactDeckCollapsed = false;
  String? _lastRequestedDetailKey;
  String? _lastRequestedCombatPreviewKey;
  String? _lastAutoTurnFlowSignature;
  String? _autoTurnFlowContextKey;
  String? _lastManualAutoTargetKey;
  String? _pausedManualAutoTargetKey;
  BuildContext? _detailModalContext;
  BuildContext? _combatModalContext;
  bool _actionCompletionPulseVisible = false;
  late int _lastObservedActionTurn;
  late int _lastObservedActionCount;

  int get _visibleTurnActionCount {
    if (widget.turnActionOptions.isNotEmpty) {
      return widget.turnActionOptions.length;
    }
    return widget.remainingActionCount < 0 ? 0 : widget.remainingActionCount;
  }

  bool get _canShowSelection =>
      widget.showSelectionInfo &&
      widget.selection != null &&
      widget.cityFoundingDraft == null;

  bool get _cityExpansionSelectionActive {
    final pendingAction = widget.gameState?.pendingAction;
    return pendingAction is PendingCityExpansionSelection &&
        pendingAction.ownerPlayerId == widget.activePlayerId;
  }

  bool get _cityExpansionSelectionReady {
    final pendingAction = widget.gameState?.pendingAction;
    if (pendingAction is! PendingCityExpansionSelection ||
        pendingAction.ownerPlayerId != widget.activePlayerId) {
      return false;
    }
    for (final city in widget.gameState?.cities ?? const <GameCity>[]) {
      if (city.id == pendingAction.cityId &&
          city.preferredExpansionHex != null) {
        return true;
      }
    }
    return false;
  }

  SelectionDetailViewModel? _activeDetail(AppLocalizations l10n) {
    final actionDetail = _actionDetail(l10n);
    if (actionDetail != null) return actionDetail;

    final selection = widget.selection;
    final chipId = widget.openSelectionDetailChipId;
    if (!_canShowSelection || selection == null || chipId == null) {
      return null;
    }
    return SelectionDetailViewModelFactory.detailFor(chipId, selection, l10n);
  }

  SelectionDetailViewModel? _actionDetail(AppLocalizations l10n) {
    final pendingAction = widget.gameState?.pendingAction;
    if (pendingAction is PendingWorkerActionSelection) {
      final workerAction = widget.selection?.workerAction;
      if (workerAction?.unitId == pendingAction.unitId) {
        return _workerBuildDetail(workerAction!, l10n);
      }
    }
    return null;
  }

  WorkerActionSelectionDetail _workerBuildDetail(
    WorkerActionPanelViewModel workerAction,
    AppLocalizations l10n,
  ) {
    final selectedType = workerAction.selectedImprovementType;
    final optionsKey = workerAction.options
        .map((option) => '${option.improvementType.name}:${option.state.name}')
        .join(',');
    return WorkerActionSelectionDetail(
      chipId: 'workerBuildGuide',
      title: l10n.workerActionBuildDetailTitle,
      contentKey:
          'workerBuild:${workerAction.unitId}:${selectedType?.name ?? 'none'}:$optionsKey',
      workerAction: workerAction,
    );
  }

  @override
  void initState() {
    super.initState();
    _detailNotifier = ValueNotifier<_SelectionDetailModalModel?>(null);
    _combatPreviewNotifier = ValueNotifier<HudCombatPreview?>(null);
    _lastObservedActionTurn = widget.gameSave.turn;
    _lastObservedActionCount = _visibleTurnActionCount;
    widget.animatingUnitIdsListenable.addListener(_onAutoTurnFlowSignal);
  }

  @override
  void dispose() {
    widget.animatingUnitIdsListenable.removeListener(_onAutoTurnFlowSignal);
    _detailNotifier.dispose();
    _combatPreviewNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HudActionDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animatingUnitIdsListenable !=
        widget.animatingUnitIdsListenable) {
      oldWidget.animatingUnitIdsListenable.removeListener(
        _onAutoTurnFlowSignal,
      );
      widget.animatingUnitIdsListenable.addListener(_onAutoTurnFlowSignal);
    }
    _syncAutoTurnFlowAfterUpdate();
    _syncDismissedResearchAction(oldWidget);
    _syncCombatModal();
    _syncDetailModal();
    _syncActionCompletionPulse();
    _queueAutoTurnFlow();
  }

  void _syncActionCompletionPulse() {
    final turn = widget.gameSave.turn;
    final count = _visibleTurnActionCount;
    final sameTurn = turn == _lastObservedActionTurn;
    final actionCompleted = sameTurn && count < _lastObservedActionCount;
    var shouldPulse = _actionCompletionPulseVisible;
    if (!sameTurn || count <= 0 || widget.readyToEndTurn) {
      shouldPulse = false;
    } else if (actionCompleted) {
      shouldPulse = true;
    }

    _lastObservedActionTurn = turn;
    _lastObservedActionCount = count;

    if (shouldPulse == _actionCompletionPulseVisible) return;
    setState(() {
      _actionCompletionPulseVisible = shouldPulse;
    });
  }

  void _clearActionCompletionPulse() {
    if (!_actionCompletionPulseVisible) return;
    setState(() => _actionCompletionPulseVisible = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAutoTurnFlowAfterUpdate();
    _syncCombatModal();
    _syncDetailModal();
    _queueAutoTurnFlow();
  }

  void _setAutoTurnFlowEnabled(bool enabled) {
    if (_autoTurnFlowEnabled == enabled) return;
    setState(() {
      _autoTurnFlowEnabled = enabled;
      _lastAutoTurnFlowSignature = null;
    });
    _queueAutoTurnFlow(force: enabled);
  }

  void _setAutoActionFlowEnabled(bool enabled) {
    if (_autoActionFlowEnabled == enabled) return;
    setState(() {
      _autoActionFlowEnabled = enabled;
      if (enabled) {
        _autoTurnFlowPrimed = true;
      } else {
        _autoTurnFlowPrimed = false;
        _autoTurnFlowAdvancedThisTurn = false;
      }
      if (enabled) _clearDismissedResearchAction(_researchActionKey());
      _lastAutoTurnFlowSignature = null;
    });
    _queueAutoTurnFlow(force: enabled);
  }

  @override
  Widget build(BuildContext context) {
    return _buildLayout(context);
  }

  void _toggleCompactDeck() {
    setState(() => _compactDeckCollapsed = !_compactDeckCollapsed);
  }
}
