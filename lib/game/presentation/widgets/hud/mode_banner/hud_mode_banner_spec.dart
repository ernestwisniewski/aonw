import 'package:aonw/game/presentation/widgets/hud/combat/hud_combat_preview.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class HudModeBannerSpec {
  static const cityFoundingId = 'cityFounding';
  static const selectedWorkerActionId = 'selectedWorkerAction';
  static const selectedWorkerMoveToWorkId = 'selectedWorkerMoveToWork';
  static const selectedScoutExploreId = 'selectedScoutExplore';
  static const selectedSettlerCityFoundingId = 'selectedSettlerCityFounding';
  static const selectedSettlerMoveToCitySiteId =
      'selectedSettlerMoveToCitySite';
  static const cityExpansionSelectionId = 'cityExpansionSelection';
  static const moveTargetingId = 'moveTargeting';

  const HudModeBannerSpec({
    required this.id,
    required this.icon,
    required this.accent,
    required this.title,
    required this.instruction,
    this.progress,
    this.details = const [],
    this.primaryAction,
    this.minimizable = true,
  });

  final String id;
  final GameIconData icon;
  final Color accent;
  final String title;
  final String instruction;
  final String? progress;
  final List<String> details;
  final HudModeBannerActionSpec? primaryAction;
  final bool minimizable;

  static HudModeBannerSpec? resolve({
    required AppLocalizations l10n,
    required PendingPlayerAction? pendingAction,
    required CityFoundingDraft? cityFoundingDraft,
    required bool moveTargetingActive,
    HudCombatPreview? combatPreview,
    GameUnit? selectedUnit,
    bool workerActionAvailable = false,
    String? workerActionBlockedReason,
    bool scoutAutoExploreAvailable = false,
    bool canStartCityFounding = false,
    String? cityFoundingBlockedReason,
    bool cityExpansionHexSelected = false,
    bool selectedUnitMoveActionEnabled = false,
    String? selectedUnitMoveActionDisabledReason,
  }) {
    if (cityFoundingDraft != null) {
      return _cityFoundingSpec(l10n, cityFoundingDraft);
    }
    if (pendingAction != null) {
      return _pendingActionSpec(
        l10n,
        pendingAction,
        combatPreview: combatPreview,
        cityExpansionHexSelected: cityExpansionHexSelected,
      );
    }
    if (moveTargetingActive) return _moveTargetingSpec(l10n);
    return _selectedUnitActionHint(
      selectedUnit: selectedUnit,
      workerActionAvailable: workerActionAvailable,
      workerActionBlockedReason: workerActionBlockedReason,
      scoutAutoExploreAvailable: scoutAutoExploreAvailable,
      canStartCityFounding: canStartCityFounding,
      cityFoundingBlockedReason: cityFoundingBlockedReason,
      l10n: l10n,
      selectedUnitMoveActionEnabled: selectedUnitMoveActionEnabled,
      selectedUnitMoveActionDisabledReason:
          selectedUnitMoveActionDisabledReason,
    );
  }
}

HudModeBannerSpec _cityFoundingSpec(
  AppLocalizations l10n,
  CityFoundingDraft draft,
) {
  const required = CityFoundingDraft.requiredControlledHexes;
  final selected = draft.controlledHexes.length;
  return HudModeBannerSpec(
    id: HudModeBannerSpec.cityFoundingId,
    icon: GameIcons.foundCity,
    accent: GameUiTheme.gold,
    title: l10n.modeBannerCityFoundingTitle,
    instruction: draft.canConfirm
        ? l10n.modeBannerCityFoundingInstructionReady
        : l10n.modeBannerCityFoundingInstructionPick(required),
    progress: '$selected/$required',
    minimizable: false,
    primaryAction: draft.canConfirm
        ? HudModeBannerActionSpec(
            icon: GameIcons.flag,
            label: l10n.selectionActionFoundCity,
            accent: GameUiTheme.gold,
          )
        : null,
  );
}

