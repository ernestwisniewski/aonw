part of 'resource_breakdown_popup.dart';

List<_BreakdownSectionModel> _resourceBreakdownSections(
  ResourceBreakdownPopup popup,
) {
  return switch (popup.type) {
    ResourceBreakdownType.gold => _goldSections(popup),
    ResourceBreakdownType.science => _scienceSections(popup),
    ResourceBreakdownType.stability => _stabilitySections(popup),
    ResourceBreakdownType.resources => _resourceSections(popup),
  };
}

List<_BreakdownSectionModel> _stabilitySections(ResourceBreakdownPopup popup) {
  final stability = popup.stability;
  final standingAdjustment = popup.stabilityStandingAdjustment;
  final sourceRows = <_BreakdownRowModel>[
    _BreakdownRowModel(
      label: popup.l10n.stabilityBreakdownBaseOrder,
      value: _signed(stability.baseOrder),
      positive: stability.baseOrder > 0,
    ),
    if (stability.buildingSources > 0)
      _BreakdownRowModel(
        label: popup.l10n.stabilityBreakdownBuildings,
        value: _signed(stability.buildingSources),
        positive: true,
      ),
    if (stability.luxurySources > 0)
      _BreakdownRowModel(
        label: popup.l10n.stabilityBreakdownLuxuries,
        value: _signed(stability.luxurySources),
        positive: true,
      ),
    if (stability.techSources > 0)
      _BreakdownRowModel(
        label: popup.l10n.stabilityBreakdownTechnologies,
        value: _signed(stability.techSources),
        positive: true,
      ),
    if (stability.artifactSources > 0)
      _BreakdownRowModel(
        label: popup.l10n.stabilityBreakdownArtifacts,
        value: _signed(stability.artifactSources),
        positive: true,
      ),
  ];
  final costRows = <_BreakdownRowModel>[
    _stabilityCostRow(popup.l10n.stabilityBreakdownCities, stability.cityCost),
    _stabilityCostRow(
      popup.l10n.stabilityBreakdownPopulation,
      stability.populationCost,
    ),
    _stabilityCostRow(
      popup.l10n.stabilityBreakdownCohesion,
      stability.cohesionCost,
    ),
    _stabilityCostRow(
      popup.l10n.stabilityBreakdownConqueredCities,
      stability.conqueredCityCost,
    ),
    _stabilityCostRow(
      popup.l10n.stabilityBreakdownWarWeariness,
      stability.warWearinessCost,
    ),
    _stabilityCostRow(
      popup.l10n.stabilityBreakdownHegemony,
      stability.hegemonyTax,
    ),
  ];

  return [
    _BreakdownSectionModel(
      title: popup.l10n.commonSummary,
      rows: [
        _BreakdownRowModel(
          label: popup.l10n.stabilityBreakdownBand,
          value: _stabilityBandLabel(popup),
        ),
        _BreakdownRowModel(
          label: popup.l10n.stabilityBreakdownSources,
          value: _signed(stability.sources),
          positive: stability.sources > 0,
        ),
        _BreakdownRowModel(
          label: popup.l10n.stabilityBreakdownCosts,
          value: '-${stability.costs}',
          negative: stability.costs > 0,
        ),
        if (standingAdjustment != 0)
          _BreakdownRowModel(
            label: popup.l10n.stabilityBreakdownRelativeStanding,
            value: _signed(standingAdjustment),
            positive: standingAdjustment > 0,
            negative: standingAdjustment < 0,
          ),
        _BreakdownRowModel(
          label: popup.l10n.stabilityBreakdownNet,
          value: _signed(popup.stabilityNet),
          positive: popup.stabilityNet > 0,
          negative: popup.stabilityNet < 0,
        ),
      ],
    ),
    _BreakdownSectionModel(
      title: popup.l10n.stabilityBreakdownSources,
      rows: sourceRows,
    ),
    _BreakdownSectionModel(
      title: popup.l10n.stabilityBreakdownCosts,
      rows: costRows,
    ),
  ];
}

_BreakdownRowModel _stabilityCostRow(String label, int value) {
  return _BreakdownRowModel(
    label: label,
    value: value == 0 ? '0' : '-$value',
    negative: value > 0,
  );
}

String _stabilityBandLabel(ResourceBreakdownPopup popup) {
  return switch (popup.stabilityBand) {
    StabilityBand.content => popup.l10n.stabilityBandContent,
    StabilityBand.stable => popup.l10n.stabilityBandStable,
    StabilityBand.strained => popup.l10n.stabilityBandStrained,
    StabilityBand.unrest => popup.l10n.stabilityBandUnrest,
  };
}

