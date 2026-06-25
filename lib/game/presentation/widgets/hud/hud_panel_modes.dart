import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';

class HudPanelModes {
  const HudPanelModes({
    this.cityBuildings = false,
    this.technology = false,
    this.objectives = false,
    this.empire = false,
    this.activityLog = false,
  });

  final bool cityBuildings;
  final bool technology;
  final bool objectives;
  final bool empire;
  final bool activityLog;

  HudPanelModes copyWith({
    bool? cityBuildings,
    bool? technology,
    bool? objectives,
    bool? empire,
    bool? activityLog,
  }) {
    return HudPanelModes(
      cityBuildings: cityBuildings ?? this.cityBuildings,
      technology: technology ?? this.technology,
      objectives: objectives ?? this.objectives,
      empire: empire ?? this.empire,
      activityLog: activityLog ?? this.activityLog,
    );
  }

  HudPanelModes openCityBuildings() => copyWith(
    cityBuildings: true,
    technology: false,
    objectives: false,
    empire: false,
    activityLog: false,
  );

  HudPanelModes openTechnology() => copyWith(
    cityBuildings: false,
    technology: true,
    objectives: false,
    empire: false,
    activityLog: false,
  );

  HudPanelModes openObjectives() => copyWith(
    cityBuildings: false,
    technology: false,
    objectives: true,
    empire: false,
    activityLog: false,
  );

  HudPanelModes openEmpire() => copyWith(
    cityBuildings: false,
    technology: false,
    objectives: false,
    empire: true,
    activityLog: false,
  );

  HudPanelModes openActivityLog() => copyWith(
    cityBuildings: false,
    technology: false,
    objectives: false,
    empire: false,
    activityLog: true,
  );

  HudPanelModes closeCityBuildings() => copyWith(cityBuildings: false);

  HudPanelModes closeTechnology() => copyWith(technology: false);

  HudPanelModes closeObjectives() => copyWith(objectives: false);

  HudPanelModes closeEmpire() => copyWith(empire: false);

  HudPanelModes closeActivityLog() => copyWith(activityLog: false);

  HudPanelModes closePrimaryPanels() =>
      copyWith(cityBuildings: false, technology: false, objectives: false);

  HudPanelModes closeUnitActionPanels() =>
      copyWith(technology: false, objectives: false);

  @override
  bool operator ==(Object other) =>
      other is HudPanelModes &&
      other.cityBuildings == cityBuildings &&
      other.technology == technology &&
      other.objectives == objectives &&
      other.empire == empire &&
      other.activityLog == activityLog;

  @override
  int get hashCode =>
      Object.hash(cityBuildings, technology, objectives, empire, activityLog);
}

HudPanelModes normalizeHudPanelModes({
  required HudPanelModes current,
  required GameState? gameState,
}) {
  final selection = gameState?.selection;
  var cityBuildings = current.cityBuildings;

  if (selection?.type != GameSelectionType.city) {
    cityBuildings = false;
  }

  return current.copyWith(cityBuildings: cityBuildings);
}
