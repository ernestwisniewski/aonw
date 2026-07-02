part of 'resource_breakdown_popup.dart';

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
          value: StabilityBandPresentation.label(
            popup.l10n,
            popup.stabilityBand,
          ),
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
