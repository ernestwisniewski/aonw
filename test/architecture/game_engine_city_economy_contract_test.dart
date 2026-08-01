import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/city_economy_family_pattern_guard.dart';
import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

const _gameEnginePath =
    'packages/aonw_core/lib/game/application/engine/game_engine.dart';
const _cityHandlerPath =
    'packages/aonw_core/lib/game/application/engine/'
    'city_engine_handler.dart';
const _productionHandlerPath =
    'packages/aonw_core/lib/game/application/engine/'
    'production_engine_handler.dart';
const _workerHandlerPath =
    'packages/aonw_core/lib/game/application/engine/'
    'worker_engine_handler.dart';
const _artifactTradeHandlerPath =
    'packages/aonw_core/lib/game/application/engine/'
    'artifact_trade_engine_handler.dart';

const _expectedDomainFamilies = <String, String>{
  'FoundCityCommand': 'city',
  'ToggleWorkedHexCommand': 'city',
  'SelectCityExpansionHexCommand': 'city',
  'StartBuildingCommand': 'production',
  'StartUnitProductionCommand': 'production',
  'StartCityProjectCommand': 'production',
  'StartWonderCommand': 'production',
  'SetCitySpecializationCommand': 'production',
  'RushProductionCommand': 'production',
  'SelectWorkerImprovementCommand': 'worker',
  'ConfirmWorkerImprovementCommand': 'worker',
  'CancelWorkerJobCommand': 'worker',
  'AssignWorkerToHexCommand': 'worker',
  'CancelWorkerAssignmentCommand': 'worker',
  'StartArtifactExcavationCommand': 'artifactTrade',
  'StoreArtifactInCityCommand': 'artifactTrade',
  'TradeArtifactCommand': 'artifactTrade',
  'OpenResourceTradeCommand': 'artifactTrade',
  'OpenResourceExchangeCommand': 'artifactTrade',
};

