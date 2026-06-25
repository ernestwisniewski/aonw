part of 'hud_selection_actions.dart';

_HudSelectionActionSpec _merchantTradeRouteActionFor({
  required GameUnit unit,
  required GameState? gameState,
  required MapData mapData,
  required String? lockedReason,
  required AppLocalizations l10n,
  required VoidCallback onStartMerchantTradeRouteSelection,
  required VoidCallback onCancelMerchantTradeRouteSelection,
  required VoidCallback onCancelSelectedUnitAction,
}) {
  final pending = gameState?.pendingAction;
  final selectionActive =
      pending is PendingMerchantTradeRouteSelection &&
      pending.unitId == unit.id;
  final routeActive = unit.merchantTradeRoute != null;
  final active = selectionActive || routeActive;
  final destinations = _merchantReachableDestinations(
    unit: unit,
    gameState: gameState,
    mapData: mapData,
    l10n: l10n,
  );
  final canStart =
      !unit.isWorking &&
      !unit.isFortified &&
      destinations.isNotEmpty &&
      lockedReason == null;

  return _HudSelectionActionSpec(
    icon: GameIcons.commerce,
    actionId: 'tradeRoute',
    label: l10n.selectionActionTradeRoute,
    color: GameUiTheme.gold,
    active: active,
    enabled: _enabled(active || canStart, lockedReason),
    dangerOutlined: active,
    prominent: !active && canStart,
    disabledReason: _disabledReason(
      lockedReason: lockedReason,
      actionReason: active
          ? null
          : _merchantTradeRouteBlockedReason(
              unit: unit,
              gameState: gameState,
              mapData: mapData,
              l10n: l10n,
              reachableDestinations: destinations,
            ),
    ),
    onTap: routeActive
        ? onCancelSelectedUnitAction
        : selectionActive
        ? onCancelMerchantTradeRouteSelection
        : onStartMerchantTradeRouteSelection,
  );
}

List<_HudSelectionActionSpec> _merchantTradeRouteCityActionsFor({
  required GameUnit unit,
  required GameState? gameState,
  required MapData mapData,
  required String? lockedReason,
  required AppLocalizations l10n,
  required ValueChanged<String> onAssignMerchantTradeRoute,
}) {
  final destinations = _merchantReachableDestinations(
    unit: unit,
    gameState: gameState,
    mapData: mapData,
    l10n: l10n,
  );
  return [
    for (final city in destinations)
      _HudSelectionActionSpec(
        icon: GameIcons.commerce,
        actionId: 'tradeRoute:${city.id}',
        label: l10n.selectionActionTradeRouteToCity(
          GameDisplayNames.city(l10n, city),
        ),
        color: GameUiTheme.gold,
        enabled: lockedReason == null,
        prominent: lockedReason == null,
        showLabel: true,
        disabledReason: lockedReason,
        onTap: () => onAssignMerchantTradeRoute(city.id),
      ),
  ];
}

_HudSelectionActionSpec _merchantMoveToCityActionFor({
  required GameUnit unit,
  required GameState? gameState,
  required MapData mapData,
  required String? lockedReason,
  required AppLocalizations l10n,
  required VoidCallback onStartMerchantMoveToCitySelection,
  required VoidCallback onCancelMerchantMoveToCitySelection,
  required VoidCallback onCancelSelectedUnitAction,
}) {
  final pending = gameState?.pendingAction;
  final selectionActive =
      pending is PendingMerchantMoveToCitySelection &&
      pending.unitId == unit.id;
  final queuedPathActive = unit.queuedPath != null;
  final active = selectionActive || queuedPathActive;
  final destinations = _merchantReachableMoveToCityDestinations(
    unit: unit,
    gameState: gameState,
    mapData: mapData,
    l10n: l10n,
  );
  final canStart =
      !unit.isWorking &&
      !unit.isFortified &&
      !queuedPathActive &&
      destinations.isNotEmpty &&
      lockedReason == null;

  return _HudSelectionActionSpec(
    icon: GameIcons.city,
    actionId: 'merchantMoveToCity',
    label: l10n.selectionActionMerchantMoveToCity,
    color: GameUiTheme.gold,
    active: active,
    enabled: _enabled(active || canStart, lockedReason),
    dangerOutlined: active,
    prominent: !active && canStart,
    disabledReason: _disabledReason(
      lockedReason: lockedReason,
      actionReason: active
          ? null
          : _merchantMoveToCityBlockedReason(
              unit: unit,
              gameState: gameState,
              l10n: l10n,
              reachableDestinations: destinations,
            ),
    ),
    badgeLabel: _queuedPathTurnsLabel(unit, unit.queuedPath),
    onTap: queuedPathActive
        ? onCancelSelectedUnitAction
        : selectionActive
        ? onCancelMerchantMoveToCitySelection
        : onStartMerchantMoveToCitySelection,
  );
}