List<_BreakdownSectionModel> _goldSections(ResourceBreakdownPopup popup) {
  final gold = popup.gold;
  return [
    _BreakdownSectionModel(
      title: popup.l10n.commonSummary,
      rows: [
        _BreakdownRowModel(
          label: popup.l10n.resourceBreakdownTreasury,
          value: '${gold.treasury}',
        ),
        _BreakdownRowModel(
          label: popup.l10n.resourceBreakdownCityIncome,
          value: _signed(gold.cityIncome),
          positive: gold.cityIncome > 0,
        ),
        if (gold.projectSources.isNotEmpty)
          _BreakdownRowModel(
            label: popup.l10n.commonProjects,
            value: _signed(gold.projectIncome),
            positive: gold.projectIncome > 0,
          ),
        _BreakdownRowModel(
          label: popup.l10n.resourceBreakdownUpkeep,
          value: '-${gold.unitUpkeep}',
          negative: gold.unitUpkeep > 0,
        ),
        _BreakdownRowModel(
          label: popup.l10n.resourceBreakdownNetPerTurn,
          value: _signed(gold.netPerTurn),
          positive: gold.netPerTurn > 0,
          negative: gold.netPerTurn < 0,
        ),
      ],
    ),
    _BreakdownSectionModel(
      title: popup.l10n.commonCities,
      rows: gold.citySources.isEmpty
          ? [
              _BreakdownRowModel(
                label: popup.l10n.resourceBreakdownNoCityIncome,
                value: '+0',
              ),
            ]
          : [
              for (final source in gold.citySources)
                _BreakdownRowModel(
                  label: GameDisplayNames.city(popup.l10n, source.city),
                  value: _signed(source.amount),
                  positive: source.amount > 0,
                ),
            ],
    ),
    if (gold.projectSources.isNotEmpty)
      _BreakdownSectionModel(
        title: popup.l10n.commonProjects,
        rows: [
          for (final source in gold.projectSources)
            _BreakdownRowModel(
              label:
                  '${GameDisplayNames.city(popup.l10n, source.city)}: ${popup.l10n.cityProjectWealth}',
              value: _signed(source.amount),
              positive: source.amount > 0,
            ),
        ],
      ),
    _BreakdownSectionModel(
      title: popup.l10n.unitsSection,
      rows: _unitUpkeepRows(popup),
    ),
  ];
}

List<_BreakdownRowModel> _unitUpkeepRows(ResourceBreakdownPopup popup) {
  final upkeep = popup.gold.upkeep;
  final rows = <_BreakdownRowModel>[
    _BreakdownRowModel(
      label: popup.l10n.resourceBreakdownFreeLimit,
      value: '${upkeep.unitCount}/${upkeep.freeUnitCount}',
    ),
    _BreakdownRowModel(
      label: popup.l10n.resourceBreakdownNextWorkerUpkeep,
      value: upkeep.nextWorkerUpkeep == 0
          ? '0'
          : popup.l10n.resourceBreakdownNextWorkerUpkeepValue(
              upkeep.nextWorkerUpkeep,
            ),
      negative: upkeep.nextWorkerUpkeep > 0,
    ),
  ];
  if (!upkeep.hasUpkeep) {
    rows.add(
      _BreakdownRowModel(
        label: popup.l10n.resourceBreakdownInsideFreeLimit,
        value: '0',
      ),
    );
    return rows;
  }

  for (final entry in upkeep.upkeepByType.entries) {
    final count = upkeep.paidUnitsByType[entry.key] ?? 0;
    rows.add(
      _BreakdownRowModel(
        label: '${GameDisplayNames.unitType(popup.l10n, entry.key)} x$count',
        value: '-${entry.value}',
        negative: entry.value > 0,
      ),
    );
  }
  return rows;
}

List<_BreakdownSectionModel> _scienceSections(ResourceBreakdownPopup popup) {
  final cityById = {for (final city in popup.cities) city.id: city};
  final activeLabel = popup.activeTechnologyName == null
      ? popup.l10n.resourceBreakdownNoActiveTechnology
      : popup.activeTechnologyName!;
  final activeEta = TurnEtaFormatter.fromTurns(
    turnsRemaining: popup.activeTechnologyTurnsRemaining,
    completionTurn: popup.activeTechnologyCompletionTurn,
    blockedLabel: '',
  );
  final activeValue = popup.activeTechnologyTurnsRemaining == null
      ? ''
      : activeEta.detailLabel(popup.l10n);

  return [
    _BreakdownSectionModel(
      title: popup.l10n.commonSummary,
      rows: [
        _BreakdownRowModel(
          label: popup.l10n.resourceBreakdownSciencePerTurn,
          value: _signed(popup.science.total),
          positive: popup.science.total > 0,
        ),
        _BreakdownRowModel(
          label: popup.l10n.resourceBreakdownActiveResearch,
          value: activeLabel,
        ),
        if (activeValue.isNotEmpty)
          _BreakdownRowModel(
            label: popup.l10n.resourceBreakdownTurnsToComplete,
            value: activeValue,
          ),
      ],
    ),
    _BreakdownSectionModel(
      title: popup.l10n.commonCities,
      rows: popup.science.sources.isEmpty
          ? [
              _BreakdownRowModel(
                label: popup.l10n.resourceBreakdownNoScienceSources,
                value: '+0',
              ),
            ]
          : [
              for (final source in popup.science.sources)
                _BreakdownRowModel(
                  label: _scienceSourceLabel(
                    source: source,
                    city: cityById[source.cityId],
                    popup: popup,
                  ),
                  value: _signed(source.amount),
                  positive: source.amount > 0,
                ),
            ],
    ),
  ];
}