void main() {
  test('city economy classes have one executable role and handler family', () {
    final domainCommands = <DomainCommand>[
      FoundCityCommand('settler', controlledHexes: const []),
      const ToggleWorkedHexCommand('city', 1, 0),
      const SelectCityExpansionHexCommand('city', 1, 0),
      const StartBuildingCommand('city', CityBuildingType.granary),
      const StartUnitProductionCommand('city', GameUnitType.warrior),
      const StartCityProjectCommand('city', CityProjectType.wealth),
      const StartWonderCommand('city', WonderType.greatLibrary),
      const SetCitySpecializationCommand(
        'city',
        CitySpecializationType.industry,
      ),
      const RushProductionCommand('city'),
      const SelectWorkerImprovementCommand('worker', FieldImprovementType.farm),
      const ConfirmWorkerImprovementCommand('worker'),
      const CancelWorkerJobCommand('worker'),
      const AssignWorkerToHexCommand('worker'),
      const CancelWorkerAssignmentCommand('worker'),
      const StartArtifactExcavationCommand('scout'),
      const StoreArtifactInCityCommand('scout'),
      const TradeArtifactCommand(
        playerId: 'player_1',
        targetPlayerId: 'player_2',
        offeredArtifactId: 'artifact',
      ),
      const OpenResourceTradeCommand(
        playerId: 'player_1',
        targetPlayerId: 'player_2',
        resource: ResourceType.iron,
        goldPerTurn: 1,
        durationTurns: 1,
      ),
      const OpenResourceExchangeCommand(
        playerId: 'player_1',
        targetPlayerId: 'player_2',
        offeredResource: ResourceType.iron,
        requestedResource: ResourceType.horses,
        durationTurns: 1,
      ),
    ];

    expect({
      for (final command in domainCommands)
        command.runtimeType.toString():
            GameEngine.commandFamily(command)?.name ?? 'unhandled',
    }, _expectedDomainFamilies);
  });

  test('city economy picker and targeting commands remain intents', () {
    const intents = <GameIntent>[
      StartCityFoundingCommand(),
      CancelCityFoundingCommand(),
      StartCityWorkedHexSelectionCommand('city'),
      CancelCityWorkedHexSelectionCommand('city'),
      StartCityExpansionSelectionCommand('city'),
      CancelCityExpansionSelectionCommand('city'),
      StartWorkerActionSelectionCommand('worker'),
      CancelWorkerActionSelectionCommand('worker'),
    ];

    expect(intents, everyElement(isA<GameIntent>()));
  });

  test('city economy handlers have one game engine call-site each', () {
    final sources = productionDartSources();
    for (final handler in const [
      'CityEngineHandler',
      'ProductionEngineHandler',
      'WorkerEngineHandler',
      'ArtifactTradeEngineHandler',
    ]) {
      expect(
        instanceMemberReferenceCountsByPath(sources, handler, 'apply'),
        {_gameEnginePath: 1},
        reason: '$handler.apply must remain private to GameEngine.',
      );
    }
  });

  test('each canonical resolver method has exactly one engine call-site', () {
    final sources = productionDartSources();
    const expected = <(String, String), String>{
      ('DomainCityFoundingResolver', 'foundCity'): _cityHandlerPath,
      ('DomainCityWorkedHexResolver', 'toggleWorkedHex'): _cityHandlerPath,
      ('DomainCityExpansionResolver', 'selectExpansionHex'): _cityHandlerPath,
      ('DomainCityProductionResolver', 'startBuilding'): _productionHandlerPath,
      ('DomainCityProductionResolver', 'startUnitProduction'):
          _productionHandlerPath,
      ('DomainCityProductionResolver', 'startCityProject'):
          _productionHandlerPath,
      ('DomainCityProductionResolver', 'startWonder'): _productionHandlerPath,
      ('DomainCityProductionResolver', 'setCitySpecialization'):
          _productionHandlerPath,
      ('DomainCityProductionResolver', 'rushProduction'):
          _productionHandlerPath,
      ('DomainWorkerCommandResolver', 'selectWorkerImprovement'):
          _workerHandlerPath,
      ('DomainWorkerCommandResolver', 'confirmWorkerImprovement'):
          _workerHandlerPath,
      ('DomainWorkerCommandResolver', 'cancelWorkerJob'): _workerHandlerPath,
      ('DomainWorkerCommandResolver', 'assignWorkerToHex'): _workerHandlerPath,
      ('DomainWorkerCommandResolver', 'cancelWorkerAssignment'):
          _workerHandlerPath,
      ('DomainArtifactCommandResolver', 'startExcavation'):
          _artifactTradeHandlerPath,
      ('DomainArtifactCommandResolver', 'storeInCity'):
          _artifactTradeHandlerPath,
      ('DomainArtifactCommandResolver', 'tradeArtifact'):
          _artifactTradeHandlerPath,
      ('DomainResourceTradeCommandResolver', 'openGoldForResourceTrade'):
          _artifactTradeHandlerPath,
      ('DomainResourceTradeCommandResolver', 'openResourceForResourceTrade'):
          _artifactTradeHandlerPath,
    };
    for (final entry in expected.entries) {
      final (type, method) = entry.key;
      expect(
        instanceMemberReferenceCountsByPath(sources, type, method),
        {entry.value: 1},
        reason:
            '$type.$method must remain private to its focused engine handler.',
      );
    }
  });

  test('retired city economy adapters and reducers are absent', () {
    final paths = productionDartSources().keys;
    for (final fragment in const [
      'persistent_artifact_command_resolver.dart',
      'persistent_resource_trade_resolver.dart',
      'persistent_city_expansion_resolver.dart',
      'persistent_city_founding_resolver.dart',
      'persistent_city_production_resolver.dart',
      'persistent_city_worked_hex_resolver.dart',
      'persistent_worker_command_resolver.dart',
      '/artifact_reducer.dart',
      '/city_expansion_reducer.dart',
      '/city_production_reducer.dart',
      '/city_worked_hex_reducer.dart',
      '/resource_trade_reducer.dart',
      '/worker_reducer.dart',
    ]) {
      expect(
        paths.where((path) => path.contains(fragment)),
        isEmpty,
        reason: '$fragment is a retired parallel runtime.',
      );
    }
  });

  test(
    'local server AI and replay have only reviewed family switches',
    () async {
      final signatures = await cityEconomyFamilyPatternSignaturesByPath(
        _localServerAiReplaySources(productionDartSources()),
      );
      expect(signatures, reviewedCityEconomyFamilyPatternSignatures);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  test(
    'family ratchet rejects all duplicate executor forms',
    () async {
      const switchPath =
          'lib/game/application/services/second_city_executor.dart';
      const isPath =
          'lib/game/application/services/conditional_city_executor.dart';
      const handlerPath =
          'lib/game/application/services/direct_city_handler_executor.dart';
      const reviewedPath =
          'lib/game/application/services/ai_turn_command_executor.dart';
      final sources = {
        ..._localServerAiReplaySources(productionDartSources()),
        switchPath: '''
import 'package:aonw_core/domain.dart';

Object execute(Object command) => switch (command) {
  StartBuildingCommand() => command,
  _ => command,
};
''',
        isPath: '''
import 'package:aonw_core/domain.dart';

Object conditionalExecute(Object command) =>
    command is StartBuildingCommand ? command : Object();

Object ifExecute(Object command) {
  if (command is StartBuildingCommand) return command;
  return Object();
}
''',
        handlerPath: '''
import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';

Object directExecute(
  CanonicalGameSnapshot snapshot,
  DomainCommand command,
  GameEngineContext context,
) => const ProductionEngineHandler().apply(
  snapshot: snapshot,
  command: command,
  context: context,
);

Object handlerTearOff() => const ProductionEngineHandler().apply;
''',
      };
      sources[reviewedPath] =
          '''
${sources[reviewedPath]}

Object _duplicateBuildingConstructor() => StartBuildingCommand.new;
''';

      expect(
        await unreviewedCityEconomyFamilyPatternPaths(sources),
        containsAll([switchPath, isPath, handlerPath, reviewedPath]),
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}

Map<String, String> _localServerAiReplaySources(Map<String, String> sources) =>
    {
      for (final entry in sources.entries)
        if (entry.key.startsWith('lib/') ||
            entry.key.startsWith('server/lib/') ||
            entry.key.startsWith('server/bin/') ||
            entry.key.startsWith('packages/aonw_core/lib/ai/'))
          entry.key: entry.value,
    };
