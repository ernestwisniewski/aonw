import 'package:aonw/game/presentation/formatters/game_objective_labels.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_options_panel.dart';
import 'package:aonw_core/game/domain/objective.dart';

class HudObjectiveButtonSignal {
  final String badgeLabel;
  final GameUiSideMenuBadgeTone badgeTone;
  final String tooltip;

  const HudObjectiveButtonSignal({
    required this.badgeLabel,
    required this.badgeTone,
    required this.tooltip,
  });

  factory HudObjectiveButtonSignal.from({
    required AppLocalizations l10n,
    required List<GameObjectiveProgress> objectives,
    required bool open,
  }) {
    final objective = objectives.first;
    final prefix = open
        ? l10n.objectivesMenuClosePrefix
        : l10n.objectivesMenuOpenPrefix;
    final descriptor = _descriptor(l10n, objective.definition.id);
    final title = GameObjectiveLabels.title(l10n, objective.definition.id);
    final count = l10n.objectivesMenuCount(objectives.length);

    return HudObjectiveButtonSignal(
      badgeLabel: _badgeLabel(l10n, objective, objectives.length),
      badgeTone: _badgeTone(objective),
      tooltip: l10n.objectivesMenuTooltip(
        prefix,
        descriptor,
        title,
        objective.progressLabel,
        count,
      ),
    );
  }

  static String _badgeLabel(
    AppLocalizations l10n,
    GameObjectiveProgress objective,
    int count,
  ) {
    return switch (objective.definition.id) {
      GameObjectiveId.holdScoreLead ||
      GameObjectiveId.overtakeScoreLeader => l10n.objectivesMenuBadgeScore,
      GameObjectiveId.holdDomination ||
      GameObjectiveId.breakDominationHold => l10n.objectivesMenuBadgeDomination,
      _ => '$count',
    };
  }

  static GameUiSideMenuBadgeTone _badgeTone(GameObjectiveProgress objective) {
    return switch (objective.definition.id) {
      GameObjectiveId.holdScoreLead ||
      GameObjectiveId.overtakeScoreLeader => GameUiSideMenuBadgeTone.score,
      GameObjectiveId.holdDomination ||
      GameObjectiveId.breakDominationHold => GameUiSideMenuBadgeTone.domination,
      _ => GameUiSideMenuBadgeTone.count,
    };
  }

  static String _descriptor(AppLocalizations l10n, GameObjectiveId id) {
    return switch (id) {
      GameObjectiveId.holdDomination => l10n.objectivesMenuDescriptorDomination,
      GameObjectiveId.breakDominationHold =>
        l10n.objectivesMenuDescriptorDominationThreat,
      GameObjectiveId.holdScoreLead => l10n.objectivesMenuDescriptorScoreLead,
      GameObjectiveId.overtakeScoreLeader =>
        l10n.objectivesMenuDescriptorScorePressure,
      _ => l10n.objectivesMenuDescriptorActiveObjective,
    };
  }
}