List<_HudSelectionActionSpec> _merchantMoveToCityActionsFor({
  required GameUnit unit,
  required GameState? gameState,
  required MapData mapData,
  required String? lockedReason,
  required AppLocalizations l10n,
  required ValueChanged<String> onMoveMerchantToCity,
}) {
  final destinations = _merchantReachableMoveToCityDestinations(
    unit: unit,
    gameState: gameState,
    mapData: mapData,
    l10n: l10n,
  );
  return [
    for (final city in destinations)
      _HudSelectionActionSpec(
        icon: GameIcons.city,
        actionId: 'merchantMoveToCity:${city.id}',
        label: l10n.selectionActionMerchantMoveToCityTarget(
          GameDisplayNames.city(l10n, city),
        ),
        color: GameUiTheme.gold,
        enabled: lockedReason == null,
        prominent: lockedReason == null,
        showLabel: true,
        disabledReason: lockedReason,
        onTap: () => onMoveMerchantToCity(city.id),
      ),
  ];
}

List<GameCity> _merchantReachableDestinations({
  required GameUnit unit,
  required GameState? gameState,
  required MapData mapData,
  required AppLocalizations l10n,
}) {
  if (gameState == null || unit.type != GameUnitType.merchant) return const [];
  final origin = MerchantTradeRouteRules.originCityFor(
    merchant: unit,
    cities: gameState.cities,
  );
  if (origin == null) return const [];
  final destinations = [
    for (final city in MerchantTradeRouteRules.destinationCandidatesFor(
      merchant: unit,
      cities: gameState.cities,
    ))
      if (MerchantTradeRouteRules.planRoute(
            merchant: unit,
            originCity: origin,
            destinationCity: city,
            mapData: mapData,
            units: gameState.units,
            cities: gameState.cities,
          ) !=
          null)
        city,
  ];
  return destinations..sort(
    (a, b) => GameDisplayNames.city(
      l10n,
      a,
    ).compareTo(GameDisplayNames.city(l10n, b)),
  );
}

List<GameCity> _merchantReachableMoveToCityDestinations({
  required GameUnit unit,
  required GameState? gameState,
  required MapData mapData,
  required AppLocalizations l10n,
}) {
  if (gameState == null || unit.type != GameUnitType.merchant) return const [];
  final destinations = [
    for (final city in MerchantTradeRouteRules.moveToCityCandidatesFor(
      merchant: unit,
      cities: gameState.cities,
    ))
      if (MerchantTradeRouteRules.planMoveToCity(
            merchant: unit,
            destinationCity: city,
            mapData: mapData,
            units: gameState.units,
            cities: gameState.cities,
          ) !=
          null)
        city,
  ];
  return destinations..sort(
    (a, b) => GameDisplayNames.city(
      l10n,
      a,
    ).compareTo(GameDisplayNames.city(l10n, b)),
  );
}

String? _merchantTradeRouteBlockedReason({
  required GameUnit unit,
  required GameState? gameState,
  required MapData mapData,
  required AppLocalizations l10n,
  required List<GameCity> reachableDestinations,
}) {
  if (unit.isWorking) return l10n.selectionActionUnitWorking;
  if (unit.isFortified) return l10n.selectionActionUnitFortified;
  if (gameState == null) return l10n.selectionActionMerchantNoDestinationCity;
  final origin = MerchantTradeRouteRules.originCityFor(
    merchant: unit,
    cities: gameState.cities,
  );
  if (origin == null) return l10n.selectionActionMerchantNoOriginCity;
  final hasAnyDestination = MerchantTradeRouteRules.destinationCandidatesFor(
    merchant: unit,
    cities: gameState.cities,
  ).isNotEmpty;
  if (!hasAnyDestination) return l10n.selectionActionMerchantNoDestinationCity;
  if (reachableDestinations.isEmpty) return l10n.selectionActionMerchantNoRoute;
  return null;
}

String? _merchantMoveToCityBlockedReason({
  required GameUnit unit,
  required GameState? gameState,
  required AppLocalizations l10n,
  required List<GameCity> reachableDestinations,
}) {
  if (unit.isWorking) return l10n.selectionActionUnitWorking;
  if (unit.isFortified) return l10n.selectionActionUnitFortified;
  if (unit.queuedPath != null) {
    return l10n.selectionActionCancelCurrentMoveFirst;
  }
  if (gameState == null) return l10n.selectionActionMerchantNoDestinationCity;
  final hasAnyDestination = MerchantTradeRouteRules.moveToCityCandidatesFor(
    merchant: unit,
    cities: gameState.cities,
  ).isNotEmpty;
  if (!hasAnyDestination) return l10n.selectionActionMerchantNoDestinationCity;
  if (reachableDestinations.isEmpty) {
    return l10n.selectionActionMerchantNoCityPath;
  }
  return null;
}