HudModeBannerSpec _pendingActionSpec(
  AppLocalizations l10n,
  PendingPlayerAction action, {
  required HudCombatPreview? combatPreview,
  required bool cityExpansionHexSelected,
}) {
  if (action case PendingAttackTargeting(:final hasDefenderTarget)) {
    return _attackSpec(l10n, hasDefenderTarget ? combatPreview : null);
  }
  if (action is PendingCityWorkedHexSelection) return _workedHexSpec(l10n);
  if (action is PendingCityExpansionSelection) {
    return _cityExpansionSpec(l10n, cityExpansionHexSelected);
  }
  if (action case PendingWorkerActionSelection(:final improvementType)) {
    return _workerPickSpec(l10n, improvementType != null);
  }
  return _secondaryPendingActionSpec(l10n, action);
}

HudModeBannerSpec _secondaryPendingActionSpec(
  AppLocalizations l10n,
  PendingPlayerAction action,
) {
  return switch (action) {
    PendingMerchantTradeRouteSelection() => _merchantTradeSpec(l10n),
    PendingMerchantMoveToCitySelection() => _merchantMoveSpec(l10n),
    PendingResearchSelection() => _researchSpec(l10n),
    PendingUnitTurnSkip() => _turnSkipSpec(l10n),
    PendingCommanderMergeSelection() => _commanderMergeSpec(l10n),
    _ => throw StateError('Pending action already handled: $action'),
  };
}

HudModeBannerSpec _attackSpec(
  AppLocalizations l10n,
  HudCombatPreview? preview,
) {
  return HudModeBannerSpec(
    id: 'attackTargeting',
    icon: GameIcons.attack,
    accent: GameUiTheme.danger,
    title: l10n.modeBannerAttackTargetingTitle,
    instruction: preview != null
        ? l10n.modeBannerAttackTargetingInstructionSelected
        : l10n.modeBannerAttackTargetingInstructionEmpty,
    progress: _attackProgress(l10n, preview),
    details: preview?.detailLines(l10n) ?? const [],
  );
}

String? _attackProgress(AppLocalizations l10n, HudCombatPreview? preview) {
  if (preview == null) return null;
  if (preview.defenderKilled) return 'KO';
  if (preview.defenderRetreated) return l10n.modeBannerAttackRetreatProgress;
  return '-${preview.attackDamage} HP';
}

HudModeBannerSpec _workedHexSpec(AppLocalizations l10n) => HudModeBannerSpec(
  id: 'cityWorkedHexSelection',
  icon: GameIcons.workedHexes,
  accent: GameUiTheme.gold,
  title: l10n.modeBannerWorkedTilesTitle,
  instruction: l10n.modeBannerWorkedTilesInstruction,
);

HudModeBannerSpec _cityExpansionSpec(AppLocalizations l10n, bool selected) {
  return HudModeBannerSpec(
    id: HudModeBannerSpec.cityExpansionSelectionId,
    icon: GameIcons.workedHexes,
    accent: GameUiTheme.gold,
    title: l10n.modeBannerCityGrowthTitle,
    instruction: selected
        ? l10n.modeBannerCityGrowthInstructionSelected
        : l10n.modeBannerCityGrowthInstructionEmpty,
    primaryAction: selected
        ? HudModeBannerActionSpec(
            icon: GameIcons.checkCircle,
            label: l10n.selectionActionConfirm,
            accent: GameUiTheme.gold,
          )
        : null,
  );
}

HudModeBannerSpec _workerPickSpec(AppLocalizations l10n, bool picked) {
  return HudModeBannerSpec(
    id: 'workerAction',
    icon: GameIcons.production,
    accent: GameUiTheme.gold,
    title: l10n.modeBannerWorkerActionTitle,
    instruction: picked
        ? l10n.modeBannerWorkerActionInstructionPicked
        : l10n.modeBannerWorkerActionInstructionEmpty,
  );
}

HudModeBannerSpec _merchantTradeSpec(AppLocalizations l10n) =>
    HudModeBannerSpec(
      id: 'merchantTradeRoute',
      icon: GameIcons.commerce,
      accent: GameUiTheme.gold,
      title: l10n.modeBannerMerchantTradeRouteTitle,
      instruction: l10n.modeBannerMerchantTradeRouteInstruction,
    );

