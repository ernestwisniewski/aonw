import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_next_action_panel.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'hud_panel_modes.freezed.dart';

@freezed
abstract class HudPanelModes with _$HudPanelModes {
  const HudPanelModes._();

  const factory HudPanelModes({
    @Default(false) bool cityBuildings,
    @Default(false) bool technology,
    @Default(false) bool objectives,
    @Default(false) bool empire,
    @Default(false) bool activityLog,
  }) = _HudPanelModes;

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

  HudPanelModes closePrimaryPanelsPreserving(HudNextActionPanel panel) {
    return switch (panel) {
      HudNextActionPanel.cityProduction => copyWith(
        technology: false,
        objectives: false,
      ),
      HudNextActionPanel.technology => copyWith(
        cityBuildings: false,
        objectives: false,
      ),
      HudNextActionPanel.none => closePrimaryPanels(),
    };
  }

  HudPanelModes closeUnitActionPanels() =>
      copyWith(technology: false, objectives: false);
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
