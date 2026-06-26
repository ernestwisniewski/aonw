import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/action_deck/hud_action_deck.dart';
import 'package:aonw/game/presentation/widgets/hud/combat/hud_combat_preview.dart';
import 'package:aonw/game/presentation/widgets/hud/turn/turn_action_hint.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HudActionDeckSlot extends StatelessWidget {
  const HudActionDeckSlot({
    required this.animatingUnitIdsListenable,
    required this.gameSave,
    required this.activePlayerId,
    required this.activePlayerCanAct,
    required this.gameState,
    required this.readyToEndTurn,
    required this.remainingActionCount,
    required this.currentActionIndex,
    required this.turnActionOptions,
    required this.actionHintLabel,
    required this.nextActionObjectiveAdvice,
    required this.selection,
    required this.openSelectionDetailChipId,
    required this.selectionDetailPeek,
    required this.selectionActions,
    required this.cityFoundingDraft,
    required this.combatPreview,
    required this.cityRuleset,
    required this.technologyRuleset,
    required this.useBottomGlobalActions,
    required this.mainGlobalActions,
    required this.activityLogAvailable,
    required this.activityLogModeActive,
    required this.showSelectionInfo,
    required this.panelOpen,
    required this.cityProductionPanelOpen,
    required this.onToggleSelectionDetail,
    required this.onCloseSelectionDetail,
    super.key,
  });

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
  final bool selectionDetailPeek;
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
  final bool panelOpen;
  final bool cityProductionPanelOpen;
  final ValueChanged<String> onToggleSelectionDetail;
  final VoidCallback onCloseSelectionDetail;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: HudActionDeck(
        animatingUnitIdsListenable: animatingUnitIdsListenable,
        gameSave: gameSave,
        activePlayerId: activePlayerId,
        activePlayerCanAct: activePlayerCanAct,
        gameState: gameState,
        readyToEndTurn: readyToEndTurn,
        remainingActionCount: remainingActionCount,
        currentActionIndex: currentActionIndex,
        turnActionOptions: turnActionOptions,
        actionHintLabel: actionHintLabel,
        nextActionObjectiveAdvice: nextActionObjectiveAdvice,
        selection: selection,
        openSelectionDetailChipId: openSelectionDetailChipId,
        selectionDetailPeek: selectionDetailPeek,
        selectionActions: selectionActions,
        cityFoundingDraft: cityFoundingDraft,
        combatPreview: combatPreview,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        useBottomGlobalActions: useBottomGlobalActions,
        mainGlobalActions: mainGlobalActions,
        activityLogAvailable: activityLogAvailable,
        activityLogModeActive: activityLogModeActive,
        showSelectionInfo: showSelectionInfo,
        panelOpen: panelOpen,
        cityProductionPanelOpen: cityProductionPanelOpen,
        onToggleSelectionDetail: onToggleSelectionDetail,
        onCloseSelectionDetail: onCloseSelectionDetail,
      ),
    );
  }
}