HudModeBannerSpec _merchantMoveSpec(AppLocalizations l10n) => HudModeBannerSpec(
  id: 'merchantMoveToCity',
  icon: GameIcons.city,
  accent: GameUiTheme.gold,
  title: l10n.modeBannerMerchantMoveToCityTitle,
  instruction: l10n.modeBannerMerchantMoveToCityInstruction,
);

HudModeBannerSpec _researchSpec(AppLocalizations l10n) => HudModeBannerSpec(
  id: 'researchSelection',
  icon: GameIcons.science,
  accent: GameUiTheme.gold,
  title: l10n.modeBannerResearchSelectionTitle,
  instruction: l10n.modeBannerResearchSelectionInstruction,
);

HudModeBannerSpec _turnSkipSpec(AppLocalizations l10n) => HudModeBannerSpec(
  id: 'unitTurnSkip',
  icon: GameIcons.skipTurn,
  accent: GameHudTheme.colorNeutral,
  title: l10n.modeBannerUnitTurnSkipTitle,
  instruction: l10n.modeBannerUnitTurnSkipInstruction,
);

HudModeBannerSpec _commanderMergeSpec(AppLocalizations l10n) =>
    HudModeBannerSpec(
      id: 'commanderMerge',
      icon: GameIcons.army,
      accent: GameUiTheme.gold,
      title: l10n.modeBannerCommanderMergeTitle,
      instruction: l10n.modeBannerCommanderMergeInstruction,
    );

HudModeBannerSpec _moveTargetingSpec(AppLocalizations l10n) {
  return HudModeBannerSpec(
    id: HudModeBannerSpec.moveTargetingId,
    icon: GameIcons.move,
    accent: GameUiTheme.gold,
    title: l10n.modeBannerMoveTargetingTitle,
    instruction: l10n.modeBannerMoveTargetingInstruction,
    primaryAction: HudModeBannerActionSpec(
      icon: GameIcons.close,
      label: l10n.modeBannerMoveTargetingCancelAction,
      accent: GameUiTheme.gold,
    ),
  );
}

HudModeBannerSpec? _selectedUnitActionHint({
  required GameUnit? selectedUnit,
  required bool workerActionAvailable,
  required String? workerActionBlockedReason,
  required bool scoutAutoExploreAvailable,
  required bool canStartCityFounding,
  required String? cityFoundingBlockedReason,
  required AppLocalizations l10n,
  required bool selectedUnitMoveActionEnabled,
  required String? selectedUnitMoveActionDisabledReason,
}) {
  return switch (selectedUnit?.type) {
    GameUnitType.worker => _workerHint(
      l10n,
      actionAvailable: workerActionAvailable,
      blockedReason: workerActionBlockedReason,
      moveEnabled: selectedUnitMoveActionEnabled,
      moveDisabledReason: selectedUnitMoveActionDisabledReason,
    ),
    GameUnitType.scout => _scoutHint(l10n, scoutAutoExploreAvailable),
    GameUnitType.settler => _settlerHint(
      l10n,
      canFound: canStartCityFounding,
      blockedReason: cityFoundingBlockedReason,
      moveEnabled: selectedUnitMoveActionEnabled,
      moveDisabledReason: selectedUnitMoveActionDisabledReason,
    ),
    _ => null,
  };
}

