part of 'resource_breakdown_popup_test.dart';

Future<void> _pumpPopup(
  WidgetTester tester, {
  required ResourceBreakdownType type,
  GoldBreakdown gold = const GoldBreakdown(
    treasury: 0,
    citySources: [],
    projectSources: [],
    upkeep: UnitUpkeepBreakdown(
      playerId: 'player_1',
      unitCount: 0,
      freeUnitCount: 0,
      paidUnitCount: 0,
      grossUpkeep: 0,
    ),
  ),
  ScienceYieldBreakdown science = ScienceYieldBreakdown.empty,
  StabilityBreakdown stability = const StabilityBreakdown(
    playerId: '',
    baseOrder: 0,
    buildingSources: 0,
    luxurySources: 0,
    techSources: 0,
    artifactSources: 0,
    cityCost: 0,
    populationCost: 0,
    cohesionCost: 0,
    conqueredCityCost: 0,
    warWearinessCost: 0,
    hegemonyTax: 0,
  ),
  int stabilityNet = 0,
  StabilityBand stabilityBand = StabilityBand.stable,
  int stabilityStandingAdjustment = 0,
  CityResourceInventory resources = CityResourceInventory.empty,
  EmpireResourceNetwork resourceNetwork = EmpireResourceNetwork.empty,
  HudStrategicResourceSummary strategicResources =
      HudStrategicResourceSummary.empty,
  ValueChanged<GameCity>? onCityPressed,
  VoidCallback? onOpenStrategicEconomy,
  AppLocalizations? l10n,
  String? activeTechnologyName,
  int? activeTechnologyTurnsRemaining,
  int? activeTechnologyCompletionTurn,
  VoidCallback? onClose,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: ResourceBreakdownPopup(
            type: type,
            gold: gold,
            science: science,
            stability: stability,
            stabilityNet: stabilityNet,
            stabilityBand: stabilityBand,
            stabilityStandingAdjustment: stabilityStandingAdjustment,
            resources: resources,
            resourceNetwork: resourceNetwork,
            strategicResources: strategicResources,
            cities: const [
              GameCity(
                id: 'city_1',
                ownerPlayerId: 'player_1',
                name: 'Krakow',
                center: CityHex(col: 1, row: 1),
              ),
            ],
            activeTechnologyName: activeTechnologyName,
            activeTechnologyTurnsRemaining: activeTechnologyTurnsRemaining,
            activeTechnologyCompletionTurn: activeTechnologyCompletionTurn,
            l10n: l10n ?? AppLocalizationsEn(),
            onClose: onClose ?? () {},
            onCityPressed: onCityPressed,
            onOpenStrategicEconomy: onOpenStrategicEconomy,
          ),
        ),
      ),
    ),
  );
}
