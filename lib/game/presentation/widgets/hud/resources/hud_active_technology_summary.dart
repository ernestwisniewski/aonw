import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/formatters/turn_eta.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';

class HudActiveTechnologySummary {
  final String? name;
  final int? turnsRemaining;
  final int? completionTurn;

  const HudActiveTechnologySummary({
    required this.name,
    required this.turnsRemaining,
    required this.completionTurn,
  });

  factory HudActiveTechnologySummary.fromViewModel({
    required TechnologyPanelViewModel viewModel,
    required AppLocalizations l10n,
    int? currentTurn,
  }) {
    final activeTechnology = viewModel.activeTechnology;
    if (activeTechnology == null) {
      return const HudActiveTechnologySummary(
        name: null,
        turnsRemaining: null,
        completionTurn: null,
      );
    }
    return HudActiveTechnologySummary(
      name: GameDisplayNames.technology(l10n, activeTechnology.id),
      turnsRemaining: activeTechnology.turnsRemaining,
      completionTurn:
          activeTechnology.completionTurn ??
          TurnEtaFormatter.expectedCompletionTurn(
            currentTurn: currentTurn,
            turnsRemaining: activeTechnology.turnsRemaining,
          ),
    );
  }

  TurnEta get eta => TurnEtaFormatter.fromTurns(
    turnsRemaining: turnsRemaining,
    completionTurn: completionTurn,
  );
}
