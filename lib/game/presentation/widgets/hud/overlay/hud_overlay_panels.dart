import 'dart:async';

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/hud/hud_command_dispatcher_provider.dart';
import 'package:aonw/game/presentation/providers/hud/hud_map_focus_controller_provider.dart';
import 'package:aonw/game/presentation/widgets/activity_log/activity_log_dialog.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_dialog.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_dialog.dart';
import 'package:aonw/game/presentation/widgets/hud/map/hud_map_focus_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/overlay/hud_overlay_panel_slot.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_dialog.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HudOverlayPanels extends ConsumerWidget {
  final EdgeInsetsGeometry panelPadding;
  final bool technologyActive;
  final bool empireActive;
  final bool activityLogActive;
  final GameCity? cityProductionCity;
  final GameState? gameState;
  final String activePlayerId;
  final TechnologyPanelViewModel technologyViewModel;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final MapData mapData;
  final int cityProductionPerTurn;
  final List<GameEventNotification> activityLogEntries;
  final GameSave gameSave;

  const HudOverlayPanels({
    required this.panelPadding,
    required this.technologyActive,
    required this.empireActive,
    required this.activityLogActive,
    required this.cityProductionCity,
    required this.gameState,
    required this.activePlayerId,
    required this.technologyViewModel,
    required this.cityRuleset,
    required this.technologyRuleset,
    required this.mapData,
    required this.cityProductionPerTurn,
    required this.activityLogEntries,
    required this.gameSave,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = gameState;
    final city = cityProductionCity;
    final dispatcher = ref.read(hudCommandDispatcherProvider);
    final focusController = ref.read(hudMapFocusControllerProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (technologyActive) _buildTechnologyPanel(dispatcher),
        if (city != null && state != null)
          _buildCityProductionPanel(city, state, dispatcher),
        if (empireActive && state != null && activePlayerId.isNotEmpty)
          _buildEmpirePanel(state, dispatcher, focusController),
        if (activityLogActive && state != null && activePlayerId.isNotEmpty)
          _buildActivityLogPanel(dispatcher, focusController),
      ],
    );
  }

  Widget _buildTechnologyPanel(HudCommandDispatcher dispatcher) {
    return HudOverlayPanelSlot(
      padding: panelPadding,
      builder: (context, maxHeight) => TechnologyTreePanel(
        viewModel: technologyViewModel,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        maxHeight: maxHeight,
        onResearch: (technologyId) => unawaited(
          dispatcher.selectTechnology(
            activePlayerId: activePlayerId,
            technologyId: technologyId,
          ),
        ),
        onClose: () => dispatcher.closeTechnologyPanel(
          activePlayerId: activePlayerId,
          state: gameState,
        ),
      ),
    );
  }

  Widget _buildCityProductionPanel(
    GameCity city,
    GameState state,
    HudCommandDispatcher dispatcher,
  ) {
    return HudOverlayPanelSlot(
      padding: panelPadding,
      builder: (context, maxHeight) => CityProductionPanel(
        city: city,
        cityRuleset: cityRuleset,
        research: state.research,
        technologyRuleset: technologyRuleset,
        mapData: mapData,
        cities: state.cities,
        units: state.units,
        artifacts: state.artifacts,
        fieldImprovements: state.fieldImprovements,
        resourceTradeAgreements: state.resourceTradeAgreements,
        productionPerTurn: cityProductionPerTurn,
        currentTurn: gameSave.turn,
        paceBalance: gameSave.matchRules.paceBalance,
        playerGold: state.playerGold[city.ownerPlayerId] ?? 0,
        maxHeight: maxHeight,
        onBuild: (buildingType) =>
            unawaited(dispatcher.startCityBuilding(city.id, buildingType)),
        onProduceUnit: (unitType) =>
            unawaited(dispatcher.startCityUnitProduction(city.id, unitType)),
        onStartProject: (projectType) =>
            unawaited(dispatcher.startCityProject(city.id, projectType)),
        onSetSpecialization: (specialization) => unawaited(
          dispatcher.setCitySpecialization(city.id, specialization),
        ),
        onRushProduction: () =>
            unawaited(dispatcher.rushCityProduction(city.id)),
        onClose: () => dispatcher.closeCityProductionPanel(),
      ),
    );
  }

  Widget _buildEmpirePanel(
    GameState state,
    HudCommandDispatcher dispatcher,
    HudMapFocusController focusController,
  ) {
    return HudOverlayPanelSlot(
      padding: panelPadding,
      builder: (context, maxHeight) => EmpireOverviewPanel(
        state: state,
        activePlayerId: activePlayerId,
        mapData: mapData,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        paceBalance: gameSave.matchRules.paceBalance,
        maxHeight: maxHeight,
        onUnitSelected: (unit) =>
            unawaited(focusController.focusEmpireUnit(unit)),
        onCitySelected: (city) =>
            unawaited(focusController.focusEmpireCity(city)),
        onClose: dispatcher.closeEmpirePanel,
      ),
    );
  }

  Widget _buildActivityLogPanel(
    HudCommandDispatcher dispatcher,
    HudMapFocusController focusController,
  ) {
    return HudOverlayPanelSlot(
      padding: panelPadding,
      builder: (context, maxHeight) => ActivityLogPanel(
        entries: activityLogEntries,
        gameSave: gameSave,
        currentState: gameState,
        activePlayerId: activePlayerId,
        maxHeight: maxHeight,
        onEntrySelected: (notification) => unawaited(
          focusController.focusActivityLogEntry(
            notification: notification,
            currentState: gameState,
          ),
        ),
        onClose: dispatcher.closeActivityLogPanel,
      ),
    );
  }
}
