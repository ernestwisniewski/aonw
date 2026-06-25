import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';

enum CoachmarkAnchor {
  actionDeck,
  topResources,
  sideMenu,
  selectionActions,
  bottomResearch,
  endTurn,
}

enum FirstTurnCoachmarkSelectionKind { none, settler, worker, city, unit }

class FirstTurnCoachmarkContext {
  const FirstTurnCoachmarkContext({
    this.selectionKind = FirstTurnCoachmarkSelectionKind.none,
    this.hasOwnedCity = false,
    this.hasCityNeedingProduction = false,
    this.researchAvailable = false,
    this.hasSelectionActions = false,
    this.readyToEndTurn = false,
  });

  final FirstTurnCoachmarkSelectionKind selectionKind;
  final bool hasOwnedCity;
  final bool hasCityNeedingProduction;
  final bool researchAvailable;
  final bool hasSelectionActions;
  final bool readyToEndTurn;

  FirstTurnCoachmarkContext copyWith({
    FirstTurnCoachmarkSelectionKind? selectionKind,
    bool? hasOwnedCity,
    bool? hasCityNeedingProduction,
    bool? researchAvailable,
    bool? hasSelectionActions,
    bool? readyToEndTurn,
  }) {
    return FirstTurnCoachmarkContext(
      selectionKind: selectionKind ?? this.selectionKind,
      hasOwnedCity: hasOwnedCity ?? this.hasOwnedCity,
      hasCityNeedingProduction:
          hasCityNeedingProduction ?? this.hasCityNeedingProduction,
      researchAvailable: researchAvailable ?? this.researchAvailable,
      hasSelectionActions: hasSelectionActions ?? this.hasSelectionActions,
      readyToEndTurn: readyToEndTurn ?? this.readyToEndTurn,
    );
  }
}

class CoachmarkStep {
  const CoachmarkStep({
    required this.anchor,
    required this.icon,
    required this.title,
    required this.body,
  });

  final CoachmarkAnchor anchor;
  final GameIconData icon;
  final String title;
  final String body;
}

abstract final class FirstTurnCoachmarkSteps {
  static List<CoachmarkStep> build({
    required AppLocalizations l10n,
    required FirstTurnCoachmarkContext context,
  }) {
    return [
      CoachmarkStep(
        anchor: CoachmarkAnchor.actionDeck,
        icon: _selectionIcon(context.selectionKind),
        title: l10n.firstTurnCoachmarkSelectionTitle,
        body: '${_hexTapBody(l10n)}\n\n${_selectionBody(l10n, context)}',
      ),
      CoachmarkStep(
        anchor: CoachmarkAnchor.topResources,
        icon: GameIcons.resources,
        title: l10n.firstTurnCoachmarkResourcesTitle,
        body:
            '${l10n.firstTurnCoachmarkResourcesBody}\n\n${_victoryBody(l10n)}',
      ),
      CoachmarkStep(
        anchor: CoachmarkAnchor.sideMenu,
        icon: GameIcons.settings,
        title: l10n.firstTurnCoachmarkMenuTitle,
        body: l10n.firstTurnCoachmarkMenuBody,
      ),
      CoachmarkStep(
        anchor: CoachmarkAnchor.selectionActions,
        icon: _actionIcon(context.selectionKind),
        title: l10n.firstTurnCoachmarkActionTitle,
        body: _actionBody(l10n, context),
      ),
      CoachmarkStep(
        anchor: CoachmarkAnchor.bottomResearch,
        icon: GameIcons.science,
        title: l10n.firstTurnCoachmarkResearchTitle,
        body: context.researchAvailable
            ? l10n.firstTurnCoachmarkResearchBodyAvailable
            : l10n.firstTurnCoachmarkResearchBody,
      ),
      CoachmarkStep(
        anchor: CoachmarkAnchor.actionDeck,
        icon: GameIcons.cityFilled,
        title: l10n.firstTurnCoachmarkCityTitle,
        body: _cityBody(l10n, context),
      ),
      CoachmarkStep(
        anchor: CoachmarkAnchor.endTurn,
        icon: GameIcons.arrowRight,
        title: l10n.firstTurnCoachmarkActionFlowTitle,
        body: context.readyToEndTurn
            ? l10n.firstTurnCoachmarkActionFlowBodyReady
            : l10n.firstTurnCoachmarkActionFlowBodyPending,
      ),
      CoachmarkStep(
        anchor: CoachmarkAnchor.endTurn,
        icon: GameIcons.checkCircle,
        title: l10n.firstTurnCoachmarkEndTurnTitle,
        body: l10n.firstTurnCoachmarkEndTurnBody,
      ),
    ];
  }

