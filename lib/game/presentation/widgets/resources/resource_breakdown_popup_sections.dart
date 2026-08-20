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
      rows: _goldSummaryRows(popup),
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
                  onTap: _cityTap(popup, source.city),
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
              onTap: _cityTap(popup, source.city),
            ),
        ],
      ),
    _BreakdownSectionModel(
      title: popup.l10n.unitsSection,
      rows: _unitUpkeepRows(popup),
    ),
  ];
}

List<_BreakdownRowModel> _goldSummaryRows(ResourceBreakdownPopup popup) {
  final gold = popup.gold;
  return [
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
                  onTap: _cityTap(popup, cityById[source.cityId]),
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
  final categories = ResourcePopupCategoryDataBuilder(
    resources: popup.resources,
    network: popup.resourceNetwork,
    strategic: popup.strategicResources,
    cities: popup.cities,
    l10n: popup.l10n,
  ).build();

  return [
    for (final category in categories)
      _BreakdownSectionModel(
        key: Key('resourceBreakdown.category.${category.category.name}'),
        title: category.title,
        accent: switch (category.category) {
          ResourcePopupCategory.bonus => GameUiTheme.success,
          ResourcePopupCategory.luxury => GameUiTheme.gold,
          ResourcePopupCategory.strategic => GameUiTheme.resourcesAccent,
        },
        separatedBefore: category.category == ResourcePopupCategory.strategic,
        rows: [
          for (final row in category.rows)
            _BreakdownRowModel(
              label: row.label,
              value: row.value,
              positive: row.positive,
              negative: row.negative,
              muted: row.muted,
              groupLabel: row.groupLabel,
              onTap: _cityTap(popup, row.targetCity),
            ),
        ],
      ),
  ];
}

VoidCallback? _cityTap(ResourceBreakdownPopup popup, GameCity? city) {
  final onCityPressed = popup.onCityPressed;
  if (city == null || onCityPressed == null) return null;
  return () => onCityPressed(city);
}

String _signed(int value) {
  return value > 0 ? '+$value' : '$value';
}
