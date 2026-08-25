import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';

part 'support/rust_engine_inventory_census.dart';
part 'support/rust_engine_migration_manifest.dart';
part 'support/rust_engine_state_ledger.dart';

const _manifestPath = 'engine/migration/authoritative_inventory';
const _stateLedgerPath = 'engine/migration/state_field_ledger';

void main() {
  final manifest = _MigrationInventory.read(_manifestPath);
  final stateLedger = _StateFieldLedger.read(_stateLedgerPath);

  test('migration manifest matches Dart command AST census', () {
    expect(manifest.domainEntries, hasLength(39));
    expect(manifest.systemEntries, hasLength(2));

    expect(
      _concreteSubtypeSources(
        rootPath: manifest.dartDomainRoot,
        baseType: 'DomainCommand',
      ),
      {
        for (final entry in manifest.domainEntries)
          entry.dartType: entry.dartSource,
      },
    );
    expect(
      _concreteSubtypeSources(
        rootPath: manifest.dartSystemSource,
        baseType: 'SystemCommand',
      ),
      {
        for (final entry in manifest.systemEntries)
          entry.dartType: entry.dartSource,
      },
    );
  });

  test('migration manifest matches Rust enum census', () {
    expect(_rustEnumVariants(manifest.rustDomainSource, 'PlayerCommand'), {
      for (final entry in manifest.domainEntries)
        if (entry.rustVariant != null) entry.rustVariant!,
    });
    expect(
      _rustEnumVariants(manifest.rustClientCommandSource, 'ClientCommandDto'),
      {
        for (final entry in manifest.domainEntries)
          if (entry.rustVariant != null) entry.rustVariant!,
      },
      reason: 'Clients may expose only the implemented player command family.',
    );
    expect(manifest.rustSystemSource, isNotNull);
    expect(
      _rustEnumVariants(manifest.rustSystemSource!, 'SystemCommand'),
      {
        for (final entry in manifest.systemEntries)
          if (entry.rustVariant != null) entry.rustVariant!,
      },
      reason: 'Trusted commands use a separate non-client Rust boundary.',
    );
  });

  test('migration manifest closes queries, events, and evidence', () {
    expect(manifest.queryEntries, hasLength(11));
    expect(manifest.eventEntries, hasLength(40));
    expect(manifest.nativeEventEntries, hasLength(4));
    expect(manifest.evidenceEntries, hasLength(1));
    expect(manifest.nativeEvidenceEntries, hasLength(4));

    expect(_rustEnumVariants(manifest.rustQuerySource, 'GameQuery'), {
      for (final entry in manifest.queryEntries) entry.queryVariant,
    });
    expect(_rustEnumVariants(manifest.rustQuerySource, 'QueryResult'), {
      for (final entry in manifest.queryEntries) entry.resultVariant,
    });
    expect(
      _rustEnumVariants(
        manifest.rustClientResponseSource,
        'ClientQueryResultDto',
      ),
      {for (final entry in manifest.queryEntries) entry.clientResultVariant},
    );

    expect(
      _concreteSubtypeSources(
        rootPath: manifest.dartEventRoot,
        baseType: 'DomainEvent',
      ),
      {
        for (final entry in manifest.eventEntries)
          entry.dartType: entry.dartSource,
      },
    );
    final rustEventVariants = {
      for (final entry in manifest.eventEntries)
        if (entry.rustVariant != null) entry.rustVariant!,
      for (final entry in manifest.nativeEventEntries) entry.rustVariant,
    };
    for (final entry in manifest.nativeEventEntries) {
      expect(
        _rustDataTypeNames(entry.rustSource),
        contains(entry.rustType),
        reason: '${entry.rustType} missing from ${entry.rustSource}',
      );
    }
    expect(
      _rustEnumVariants(manifest.rustEventSource, 'DomainEvent'),
      rustEventVariants,
    );
    expect(
      _rustEnumVariants(manifest.rustPersistenceSource, 'ReplayEventDto'),
      rustEventVariants,
    );
    expect(
      _rustEnumVariants(manifest.rustClientEventSource, 'ClientEventDto'),
      rustEventVariants,
    );

    for (final entry in manifest.evidenceEntries) {
      expect(
        _dartClassNames(entry.dartSource),
        contains(entry.dartType),
        reason: '${entry.dartType} missing from ${entry.dartSource}',
      );
    }
    for (final entry in manifest.nativeEvidenceEntries) {
      expect(
        _rustDataTypeNames(entry.rustSource),
        contains(entry.rustType),
        reason: '${entry.rustType} missing from ${entry.rustSource}',
      );
    }
    final rustEvidenceVariants = {
      for (final entry in manifest.evidenceEntries) entry.rustVariant!,
      for (final entry in manifest.nativeEvidenceEntries) entry.rustVariant,
    };
    expect(
      _rustEnumVariants(manifest.rustEvidenceSource, 'ExecutionEvidence'),
      rustEvidenceVariants,
    );
    expect(
      _rustEnumVariants(manifest.rustPersistenceSource, 'ReplayEvidenceDto'),
      rustEvidenceVariants,
    );
    expect(
      _rustEnumVariants(manifest.rustClientResponseSource, 'ClientEvidenceDto'),
      rustEvidenceVariants,
    );
  });

  test('migration manifest closes recipient projection variants', () {
    expect(manifest.projectionTypes, hasLength(8));
    expect(manifest.projectionVariants, hasLength(9));
    for (final entry in manifest.projectionTypes) {
      expect(
        _rustStructNames(entry.rustSource),
        contains(entry.rustType),
        reason: '${entry.rustType} missing from ${entry.rustSource}',
      );
      expect(
        _rustStructNames(manifest.rustClientResponseSource),
        contains(entry.dtoType),
        reason:
            '${entry.dtoType} missing from ${manifest.rustClientResponseSource}',
      );
    }
    expect(
      _rustEnumVariants(manifest.rustProjectionSource, 'PendingActionView'),
      {for (final entry in manifest.projectionVariants) entry.rustVariant},
    );
    expect(
      _rustEnumVariants(
        manifest.rustClientResponseSource,
        'PendingActionViewDto',
      ),
      {for (final entry in manifest.projectionVariants) entry.dtoVariant},
    );
  });

  test('full-state parity promotions remain explicit after splice removal', () {
    expect(manifest.partialParityMode, 'full-state');
    expect(
      {
        for (final entry in manifest.entries)
          if (_requiresFullStateParity.contains(entry.status))
            entry.dartType: entry.status,
      },
      const {
        'AssignMerchantTradeRouteCommand': 'runtime-ready',
        'AssignWorkerToHexCommand': 'runtime-ready',
        'AttackHexCommand': 'runtime-ready',
        'AutoExploreUnitCommand': 'runtime-ready',
        'AutomateWorkerCommand': 'runtime-ready',
        'BuildRoadCommand': 'runtime-ready',
        'CancelUnitActionCommand': 'engine-parity',
        'CancelWorkerAssignmentCommand': 'runtime-ready',
        'CancelWorkerJobCommand': 'runtime-ready',
        'ConfirmWorkerImprovementCommand': 'runtime-ready',
        'DetachTroopCommand': 'runtime-ready',
        'FortifyUnitCommand': 'engine-parity',
        'FoundCityCommand': 'runtime-ready',
        'MoveMerchantToCityCommand': 'runtime-ready',
        'MoveUnitCommand': 'engine-parity',
        'SelectCityExpansionHexCommand': 'runtime-ready',
        'SelectWorkerImprovementCommand': 'runtime-ready',
        'SetCitySpecializationCommand': 'runtime-ready',
        'SkipUnitTurnCommand': 'engine-parity',
        'StartBuildingCommand': 'runtime-ready',
        'StartCityProjectCommand': 'runtime-ready',
        'StartUnitProductionCommand': 'runtime-ready',
        'StartWonderCommand': 'runtime-ready',
        'ToggleWorkedHexCommand': 'runtime-ready',
        'CityAttackedEvent': 'runtime-ready',
        'CityCapturedEvent': 'runtime-ready',
        'CityDestroyedEvent': 'runtime-ready',
        'CityFoundedEvent': 'runtime-ready',
        'CombatResolvedEvent': 'runtime-ready',
        'DiplomaticScoreChangedEvent': 'runtime-ready',
        'UnitAttackedEvent': 'runtime-ready',
        'UnitGainedExperienceEvent': 'runtime-ready',
        'UnitKilledEvent': 'runtime-ready',
        'UnitMovedEvent': 'engine-parity',
        'UnitRetreatedEvent': 'runtime-ready',
        'WorkerCompletedJobEvent': 'runtime-ready',
        'MovementCommandExecution': 'engine-parity',
      },
      reason: 'every promotion requires reviewed full-state parity evidence',
    );
    expect(
      {
        for (final entry in manifest.domainEntries)
          if (entry.status == 'engine-parity') entry.rustVariant,
      },
      const {'CancelUnitAction', 'FortifyUnit', 'MoveUnit', 'SkipUnitTurn'},
    );
  });

  test('canonical state representation is contract ready', () {
    expect(stateLedger.domainFields.map((entry) => entry.status).toSet(), {
      'state-contract-ready',
    });
    final canonicalEnvelopeStatuses = {
      for (final entry in stateLedger.envelopes)
        if ({
          'rust-canonical-state',
          'rust-save',
          'rust-replay',
        }.contains(entry.id))
          entry.id: entry.status,
    };
    expect(canonicalEnvelopeStatuses, {
      'rust-canonical-state': 'state-contract-ready',
      'rust-save': 'state-contract-ready',
      'rust-replay': 'state-contract-ready',
    });
  });

  test('command family counts remain explicit', () {
    expect(_familyCounts(manifest.domainEntries), const {
      'artifact-resource-trade': 5,
      'city': 3,
      'combat': 1,
      'diplomacy': 6,
      'infrastructure': 1,
      'movement': 7,
      'production': 6,
      'research': 1,
      'turn': 2,
      'unit-action': 2,
      'worker': 5,
    });
  });

  test('state ledger closes the 120 reducer fixture state envelopes', () {
    final fixtureFiles = Directory(stateLedger.fixtureRoot)
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList(growable: false);
    expect(fixtureFiles, hasLength(stateLedger.expectedFixtureCount));

    final stateKeys = stateLedger.stateJsonKeys
        .map((entry) => entry.key)
        .toSet();
    final requiredStateKeys = stateLedger.stateJsonKeys
        .where((entry) => entry.presence == 'required')
        .map((entry) => entry.key)
        .toSet();
    final observedStateKeys = <String>{};
    for (final file in fixtureFiles) {
      final root = (jsonDecode(file.readAsStringSync()) as Map)
          .cast<String, dynamic>();
      final input = (root['input'] as Map).cast<String, dynamic>();
      expect(input.keys.toSet(), const {
        'now',
        'actorPlayerId',
        'tick',
        'rulesetId',
        'map',
        'match',
        'save',
        'state',
        'command',
      }, reason: file.path);
      final state = (input['state'] as Map).cast<String, dynamic>();
      expect(stateKeys.containsAll(state.keys), isTrue, reason: file.path);
      expect(
        state.keys.toSet().containsAll(requiredStateKeys),
        isTrue,
        reason: file.path,
      );
      observedStateKeys.addAll(state.keys);
    }
    expect(observedStateKeys.containsAll(requiredStateKeys), isTrue);
  });

  test(
    'state ledger matches exact canonical and recipient envelope fields',
    () {
      for (final envelope in stateLedger.envelopes) {
        final expected = stateLedger.envelopeFields[envelope.id]!
            .map((field) => field.name)
            .toSet();
        final actual = switch (envelope.type) {
          'ReducerParityFixture' => expected,
          'CanonicalGameSnapshot' || 'GameSnapshotMetadata' =>
            _dartPublicFinalFields(envelope.source, envelope.type),
          _ => _rustStructFields(envelope.source, envelope.type),
        };
        expect(actual, expected, reason: '${envelope.id} (${envelope.type})');
      }
    },
  );

  test('state ledger matches DomainState and current codec keys', () {
    expect(
      _dartPublicFinalFields(stateLedger.dartDomainStateSource, 'DomainState'),
      {for (final entry in stateLedger.domainFields) entry.dartField},
    );

    final rustStateFields = _rustStructFields(
      stateLedger.rustStateDtoSource,
      'GameStateDto',
    );
    for (final entry in stateLedger.domainFields) {
      if (entry.rustField != null) {
        expect(
          rustStateFields,
          contains(entry.rustField),
          reason: entry.dartField,
        );
      }
    }

    final codecSource = File(
      stateLedger.dartDomainCodecSource,
    ).readAsStringSync();
    expect(_functionMapKeys(codecSource, 'encodeDomainState'), {
      for (final entry in stateLedger.stateJsonKeys) entry.key,
    });
    expect(
      {
        ..._functionMapKeys(codecSource, '_encodeActionLifecycle'),
        ..._functionMapKeys(codecSource, '_encodeTurnLifecycle'),
        ..._functionMapKeys(codecSource, '_encodeRuleLifecycle'),
      },
      {for (final entry in stateLedger.lifecycleJsonKeys) entry.key},
    );
  });

  test('state ledger format fails closed', () {
    final scratch = Directory.systemTemp.createTempSync('aonw-state-ledger-');
    addTearDown(() => scratch.deleteSync(recursive: true));
    final source = File(_stateLedgerPath).readAsStringSync();

    final wrongCount = File('${scratch.path}/wrong-count')
      ..writeAsStringSync(
        source.replaceFirst(
          'expected-domain-field-count 30',
          'expected-domain-field-count 29',
        ),
      );
    expect(
      () => _StateFieldLedger.read(wrongCount.path),
      throwsFormatException,
    );

    final unknownDirective = File('${scratch.path}/unknown-directive')
      ..writeAsStringSync('$source\nunknown-ledger-axis value\n');
    expect(
      () => _StateFieldLedger.read(unknownDirective.path),
      throwsFormatException,
    );
  });
}