HudModeBannerSpec? _workerHint(
  AppLocalizations l10n, {
  required bool actionAvailable,
  required String? blockedReason,
  required bool moveEnabled,
  required String? moveDisabledReason,
}) {
  if (!actionAvailable) {
    final reason = blockedReason?.trim();
    if (reason == null || reason.isEmpty) return null;
    return HudModeBannerSpec(
      id: HudModeBannerSpec.selectedWorkerMoveToWorkId,
      icon: GameIcons.production,
      accent: GameUiTheme.warning,
      title: l10n.modeBannerWorkerFindTileTitle,
      instruction: l10n.modeBannerWorkerFindTileInstruction(reason),
      details: [
        l10n.modeBannerWorkerFindTileDetailOwnCity,
        l10n.modeBannerWorkerFindTileDetailNoImprovement,
        l10n.modeBannerWorkerFindTileDetailMatchingTerrain,
      ],
      primaryAction: _moveActionSpec(l10n, moveEnabled, moveDisabledReason),
    );
  }
  return HudModeBannerSpec(
    id: HudModeBannerSpec.selectedWorkerActionId,
    icon: GameIcons.production,
    accent: GameUiTheme.success,
    title: l10n.modeBannerWorkerImproveTileTitle,
    instruction: l10n.modeBannerWorkerImproveTileInstruction,
    details: [
      l10n.modeBannerWorkerImproveTileDetailYields,
      l10n.modeBannerWorkerImproveTileDetailMovement,
    ],
    primaryAction: HudModeBannerActionSpec(
      icon: GameIcons.production,
      label: l10n.selectionActionImprove,
      accent: GameUiTheme.success,
    ),
  );
}

HudModeBannerSpec? _scoutHint(AppLocalizations l10n, bool available) {
  if (!available) return null;
  return HudModeBannerSpec(
    id: HudModeBannerSpec.selectedScoutExploreId,
    icon: GameIcons.visibility,
    accent: GameUiTheme.info,
    title: l10n.modeBannerScoutExploreTitle,
    instruction: l10n.modeBannerScoutExploreInstruction,
    details: [
      l10n.modeBannerScoutExploreDetailAuto,
      l10n.modeBannerScoutExploreDetailReveal,
    ],
    primaryAction: HudModeBannerActionSpec(
      icon: GameIcons.visibility,
      label: l10n.selectionActionAutoExplore,
      accent: GameUiTheme.info,
    ),
  );
}

HudModeBannerSpec? _settlerHint(
  AppLocalizations l10n, {
  required bool canFound,
  required String? blockedReason,
  required bool moveEnabled,
  required String? moveDisabledReason,
}) {
  if (!canFound) {
    final reason = blockedReason?.trim();
    if (reason == null || reason.isEmpty) return null;
    return HudModeBannerSpec(
      id: HudModeBannerSpec.selectedSettlerMoveToCitySiteId,
      icon: GameIcons.foundCity,
      accent: GameUiTheme.warning,
      title: l10n.modeBannerSettlerFindSiteTitle,
      instruction: l10n.modeBannerSettlerFindSiteInstruction(reason),
      details: [
        l10n.modeBannerSettlerFindSiteDetailFreeHex,
        l10n.modeBannerSettlerFindSiteDetailOutsideBorders,
        l10n.modeBannerSettlerFindSiteDetailLandOrCoast,
      ],
      primaryAction: _moveActionSpec(l10n, moveEnabled, moveDisabledReason),
    );
  }
  return HudModeBannerSpec(
    id: HudModeBannerSpec.selectedSettlerCityFoundingId,
    icon: GameIcons.foundCity,
    accent: GameUiTheme.success,
    title: l10n.modeBannerSettlerFoundCityTitle,
    instruction: l10n.modeBannerSettlerFoundCityInstruction,
    details: [
      l10n.modeBannerSettlerFoundCityDetailNewCity,
      l10n.modeBannerSettlerFoundCityDetailChooseTiles,
    ],
    primaryAction: HudModeBannerActionSpec(
      icon: GameIcons.foundCity,
      label: l10n.selectionActionFoundCity,
      accent: GameUiTheme.success,
    ),
  );
}

HudModeBannerActionSpec _moveActionSpec(
  AppLocalizations l10n,
  bool enabled,
  String? disabledReason,
) {
  return HudModeBannerActionSpec(
    icon: GameIcons.move,
    label: l10n.selectionActionMove,
    accent: GameUiTheme.warning,
    enabled: enabled,
    disabledReason: enabled ? null : disabledReason,
  );
}

class HudModeBannerActionSpec {
  const HudModeBannerActionSpec({
    required this.icon,
    required this.label,
    required this.accent,
    this.enabled = true,
    this.disabledReason,
  });

  final GameIconData icon;
  final String label;
  final Color accent;
  final bool enabled;
  final String? disabledReason;
}
