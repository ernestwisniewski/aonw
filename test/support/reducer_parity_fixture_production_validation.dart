part of 'reducer_parity_fixture.dart';

const _requiredProductionAcceptanceModes = {
  'building',
  'unit',
  'project',
  'wonder',
  'rush',
};

String _productionAcceptanceMode(ReducerParityFixture fixture) {
  return switch (fixture.command) {
    StartBuildingCommand() => 'building',
    StartUnitProductionCommand() => 'unit',
    StartCityProjectCommand() => 'project',
    StartWonderCommand() => 'wonder',
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
}