  static String _selectionBody(
    AppLocalizations l10n,
    FirstTurnCoachmarkContext context,
  ) {
    return switch (context.selectionKind) {
      FirstTurnCoachmarkSelectionKind.city =>
        l10n.firstTurnCoachmarkSelectionBodyCity,
      FirstTurnCoachmarkSelectionKind.none =>
        l10n.firstTurnCoachmarkSelectionBodyNone,
      _ => l10n.firstTurnCoachmarkSelectionBodyUnit,
    };
  }

  static GameIconData _selectionIcon(
    FirstTurnCoachmarkSelectionKind selection,
  ) {
    return switch (selection) {
      FirstTurnCoachmarkSelectionKind.settler => GameIcons.settler,
      FirstTurnCoachmarkSelectionKind.worker => GameIcons.improvement,
      FirstTurnCoachmarkSelectionKind.city => GameIcons.cityFilled,
      FirstTurnCoachmarkSelectionKind.unit => GameIcons.warrior,
      FirstTurnCoachmarkSelectionKind.none => GameIcons.touch,
    };
  }

  static GameIconData _actionIcon(FirstTurnCoachmarkSelectionKind selection) {
    return switch (selection) {
      FirstTurnCoachmarkSelectionKind.settler => GameIcons.foundCity,
      FirstTurnCoachmarkSelectionKind.worker => GameIcons.improvement,
      FirstTurnCoachmarkSelectionKind.city => GameIcons.production,
      _ => GameIcons.arrowRight,
    };
  }

  static String _actionBody(
    AppLocalizations l10n,
    FirstTurnCoachmarkContext context,
  ) {
    if (context.selectionKind == FirstTurnCoachmarkSelectionKind.city) {
      return l10n.firstTurnCoachmarkActionBodyCity;
    }
    if (!context.hasSelectionActions) {
      return l10n.firstTurnCoachmarkActionBodyWaiting;
    }
    return switch (context.selectionKind) {
      FirstTurnCoachmarkSelectionKind.settler =>
        l10n.firstTurnCoachmarkActionBodySettler,
      FirstTurnCoachmarkSelectionKind.worker =>
        l10n.firstTurnCoachmarkActionBodyWorker,
      FirstTurnCoachmarkSelectionKind.city =>
        l10n.firstTurnCoachmarkActionBodyCity,
      FirstTurnCoachmarkSelectionKind.unit =>
        l10n.firstTurnCoachmarkActionBodyUnit,
      FirstTurnCoachmarkSelectionKind.none =>
        l10n.firstTurnCoachmarkActionBodyWaiting,
    };
  }

  static String _cityBody(
    AppLocalizations l10n,
    FirstTurnCoachmarkContext context,
  ) {
    if (context.selectionKind == FirstTurnCoachmarkSelectionKind.city) {
      return l10n.firstTurnCoachmarkCityBodySelected;
    }
    if (context.hasCityNeedingProduction) {
      return l10n.firstTurnCoachmarkCityBodyNeedsProduction;
    }
    if (context.hasOwnedCity) {
      return l10n.firstTurnCoachmarkCityBodyExisting;
    }
    return l10n.firstTurnCoachmarkCityBodyFuture;
  }

  static String _victoryBody(AppLocalizations l10n) =>
      l10n.firstTurnCoachmarkVictoryBody;

  static String _hexTapBody(AppLocalizations l10n) =>
      l10n.firstTurnCoachmarkHexTapBody;
}
