part of 'reducer_parity_fixture.dart';

const _requiredProductionAcceptanceModes = {
  'building',
  'unit',
  'project',
  'wonder',
  'specialization',
  'rush',
};

const _requiredSpecializationRejectionReasons = {
  'city_not_found',
  'city_not_controlled',
  'city_specialization_locked',
  'city_specialization_unchanged',
  'city_specialization_missing_building',
};

String _productionAcceptanceMode(ReducerParityFixture fixture) {
  return switch (fixture.command) {
    StartBuildingCommand() => 'building',
    StartUnitProductionCommand() => 'unit',
    StartCityProjectCommand() => 'project',
    StartWonderCommand() => 'wonder',
    SetCitySpecializationCommand() => 'specialization',
    RushProductionCommand() => 'rush',
    _ => throw StateError(
      '${fixture.id} uses an unreviewed city-production command.',
    ),
  };
}

void _requireProductionAcceptanceCoverage(
  _ReducerParityCorpusSummary summary,
  String family,
) {
  final actual = summary.productionAcceptanceModes;
  if (actual.length != _requiredProductionAcceptanceModes.length ||
      !actual.containsAll(_requiredProductionAcceptanceModes)) {
    throw StateError(
      '$family acceptance modes must be exactly: '
      '${_requiredProductionAcceptanceModes.toList()..sort()}.',
    );
  }
  final specializationReasons = summary.specializationRejectionReasons;
  if (specializationReasons.length !=
          _requiredSpecializationRejectionReasons.length ||
      !specializationReasons.containsAll(
        _requiredSpecializationRejectionReasons,
      )) {
    throw StateError(
      '$family specialization rejection reasons must be exactly: '
      '${_requiredSpecializationRejectionReasons.toList()..sort()}.',
    );
  }
}
