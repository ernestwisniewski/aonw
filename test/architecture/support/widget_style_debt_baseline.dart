typedef WidgetStyleDebt = ({int rawBoxDecorations, int rawAlpha});

const gameWidgets = 'lib/game/presentation/widgets/';
const sharedGameUi = 'lib/shared/widgets/game_ui/';

const widgetStyleDebtBaseline = <String, WidgetStyleDebt>{
  '${gameWidgets}bottom_toolbar/end_turn_button_action_menu.dart': (
    rawBoxDecorations: 1,
    rawAlpha: 0,
  ),
  '${gameWidgets}city/city_yield_source_charts.dart': (
    rawBoxDecorations: 1,
    rawAlpha: 1,
  ),
  '${gameWidgets}diplomacy/civilization_met_popup_overlay.dart': (
    rawBoxDecorations: 1,
    rawAlpha: 1,
  ),
  '${gameWidgets}empire/empire_statistics_charts.dart': (
    rawBoxDecorations: 1,
    rawAlpha: 2,
  ),
  '${gameWidgets}empire/empire_statistics_city_comparison.dart': (
    rawBoxDecorations: 0,
    rawAlpha: 1,
  ),
  '${gameWidgets}empire/empire_statistics_layout.dart': (
    rawBoxDecorations: 1,
    rawAlpha: 1,
  ),
  '${gameWidgets}hud/map/hud_artifact_inspection_popover.dart': (
    rawBoxDecorations: 1,
    rawAlpha: 2,
  ),
  '${gameWidgets}hud/map/hud_map_inspection_components.dart': (
    rawBoxDecorations: 3,
    rawAlpha: 8,
  ),
  '${gameWidgets}hud/map/hud_tile_inspection_popover.dart': (
    rawBoxDecorations: 1,
    rawAlpha: 2,
  ),
  '${gameWidgets}hud/objective/game_objective_overview.dart': (
    rawBoxDecorations: 1,
    rawAlpha: 0,
  ),
  '${gameWidgets}hud/objective/game_objective_score_breakdown.dart': (
    rawBoxDecorations: 1,
    rawAlpha: 0,
  ),
  '${gameWidgets}hud/outcome/hud_game_outcome_overlay.dart': (
    rawBoxDecorations: 3,
    rawAlpha: 7,
  ),
  '${gameWidgets}hud/overlay/turn_start_banner_overlay.dart': (
    rawBoxDecorations: 2,
    rawAlpha: 9,
  ),
  '${gameWidgets}multiplayer/multiplayer_avatar_tile.dart': (
    rawBoxDecorations: 1,
    rawAlpha: 2,
  ),
  '${gameWidgets}multiplayer/multiplayer_empire_stats_panel.dart': (
    rawBoxDecorations: 1,
    rawAlpha: 2,
  ),
  '${gameWidgets}multiplayer/multiplayer_player_stats_row.dart': (
    rawBoxDecorations: 2,
    rawAlpha: 4,
  ),
  '${gameWidgets}options/game_options_overlay.dart': (
    rawBoxDecorations: 0,
    rawAlpha: 1,
  ),
  '${gameWidgets}resources/resource_breakdown_popup_widgets.dart': (
    rawBoxDecorations: 1,
    rawAlpha: 2,
  ),
  '${gameWidgets}resources/victory_status_popup.dart': (
    rawBoxDecorations: 0,
    rawAlpha: 2,
  ),
  '${gameWidgets}screen/game_loading_painters.dart': (
    rawBoxDecorations: 0,
    rawAlpha: 16,
  ),
  '${gameWidgets}screen/game_loading_view.dart': (
    rawBoxDecorations: 7,
    rawAlpha: 19,
  ),
  '${gameWidgets}visual/game_insight_progress_card.dart': (
    rawBoxDecorations: 1,
    rawAlpha: 2,
  ),
  '${gameWidgets}visual/game_insight_stat_bar.dart': (
    rawBoxDecorations: 1,
    rawAlpha: 2,
  ),
  '${gameWidgets}visual/game_insight_yield_delta.dart': (
    rawBoxDecorations: 1,
    rawAlpha: 2,
  ),
  '${sharedGameUi}game_color_picker.dart': (rawBoxDecorations: 3, rawAlpha: 4),
  '${sharedGameUi}game_toast.dart': (rawBoxDecorations: 1, rawAlpha: 3),
  '${sharedGameUi}game_ui_epic_header.dart': (
    rawBoxDecorations: 2,
    rawAlpha: 8,
  ),
  '${sharedGameUi}game_ui_screen_header.dart': (
    rawBoxDecorations: 1,
    rawAlpha: 3,
  ),
};