String _scienceSourceLabel({
  required ScienceYieldSource source,
  required GameCity? city,
  required ResourceBreakdownPopup popup,
}) {
  final cityName = city == null
      ? source.cityId
      : GameDisplayNames.city(popup.l10n, city);
  return switch (source.label) {
    'City research project' => popup.l10n.resourceBreakdownCityResearchProject(
      cityName,
    ),
    _ => cityName,
  };
}

List<_BreakdownSectionModel> _resourceSections(ResourceBreakdownPopup popup) {
  final cityById = {for (final city in popup.cities) city.id: city};
  final resources = popup.resources;
  final network = popup.resourceNetwork;
  final resourceRows = resources.countsByType.isEmpty
      ? [
          _BreakdownRowModel(
            label: popup.l10n.resourceBreakdownNoControlledResources,
            value: '0',
          ),
        ]
      : [
          for (final entry in resources.countsByType.entries)
            _BreakdownRowModel(
              label: GameDisplayNames.resource(popup.l10n, entry.key),
              value: 'x${entry.value}',
              positive: entry.value > 0,
            ),
        ];
  for (final entry in network.hiddenCountsByType.entries) {
    resourceRows.add(
      _BreakdownRowModel(
        label: GameDisplayNames.resource(popup.l10n, entry.key),
        value: '?x${entry.value}',
      ),
    );
  }
  final sourceRows = resources.sources.isEmpty
      ? [
          _BreakdownRowModel(
            label: popup.l10n.resourceBreakdownGrowCitiesWithFood,
            value: '',
          ),
        ]
      : [
          for (final source in resources.sources)
            _BreakdownRowModel(
              label: _resourceSourceLabel(source, cityById, popup),
              value: GameDisplayNames.resource(popup.l10n, source.resource),
              positive: true,
            ),
        ];
  for (final source in network.hiddenSources) {
    sourceRows.add(
      _BreakdownRowModel(
        label: _resourceSourceLabel(source, cityById, popup),
        value: '? ${GameDisplayNames.resource(popup.l10n, source.resource)}',
      ),
    );
  }
  final gateRows = [
    for (final gate in network.unitGates)
      _BreakdownRowModel(
        label: GameDisplayNames.unitType(popup.l10n, gate.unitType),
        value: _resourceGateValue(gate, popup),
        positive: gate.satisfied,
        negative: gate.missingResources.isNotEmpty,
      ),
  ];

  return [
    _BreakdownSectionModel(
      title: popup.l10n.commonSummary,
      rows: [
        _BreakdownRowModel(
          label: popup.l10n.resourceBreakdownControlledDeposits,
          value: '${resources.totalCount}',
          positive: resources.totalCount > 0,
        ),
        _BreakdownRowModel(
          label: popup.l10n.resourceBreakdownResourceTypes,
          value: '${resources.distinctTypeCount}',
          positive: resources.distinctTypeCount > 0,
        ),
      ],
    ),
    _BreakdownSectionModel(
      title: popup.l10n.resourceBreakdownTypesSection,
      rows: resourceRows,
    ),
    _BreakdownSectionModel(
      title: popup.l10n.resourceBreakdownSourcesSection,
      rows: sourceRows,
    ),
    if (gateRows.isNotEmpty)
      _BreakdownSectionModel(title: popup.l10n.unitsSection, rows: gateRows),
  ];
}

String _resourceGateValue(
  EmpireResourceUnitGate gate,
  ResourceBreakdownPopup popup,
) {
  final resources = gate.satisfied
      ? gate.visibleControlledResources
      : gate.blockedByHiddenResource
      ? gate.hiddenControlledResources
      : gate.missingResources;
  final prefix = gate.satisfied
      ? '+ '
      : gate.blockedByHiddenResource
      ? '? '
      : '- ';
  return '$prefix${_resourceChoiceLabel(resources, popup)}';
}

String _resourceChoiceLabel(
  Iterable<ResourceType> resources,
  ResourceBreakdownPopup popup,
) {
  final names = [
    for (final resource in resources)
      GameDisplayNames.resource(popup.l10n, resource),
  ]..sort();
  return names.join(' / ');
}

String _resourceSourceLabel(
  CityResourceSource source,
  Map<String, GameCity> cityById,
  ResourceBreakdownPopup popup,
) {
  final city = cityById[source.cityId];
  final cityName = city == null
      ? source.cityId
      : GameDisplayNames.city(popup.l10n, city);
  return '$cityName (${source.hex.col}, ${source.hex.row})';
}

String _signed(int value) {
  return value > 0 ? '+$value' : '$value';
}
