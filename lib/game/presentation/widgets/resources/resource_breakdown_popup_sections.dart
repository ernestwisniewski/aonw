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
    ScienceYieldSourceLabels.cityResearchProject =>
      popup.l10n.resourceBreakdownCityResearchProject(cityName),
    _ => cityName,
  };
}

List<_BreakdownSectionModel> _resourceSections(ResourceBreakdownPopup popup) {
  final cityById = {for (final city in popup.cities) city.id: city};
  final network = popup.resourceNetwork;
  final resourceRows = popup.resources.countsByType.isEmpty
      ? [
          _BreakdownRowModel(
            label: popup.l10n.resourceBreakdownNoControlledResources,
            value: '0',
          ),
        ]
      : [
          for (final entry in popup.resources.countsByType.entries)
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
  final sourceRows = popup.resources.sources.isEmpty
      ? [
          _BreakdownRowModel(
            label: popup.l10n.resourceBreakdownGrowCitiesWithFood,
            value: '',
          ),
        ]
      : [
          for (final source in popup.resources.sources)
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
    ..._strategicResourceSections(popup),
    _BreakdownSectionModel(
      title: popup.l10n.commonSummary,
      rows: [
        _BreakdownRowModel(
          label: popup.l10n.resourceBreakdownControlledDeposits,
          value: '${popup.resources.totalCount}',
          positive: popup.resources.totalCount > 0,
        ),
        _BreakdownRowModel(
          label: popup.l10n.resourceBreakdownResourceTypes,
          value: '${popup.resources.distinctTypeCount}',
          positive: popup.resources.distinctTypeCount > 0,
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

List<_BreakdownSectionModel> _strategicResourceSections(
  ResourceBreakdownPopup popup,
) {
  final strategic = popup.strategicResources;
  if (!strategic.enabled) return const [];
  return [
    _strategicStockpileSection(popup),
    _strategicFlowSection(popup),
    _strategicSourceSection(popup),
    _strategicAllocationSection(popup),
  ];
}

_BreakdownSectionModel _strategicStockpileSection(
  ResourceBreakdownPopup popup,
) => _BreakdownSectionModel(
  title: popup.l10n.diplomacyStrategicResourcesTitle,
  rows: [
    for (final row in popup.strategicResources.rows) ...[
      if (row.stockpiled)
        _BreakdownRowModel(
          label:
              '${GameDisplayNames.resource(popup.l10n, row.resource)} · ${popup.l10n.resourceBreakdownStored}',
          value: '${row.storedTotal}',
          negative: row.shortage,
        )
      else
        _BreakdownRowModel(
          label:
              '${GameDisplayNames.resource(popup.l10n, row.resource)} · ${popup.l10n.resourceBreakdownControlledDeposits}',
          value: '${row.controlledDeposits}',
          positive: row.controlledDeposits > 0,
        ),
      _BreakdownRowModel(
        label:
            '${GameDisplayNames.resource(popup.l10n, row.resource)} · ${popup.l10n.commonAvailable}',
        value: '${row.available}',
        positive: row.available > 0,
        negative: row.shortage,
      ),
      if (row.stockpiled)
        _BreakdownRowModel(
          label:
              '${GameDisplayNames.resource(popup.l10n, row.resource)} · ${popup.l10n.resourceBreakdownAllocated}',
          value: '${row.allocated}',
        ),
    ],
  ],
);

_BreakdownSectionModel _strategicSourceSection(ResourceBreakdownPopup popup) =>
    _BreakdownSectionModel(
      title: popup.l10n.resourceBreakdownSourcesSection,
      rows: [
        for (final source in popup.strategicResources.sources)
          _BreakdownRowModel(
            label: _strategicSourceLabel(source, popup),
            value: source.amountPerTurn == null
                ? ''
                : _signed(source.amountPerTurn!),
            positive: (source.amountPerTurn ?? 0) > 0,
            onTap: popup.onStrategicCityPressed == null
                ? null
                : () => popup.onStrategicCityPressed!(source.city),
          ),
      ],
    );

String _strategicSourceLabel(
  HudStrategicResourceSource source,
  ResourceBreakdownPopup popup,
) {
  final labels = <String>[
    GameDisplayNames.resource(popup.l10n, source.resource),
    if (source.improvement case final improvement?)
      GameDisplayNames.fieldImprovement(popup.l10n, improvement),
    '${GameDisplayNames.city(popup.l10n, source.city)} (${source.hex.col}, ${source.hex.row})',
  ];
  return labels.join(' · ');
}

_BreakdownSectionModel _strategicFlowSection(
  ResourceBreakdownPopup popup,
) => _BreakdownSectionModel(
  title: popup.l10n.resourceBreakdownNetPerTurn,
  rows: [
    for (final row in popup.strategicResources.rows) ...[
      if (row.stockpiled)
        _BreakdownRowModel(
          label:
              '${GameDisplayNames.resource(popup.l10n, row.resource)} · ${popup.l10n.resourceBreakdownDomesticProduction}',
          value: _signed(row.domesticProduction),
          positive: row.domesticProduction > 0,
        ),
      _BreakdownRowModel(
        label:
            '${GameDisplayNames.resource(popup.l10n, row.resource)} · ${popup.l10n.resourceBreakdownImports}',
        value: _signed(row.imports),
        positive: row.imports > 0,
      ),
      _BreakdownRowModel(
        label:
            '${GameDisplayNames.resource(popup.l10n, row.resource)} · ${popup.l10n.resourceBreakdownExports}',
        value: row.exports == 0 ? '0' : '-${row.exports}',
        negative: row.exports > 0,
      ),
      _BreakdownRowModel(
        label:
            '${GameDisplayNames.resource(popup.l10n, row.resource)} · ${popup.l10n.resourceBreakdownNetPerTurn}',
        value: _signed(row.netPerTurn),
        positive: row.netPerTurn > 0,
        negative: row.netPerTurn < 0,
      ),
    ],
  ],
);

_BreakdownSectionModel _strategicAllocationSection(
  ResourceBreakdownPopup popup,
) => _BreakdownSectionModel(
  title: popup.l10n.resourceBreakdownAllocations,
  rows: popup.strategicResources.allocations.isEmpty
      ? [
          _BreakdownRowModel(
            label: popup.l10n.resourceBreakdownNoAllocations,
            value: '',
          ),
        ]
      : [
          for (final allocation in popup.strategicResources.allocations)
            _BreakdownRowModel(
              label: _strategicAllocationLabel(allocation, popup),
              value: _strategicBundleLabel(allocation.bundle, popup),
              onTap: popup.onStrategicCityPressed == null
                  ? null
                  : () => popup.onStrategicCityPressed!(allocation.city),
            ),
        ],
);

String _strategicAllocationLabel(
  HudStrategicResourceAllocation allocation,
  ResourceBreakdownPopup popup,
) {
  final target = allocation.city.productionQueue?.target;
  final targetLabel = switch (target) {
    UnitProductionTarget(:final unitType) => GameDisplayNames.unitType(
      popup.l10n,
      unitType,
    ),
    _ => '',
  };
  final cityLabel = GameDisplayNames.city(popup.l10n, allocation.city);
  return targetLabel.isEmpty ? cityLabel : '$targetLabel · $cityLabel';
}

String _strategicBundleLabel(
  StrategicResourceBundle bundle,
  ResourceBreakdownPopup popup,
) {
  return bundle.amounts.entries
      .map(
        (entry) =>
            '${entry.value} ${GameDisplayNames.resource(popup.l10n, entry.key)}',
      )
      .join(' · ');
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
