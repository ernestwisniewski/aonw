import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_combat_preview.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

/// Unified contextual mode banner.
///
/// Replaces per-mode ad-hoc indicators (city founding card, attack chip glow,
/// worker selection panel hint) with a single sticky banner that explains the
/// current mode without adding another action surface.
///
/// Visibility rules live in [HudModeBannerSpec.resolve] so the host widget can
/// decide whether to lay out the banner without instantiating it.
class HudModeBanner extends StatelessWidget {
  final HudModeBannerSpec spec;
  final bool compact;
  final VoidCallback? onMinimize;

  const HudModeBanner({
    required this.spec,
    required this.compact,
    this.onMinimize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final accent = spec.accent;
    final l10n = AppLocalizations.of(context);

    final banner = DecoratedBox(
      key: Key('hudModeBanner.${spec.id}'),
      decoration: SurfaceElevation.raised.decoration(
        accent: accent,
        background: GameUiTheme.surfaceDeep,
        backgroundAlpha: 232,
        border: BorderEmphasis.strong,
        shape: SurfaceShape.card,
        glowColor: accent,
        glowAlpha: 28,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 10 : 12,
          compact ? 9 : 11,
          compact ? 10 : 12,
          compact ? 9 : 11,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: GameIcon(
                spec.icon,
                size: GameIconSize.large,
                color: accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          spec.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GameHudTheme.selectionTitle.copyWith(
                            color: GameUiTheme.goldLight,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (spec.progress != null) ...[
                        const SizedBox(width: 8),
                        _ProgressBadge(label: spec.progress!, accent: accent),
                      ],
                      if (onMinimize != null && spec.minimizable) ...[
                        const SizedBox(width: 4),
                        _HeaderIconButton(
                          key: const Key('hudModeBanner.minimize'),
                          tooltip: l10n.selectionActionMinimize,
                          icon: GameIcons.minus,
                          color: accent,
                          onTap: onMinimize!,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spec.instruction,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GameUiTheme.textSecondary,
                      fontSize: 11,
                      height: 1.22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (spec.details.isNotEmpty) ...[
                    SizedBox(height: compact ? 7 : 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final maxChipWidth = constraints.maxWidth
                            .clamp(0.0, compact ? 230.0 : 300.0)
                            .toDouble();
                        return Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (
                              var index = 0;
                              index < spec.details.length;
                              index++
                            )
                              _ModeBannerDetailChip(
                                key: Key('hudModeBanner.detail.$index'),
                                label: spec.details[index],
                                accent: accent,
                                maxWidth: maxChipWidth,
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                  if (spec.primaryAction != null) ...[
                    SizedBox(height: compact ? 8 : 10),
                    _ModeBannerToolbarHint(
                      label: l10n.modeBannerActionToolbarHint,
                      accent: accent,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (MediaQuery.disableAnimationsOf(context)) return banner;

    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(0, -0.18), end: Offset.zero),
      duration: GameMotion.slide,
      curve: GameMotion.enter,
      child: banner,
      builder: (context, offset, child) {
        return SlideTransition(
          position: AlwaysStoppedAnimation(offset),
          child: child,
        );
      },
    );
  }
}

class _ModeBannerDetailChip extends StatelessWidget {
  const _ModeBannerDetailChip({
    required this.label,
    required this.accent,
    required this.maxWidth,
    super.key,
  });

  final String label;
  final Color accent;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: SurfaceElevation.flat.decoration(
          accent: accent,
          background: GameUiTheme.chipSurface,
          backgroundAlpha: 160,
          border: BorderEmphasis.regular,
          shape: SurfaceShape.pill,
          includeShadow: false,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GameUiTheme.textPrimary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeBannerToolbarHint extends StatelessWidget {
  const _ModeBannerToolbarHint({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('hudModeBanner.toolbarHint'),
      decoration: SurfaceElevation.flat.decoration(
        accent: accent,
        background: GameUiTheme.chipSurface,
        backgroundAlpha: 145,
        border: BorderEmphasis.subtle,
        shape: SurfaceShape.chip,
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            GameIcon(
              GameIcons.arrowRight,
              size: GameIconSize.small,
              color: accent,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GameUiTheme.textPrimary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final String tooltip;
  final GameIconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: GameUiTheme.borderRadius,
          onTap: onTap,
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: GameIcon(
                icon,
                size: 16,
                color: SurfaceElevation.flat.fill(
                  background: color,
                  alpha: 230,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Resolved presentation data for a single contextual mode.
///
/// One spec maps 1:1 to a banner instance. Built by [HudModeBannerSpec.resolve]
/// from the current pending action + UI flags. Returns null when no banner
/// should show.
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

  final String id;
  final GameIconData icon;
  final Color accent;
  final String title;
  final String instruction;
  final String? progress;
  final List<String> details;
  final HudModeBannerActionSpec? primaryAction;
  final bool minimizable;

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

  /// Returns the banner spec for the current UI state, or null when no
  /// contextual mode is active.
  ///
  /// [moveTargetingActive] reflects [GameState.moveCommandActive]; it is a
  /// transient UI flag (not a [PendingPlayerAction]) but the player perceives
  /// it as a mode they entered, so the banner treats it on equal footing.
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
      const required = CityFoundingDraft.requiredControlledHexes;
      final selected = cityFoundingDraft.controlledHexes.length;
      return HudModeBannerSpec(
        id: cityFoundingId,
        icon: GameIcons.foundCity,
        accent: GameUiTheme.gold,
        title: l10n.modeBannerCityFoundingTitle,
        instruction: cityFoundingDraft.canConfirm
            ? l10n.modeBannerCityFoundingInstructionReady
            : l10n.modeBannerCityFoundingInstructionPick(required),
        progress: '$selected/$required',
        minimizable: false,
        primaryAction: cityFoundingDraft.canConfirm
            ? HudModeBannerActionSpec(
                icon: GameIcons.flag,
                label: l10n.selectionActionFoundCity,
                accent: GameUiTheme.gold,
              )
            : null,
      );
    }

    if (pendingAction != null) {
      switch (pendingAction) {
        case PendingAttackTargeting(:final hasDefenderTarget):
          final selectedPreview = hasDefenderTarget ? combatPreview : null;
          return HudModeBannerSpec(
            id: 'attackTargeting',
            icon: GameIcons.attack,
            accent: GameUiTheme.danger,
            title: l10n.modeBannerAttackTargetingTitle,
            instruction: selectedPreview != null
                ? l10n.modeBannerAttackTargetingInstructionSelected
                : l10n.modeBannerAttackTargetingInstructionEmpty,
            progress: selectedPreview == null
                ? null
                : selectedPreview.defenderKilled
                ? 'KO'
                : selectedPreview.defenderRetreated
                ? l10n.modeBannerAttackRetreatProgress
                : '-${selectedPreview.attackDamage} HP',
            details: selectedPreview?.detailLines(l10n) ?? const [],
          );
        case PendingCityWorkedHexSelection():
          return HudModeBannerSpec(
            id: 'cityWorkedHexSelection',
            icon: GameIcons.workedHexes,
            accent: GameUiTheme.gold,
            title: l10n.modeBannerWorkedTilesTitle,
            instruction: l10n.modeBannerWorkedTilesInstruction,
          );
        case PendingCityExpansionSelection():
          return HudModeBannerSpec(
            id: cityExpansionSelectionId,
            icon: GameIcons.workedHexes,
            accent: GameUiTheme.gold,
            title: l10n.modeBannerCityGrowthTitle,
            instruction: cityExpansionHexSelected
                ? l10n.modeBannerCityGrowthInstructionSelected
                : l10n.modeBannerCityGrowthInstructionEmpty,
            primaryAction: cityExpansionHexSelected
                ? HudModeBannerActionSpec(
                    icon: GameIcons.checkCircle,
                    label: l10n.selectionActionConfirm,
                    accent: GameUiTheme.gold,
                  )
                : null,
          );
        case PendingWorkerActionSelection():
          final picked = pendingAction.improvementType != null;
          return HudModeBannerSpec(
            id: 'workerAction',
            icon: GameIcons.production,
            accent: GameUiTheme.gold,
            title: l10n.modeBannerWorkerActionTitle,
            instruction: picked
                ? l10n.modeBannerWorkerActionInstructionPicked
                : l10n.modeBannerWorkerActionInstructionEmpty,
          );
        case PendingMerchantTradeRouteSelection():
          return HudModeBannerSpec(
            id: 'merchantTradeRoute',
            icon: GameIcons.commerce,
            accent: GameUiTheme.gold,
            title: l10n.modeBannerMerchantTradeRouteTitle,
            instruction: l10n.modeBannerMerchantTradeRouteInstruction,
          );
        case PendingMerchantMoveToCitySelection():
          return HudModeBannerSpec(
            id: 'merchantMoveToCity',
            icon: GameIcons.city,
            accent: GameUiTheme.gold,
            title: l10n.modeBannerMerchantMoveToCityTitle,
            instruction: l10n.modeBannerMerchantMoveToCityInstruction,
          );
        case PendingResearchSelection():
          return HudModeBannerSpec(
            id: 'researchSelection',
            icon: GameIcons.science,
            accent: GameUiTheme.gold,
            title: l10n.modeBannerResearchSelectionTitle,
            instruction: l10n.modeBannerResearchSelectionInstruction,
          );
        case PendingUnitTurnSkip():
          return HudModeBannerSpec(
            id: 'unitTurnSkip',
            icon: GameIcons.skipTurn,
            accent: GameHudTheme.colorNeutral,
            title: l10n.modeBannerUnitTurnSkipTitle,
            instruction: l10n.modeBannerUnitTurnSkipInstruction,
          );
        case PendingCommanderMergeSelection():
          return HudModeBannerSpec(
            id: 'commanderMerge',
            icon: GameIcons.army,
            accent: GameUiTheme.gold,
            title: l10n.modeBannerCommanderMergeTitle,
            instruction: l10n.modeBannerCommanderMergeInstruction,
          );
      }
    }

    if (moveTargetingActive) {
      return HudModeBannerSpec(
        id: moveTargetingId,
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

    final selectedUnitAction = _selectedUnitActionHint(
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
    if (selectedUnitAction != null) return selectedUnitAction;

    return null;
  }

  static HudModeBannerSpec? _selectedUnitActionHint({
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
    if (selectedUnit == null) return null;

    switch (selectedUnit.type) {
      case GameUnitType.worker:
        if (!workerActionAvailable) {
          final reason = workerActionBlockedReason?.trim();
          if (reason == null || reason.isEmpty) return null;
          return HudModeBannerSpec(
            id: selectedWorkerMoveToWorkId,
            icon: GameIcons.production,
            accent: GameUiTheme.warning,
            title: l10n.modeBannerWorkerFindTileTitle,
            instruction: l10n.modeBannerWorkerFindTileInstruction(reason),
            details: [
              l10n.modeBannerWorkerFindTileDetailOwnCity,
              l10n.modeBannerWorkerFindTileDetailNoImprovement,
              l10n.modeBannerWorkerFindTileDetailMatchingTerrain,
            ],
            primaryAction: _moveActionSpec(
              l10n: l10n,
              enabled: selectedUnitMoveActionEnabled,
              disabledReason: selectedUnitMoveActionDisabledReason,
            ),
          );
        }
        return HudModeBannerSpec(
          id: selectedWorkerActionId,
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
      case GameUnitType.scout:
        if (!scoutAutoExploreAvailable) return null;
        return HudModeBannerSpec(
          id: selectedScoutExploreId,
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
      case GameUnitType.settler:
        if (!canStartCityFounding) {
          final reason = cityFoundingBlockedReason?.trim();
          if (reason == null || reason.isEmpty) return null;
          return HudModeBannerSpec(
            id: selectedSettlerMoveToCitySiteId,
            icon: GameIcons.foundCity,
            accent: GameUiTheme.warning,
            title: l10n.modeBannerSettlerFindSiteTitle,
            instruction: l10n.modeBannerSettlerFindSiteInstruction(reason),
            details: [
              l10n.modeBannerSettlerFindSiteDetailFreeHex,
              l10n.modeBannerSettlerFindSiteDetailOutsideBorders,
              l10n.modeBannerSettlerFindSiteDetailLandOrCoast,
            ],
            primaryAction: _moveActionSpec(
              l10n: l10n,
              enabled: selectedUnitMoveActionEnabled,
              disabledReason: selectedUnitMoveActionDisabledReason,
            ),
          );
        }
        return HudModeBannerSpec(
          id: selectedSettlerCityFoundingId,
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
      case GameUnitType.commander:
      case GameUnitType.warrior:
      case GameUnitType.archer:
      case GameUnitType.merchant:
      case GameUnitType.spearman:
      case GameUnitType.cavalry:
      case GameUnitType.catapult:
      case GameUnitType.heavyInfantry:
      case GameUnitType.fieldCannon:
      case GameUnitType.rifleman:
      case GameUnitType.tank:
      case GameUnitType.scoutShip:
      case GameUnitType.warship:
      case GameUnitType.reconPlane:
        return null;
    }
  }

  static HudModeBannerActionSpec _moveActionSpec({
    required AppLocalizations l10n,
    required bool enabled,
    required String? disabledReason,
  }) {
    return HudModeBannerActionSpec(
      icon: GameIcons.move,
      label: l10n.selectionActionMove,
      accent: GameUiTheme.warning,
      enabled: enabled,
      disabledReason: enabled ? null : disabledReason,
    );
  }
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

class _ProgressBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const _ProgressBadge({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.floating.decoration(
        accent: accent,
        background: accent,
        backgroundAlpha: 30,
        border: BorderEmphasis.regular,
        shape: SurfaceShape.pill,
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
