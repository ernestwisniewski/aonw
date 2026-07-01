import 'package:aonw/game/presentation/widgets/hud/outcome/hud_victory_status_summary.dart';
import 'package:aonw/game/presentation/widgets/onboarding/first_turn_coachmark_targets.dart';
import 'package:aonw/game/presentation/widgets/resources/resource_delta_badge.dart';
import 'package:aonw/game/presentation/widgets/resources/top_resource_pill.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:flutter/material.dart';

enum TopResourcePopupType { gold, science, resources, victory }

enum ResourceBreakdownType { gold, science, resources }

extension ResourceBreakdownPopupType on ResourceBreakdownType {
  TopResourcePopupType get popupType => switch (this) {
    ResourceBreakdownType.gold => TopResourcePopupType.gold,
    ResourceBreakdownType.science => TopResourcePopupType.science,
    ResourceBreakdownType.resources => TopResourcePopupType.resources,
  };
}

extension TopResourcePopupResourceType on TopResourcePopupType {
  ResourceBreakdownType? get resourceType => switch (this) {
    TopResourcePopupType.gold => ResourceBreakdownType.gold,
    TopResourcePopupType.science => ResourceBreakdownType.science,
    TopResourcePopupType.resources => ResourceBreakdownType.resources,
    TopResourcePopupType.victory => null,
  };
}

class TopResourceStrip extends StatelessWidget {
  const TopResourceStrip({
    required this.gold,
    required this.goldPerTurn,
    required this.goldIncome,
    required this.unitUpkeep,
    required this.sciencePerTurn,
    required this.stabilityNet,
    required this.stabilityBand,
    required this.resourceTotal,
    required this.resourceTypes,
    required this.openBreakdown,
    required this.onGoldPressed,
    required this.onSciencePressed,
    required this.onResourcesPressed,
    required this.onVictoryPressed,
    this.victoryStatus,
    this.playerName,
    this.playerColor,
    this.turnNumber,
    this.onTurnPressed,
    super.key,
  });

  final int gold;
  final int goldPerTurn;
  final int goldIncome;
  final int unitUpkeep;
  final int sciencePerTurn;
  final int stabilityNet;
  final StabilityBand stabilityBand;
  final int resourceTotal;
  final int resourceTypes;
  final TopResourcePopupType? openBreakdown;
  final VoidCallback onGoldPressed;
  final VoidCallback onSciencePressed;
  final VoidCallback onResourcesPressed;
  final VoidCallback onVictoryPressed;
  final HudVictoryStatusSummary? victoryStatus;
  final String? playerName;
  final Color? playerColor;
  final VoidCallback? onTurnPressed;

  /// When provided, the turn count is shown beside the resource pills.
  final int? turnNumber;

  String get _stabilityValueLabel =>
      stabilityNet > 0 ? '+$stabilityNet' : '$stabilityNet';

  static Color _stabilityColor(StabilityBand band) => switch (band) {
    StabilityBand.content => GameUiTheme.success,
    StabilityBand.stable => GameUiTheme.gold,
    StabilityBand.strained => GameUiTheme.warning,
    StabilityBand.unrest => GameUiTheme.danger,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 520;
    final portrait = size.height >= size.width;
    final resourcePills = <Widget>[
      TopResourcePill(
        key: const Key('gameHud.resource.gold'),
        icon: GameIcons.gold,
        title: l10n.commonGold,
        value: '$gold',
        delta: goldPerTurn == 0 ? null : ResourceDelta(goldPerTurn),
        color: GameUiTheme.gold,
        compact: compact,
        critical: _bankruptcyWarning,
        tooltip: _goldTooltip(l10n),
        active: openBreakdown == TopResourcePopupType.gold,
        onTap: onGoldPressed,
      ),
      const SizedBox(width: 6),
      TopResourcePill(
        key: const Key('gameHud.resource.science'),
        icon: GameIcons.science,
        title: l10n.commonScience,
        value: _scienceTurnLabel,
        color: GameUiTheme.scienceAccent,
        compact: compact,
        tooltip: l10n.topResourceScienceTooltip(_scienceTurnLabel),
        active: openBreakdown == TopResourcePopupType.science,
        onTap: onSciencePressed,
      ),
      const SizedBox(width: 6),
      TopResourcePill(
        key: const Key('gameHud.resource.stability'),
        icon: GameIcons.defense,
        title: l10n.commonStability,
        value: _stabilityValueLabel,
        color: _stabilityColor(stabilityBand),
        compact: compact,
        critical: stabilityBand == StabilityBand.unrest,
        tooltip: l10n.topResourceStabilityTooltip(stabilityNet),
        active: false,
        onTap: () {},
      ),
      const SizedBox(width: 6),
      TopResourcePill(
        key: const Key('gameHud.resource.resources'),
        icon: GameIcons.resources,
        title: l10n.commonResources,
        value: '$resourceTotal',
        color: GameUiTheme.resourcesAccent,
        compact: compact,
        tooltip: l10n.topResourceResourcesTooltip(resourceTotal, resourceTypes),
        active: openBreakdown == TopResourcePopupType.resources,
        onTap: onResourcesPressed,
      ),
      if (turnNumber != null) ...[
        const SizedBox(width: 6),
        TurnResourcePill(
          turnNumber: turnNumber!,
          compact: compact,
          onTap: onTurnPressed,
        ),
      ],
      if (victoryStatus case final status?) ...[
        const SizedBox(width: 6),
        VictoryStatusResourcePill(
          primaryLabel: status.primaryLabel,
          compactLabel: status.compactLabel,
          secondaryLabel: status.secondaryLabel,
          tooltip: status.tooltip,
          compact: compact,
          condensed: portrait,
          critical: status.critical,
          active: openBreakdown == TopResourcePopupType.victory,
          onTap: onVictoryPressed,
        ),
      ],
    ];
    final resourceRow = _ScrollableResourcePills(resourcePills: resourcePills);

    return Align(
      key: const Key('gameHud.resource.strip'),
      alignment: Alignment.topRight,
      heightFactor: 1,
      child: KeyedSubtree(
        key: FirstTurnCoachmarkTargets.resources,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: KeyedSubtree(
            key: const Key('gameHud.resource.singleRow'),
            child: resourceRow,
          ),
        ),
      ),
    );
  }

  String get _goldTurnLabel =>
      goldPerTurn > 0 ? '+$goldPerTurn' : '$goldPerTurn';

  String get _scienceTurnLabel =>
      sciencePerTurn > 0 ? '+$sciencePerTurn' : '$sciencePerTurn';

  bool get _bankruptcyWarning => _negativeTreasury || _projectedBankruptcy;

  bool get _negativeTreasury => gold < 0;

  bool get _projectedBankruptcy =>
      goldPerTurn < 0 && gold + goldPerTurn * 3 < 0;

  String _goldTooltip(AppLocalizations l10n) {
    final base = l10n.topResourceGoldTooltip(
      gold,
      goldIncome,
      unitUpkeep,
      _goldTurnLabel,
    );
    if (_negativeTreasury) {
      return l10n.topResourceGoldTooltipNegativeTreasury(base);
    }
    if (!_projectedBankruptcy) return base;
    return l10n.topResourceGoldTooltipBankruptcy(base);
  }
}

class _ScrollableResourcePills extends StatelessWidget {
  const _ScrollableResourcePills({required this.resourcePills});

  final List<Widget> resourcePills;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(mainAxisSize: MainAxisSize.min, children: resourcePills),
    );
  }
}
