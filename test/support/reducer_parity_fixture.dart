import 'dart:convert';
import 'dart:io';

import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

import 'reducer_parity_accepted_semantics.dart';
import 'reducer_parity_contract.dart';
import 'reducer_parity_production_semantics.dart';

final class ReducerParityFixture {
  const ReducerParityFixture({
    required this.id,
    required this.family,
    required this.now,
    required this.actorPlayerId,
    required this.tick,
    required this.mapData,
    required this.match,
    required this.save,
    required this.state,
    required this.command,
    required this.expectedAccepted,
    required this.expectedReason,
    required this.expectedSave,
    required this.expectedState,
    required this.expectedEvents,
  });

  final String id;
  final String family;
  final DateTime now;
  final String actorPlayerId;
  final int tick;
  final MapData mapData;
  final WireMatch match;
  final GameSave save;
  final PersistentGameState state;
  final GameCommand command;
  final bool expectedAccepted;
  final String? expectedReason;
  final Map<String, dynamic> expectedSave;
  final Map<String, dynamic> expectedState;
  final List<Map<String, dynamic>> expectedEvents;
}

abstract final class ReducerParityCorpus {
  static List<ReducerParityFixture> load(
    Directory repositoryRoot, {
    bool reverseInputMapEntries = false,
  }) {
    final directory = Directory(
      '${repositoryRoot.path}/test/fixtures/reducer_parity',
    );
    if (!directory.existsSync()) {
      throw StateError('Missing reducer parity fixture directory.');
    }

    final entries = directory.listSync()
      ..sort((left, right) {
        return left.path.compareTo(right.path);
      });
    final unexpected = <String>[];
    final files = <File>[];
    for (final entry in entries) {
      if (entry is File && entry.path.endsWith('.json')) {
        files.add(entry);
      } else if (_basename(entry.path) != 'README.md') {
        unexpected.add(_basename(entry.path));
      }
    }
    if (unexpected.isNotEmpty) {
      throw StateError(
        'Unexpected reducer parity fixture entries: ${unexpected.join(', ')}',
      );
    }
    if (files.isEmpty) throw StateError('Reducer parity corpus is empty.');

    final fixtures = files
        .map(
          (file) => _readFixture(
            file,
            reverseInputMapEntries: reverseInputMapEntries,
          ),
        )
        .toList(growable: false);
    _validateCorpus(fixtures);
    return fixtures;
  }

  static ReducerParityFixture _readFixture(
    File file, {
    required bool reverseInputMapEntries,
  }) {
    final root = _asMap(jsonDecode(file.readAsStringSync()), file.path);
    _requireExactKeys(root, const {
      'fixtureVersion',
      'id',
      'family',
      'input',
      'expected',
    }, file.path);
    final fixtureVersion = _asInt(root['fixtureVersion'], 'fixtureVersion');
    if (fixtureVersion != 1) {
      throw FormatException(
        'Unsupported fixtureVersion $fixtureVersion in ${file.path}.',
      );
    }

    final id = _asNonEmptyString(root['id'], 'id');
    if (_basename(file.path) != '$id.json') {
      throw FormatException(
        'Fixture id must match its filename: ${file.path}.',
      );
    }
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(id)) {
      throw FormatException('Fixture id is not kebab-case: $id.');
    }
    final family = _asNonEmptyString(root['family'], '$id.family');
    final decodedInput = root['input'];
    final input = _asMap(
      reverseInputMapEntries
          ? _reverseJsonMapEntries(decodedInput)
          : decodedInput,
      '$id.input',
    );
    _requireExactKeys(input, const {
      'now',
      'actorPlayerId',
      'tick',
      'rulesetId',
      'map',
      'match',
      'save',
      'state',
      'command',
    }, '$id.input');
    if (_asNonEmptyString(input['rulesetId'], '$id.rulesetId') != 'standard') {
      throw FormatException('$id must use the standard ruleset.');
    }

    final now = DateTime.parse(_asNonEmptyString(input['now'], '$id.now'));
    if (!now.isUtc) throw FormatException('$id.now must be UTC.');
    final actorPlayerId = _asNonEmptyString(
      input['actorPlayerId'],
      '$id.actorPlayerId',
    );
    final tick = _asInt(input['tick'], '$id.tick');
    if (tick < 0) throw FormatException('$id.tick must be non-negative.');
    final mapJson = _asMap(input['map'], '$id.map');
    final mapData = MapDataCodec.fromJson(jsonEncode(mapJson));
    final matchJson = _asMap(input['match'], '$id.match');
    final match = WireMatch.fromJson(matchJson);
    final saveJson = _asMap(input['save'], '$id.save');
    final save = GameSave.fromJson(saveJson);
    final stateJson = _asMap(input['state'], '$id.state');
    final state = PersistentGameState.fromJson(stateJson);
    _requireCanonicalJson(
      id,
      'map',
      jsonDecode(MapDataCodec.toJson(mapData)),
      mapJson,
    );
    _requireCanonicalJson(id, 'match', match.toJson(), matchJson);
    _requireCanonicalJson(id, 'save', save.toJson(), saveJson);
    _requireCanonicalJson(id, 'state', state.toJson(), stateJson);
    final commandJson = _asMap(input['command'], '$id.command');
    final command = GameCommandSerializer.fromJson(commandJson);
    if (!_jsonDeepEquals(GameCommandSerializer.toJson(command), commandJson)) {
      throw FormatException('$id.command is not in canonical serialized form.');
    }

    final expected = _asMap(root['expected'], '$id.expected');
    _requireExactKeys(expected, const {
      'accepted',
      'reason',
      'save',
      'state',
      'events',
    }, '$id.expected');
    final accepted = _asBool(expected['accepted'], '$id.accepted');
    final reason = _asNullableString(expected['reason'], '$id.reason');
    if (accepted == (reason != null)) {
      throw FormatException(
        '$id must have a null reason exactly when it is accepted.',
      );
    }
    final expectedSave = _asMap(expected['save'], '$id.expected.save');
    final expectedState = _asMap(expected['state'], '$id.expected.state');
    final expectedEvents = _asMapList(
      expected['events'],
      '$id.expected.events',
    );

    final fixture = ReducerParityFixture(
      id: id,
      family: family,
      now: now,
      actorPlayerId: actorPlayerId,
      tick: tick,
      mapData: mapData,
      match: match,
      save: save,
      state: state,
      command: command,
      expectedAccepted: accepted,
      expectedReason: reason,
      expectedSave: expectedSave,
      expectedState: expectedState,
      expectedEvents: expectedEvents,
    );
    _validateFixture(fixture);
    return fixture;
  }

  static void _validateCorpus(List<ReducerParityFixture> fixtures) {
    final ids = <String>{};
    final coverage = <String, Set<bool>>{};
    final acceptedCountByFamily = <String, int>{};
    final rejectionReasonsByFamily = <String, Set<String>>{};
    final resourceTradeAcceptanceModes = <String>{};
    final turnAcceptanceModes = <String>{};
    for (final fixture in fixtures) {
      if (!ids.add(fixture.id)) {
        throw StateError('Duplicate reducer parity fixture id: ${fixture.id}.');
      }
      coverage
          .putIfAbsent(fixture.family, () => <bool>{})
          .add(fixture.expectedAccepted);
      if (fixture.expectedAccepted) {
        acceptedCountByFamily.update(
          fixture.family,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        if (fixture.family == 'turn-finalization') {
          turnAcceptanceModes.add(
            fixture.expectedSave['turn'] == fixture.save.turn
                ? 'waiting'
                : 'finalizing',
          );
        }
        if (fixture.family == 'resource-trade') {
          resourceTradeAcceptanceModes.add(switch (fixture.command) {
            OpenResourceTradeCommand() => 'gold',
            OpenResourceExchangeCommand() => 'exchange',
            _ => 'unexpected',
          });
        }
      } else {
        rejectionReasonsByFamily
            .putIfAbsent(fixture.family, () => <String>{})
            .add(fixture.expectedReason!);
      }
    }
    if (coverage.keys
            .toSet()
            .difference(reducerParityRequiredFamilies)
            .isNotEmpty ||
        reducerParityRequiredFamilies
            .difference(coverage.keys.toSet())
            .isNotEmpty) {
      throw StateError(
        'Reducer parity families must be exactly: '
        '${reducerParityRequiredFamilies.toList()..sort()}.',
      );
    }
    for (final family in reducerParityRequiredFamilies) {
      if (coverage[family]?.containsAll(const {true, false}) != true) {
        throw StateError(
          '$family needs accepted and rejected parity fixtures.',
        );
      }
      if (family == 'turn-finalization') {
        if ((acceptedCountByFamily[family] ?? 0) < 2 ||
            !turnAcceptanceModes.containsAll(const {'waiting', 'finalizing'})) {
          throw StateError(
            '$family needs waiting/finalizing accepts and actor/semantic rejects.',
          );
        }
      }
      if (family == 'resource-trade' &&
          !resourceTradeAcceptanceModes.containsAll(const {
            'gold',
            'exchange',
          })) {
        throw StateError(
          '$family needs accepted gold and exchange parity fixtures.',
        );
      }
      final requiredReasons = reducerParityRequiredRejectionReasons[family]!;
      if (rejectionReasonsByFamily[family]?.containsAll(requiredReasons) !=
          true) {
        throw StateError(
          '$family needs rejection reasons: ${requiredReasons.toList()..sort()}.',
        );
      }
    }
  }

  static void _validateFixture(ReducerParityFixture fixture) {
    if (fixture.match.id != fixture.save.id ||
        fixture.match.mapName != fixture.save.mapName ||
        fixture.match.turn != fixture.save.turn ||
        fixture.mapData.mapName != fixture.save.mapName) {
      _fail(fixture, 'has inconsistent match/save/map ids');
    }
    if (fixture.match.state != 'running') {
      throw FormatException('${fixture.id} must describe a running match.');
    }
    final playerIds = fixture.save.players.map((player) => player.id).toSet();
    final matchPlayerIds = fixture.match.players
        .map((player) => player.id)
        .toSet();
    final permitsExternalTurnActor =
        fixture.family == 'turn-finalization' &&
        !fixture.expectedAccepted &&
        fixture.expectedReason == 'turn_player_not_active' &&
        fixture.command is SubmitTurnCommand &&
        (fixture.command as SubmitTurnCommand).playerId ==
            fixture.actorPlayerId;
    if (matchPlayerIds.length != playerIds.length ||
        !matchPlayerIds.containsAll(playerIds) ||
        (!permitsExternalTurnActor &&
            !playerIds.contains(fixture.actorPlayerId)) ||
        !fixture.state.playerColors.keys.toSet().containsAll(playerIds) ||
        !fixture.state.playerCountries.keys.toSet().containsAll(playerIds)) {
      _fail(fixture, 'must define its actor and full player identity maps');
    }
    if (fixture.state.playerGold.isEmpty ||
        fixture.state.playerWarWeariness.isEmpty ||
        fixture.state.playerStabilityNet.isEmpty) {
      _fail(fixture, 'must retain sentinel values in unchanged state slices');
    }
    if (!reducerParityCommandMatchesFamily(fixture.family, fixture.command)) {
      _fail(fixture, 'command does not match family ${fixture.family}');
    }

    final runtime = fixture.state.runtimeState;
    if (runtime.cityFoundingDraft != null || runtime.pendingAction != null) {
      _fail(fixture, 'uses client interaction fields outside parity scope');
    }
    final expectedSave = GameSave.fromJson({
      ...fixture.expectedSave,
      'savedAt': fixture.save.savedAt.toUtc().toIso8601String(),
    });
    _requireCanonicalJson(
      fixture.id,
      'expected.save',
      reducerParitySave(expectedSave),
      fixture.expectedSave,
    );
    final inputSave = reducerParitySave(fixture.save);
    final inputState = fixture.state.toJson();
    if (!fixture.expectedAccepted) {
      if (!_jsonDeepEquals(fixture.expectedSave, inputSave) ||
          !_jsonDeepEquals(fixture.expectedState, inputState) ||
          fixture.expectedEvents.isNotEmpty ||
          fixture.expectedReason == null) {
        _fail(fixture, 'rejected result must preserve canonical input');
      }
      return;
    }

    final changed =
        !_jsonDeepEquals(fixture.expectedSave, inputSave) ||
        !_jsonDeepEquals(fixture.expectedState, inputState) ||
        fixture.expectedEvents.isNotEmpty;
    if (!changed) {
      _fail(fixture, 'accepted fixture must have an observable domain change');
    }
    _validateAcceptedSemantics(fixture);
  }

  static void _validateAcceptedSemantics(ReducerParityFixture fixture) {
    final state = PersistentGameState.fromJson(fixture.expectedState);
    final events = fixture.expectedEvents
        .map(GameEventSerializer.fromJson)
        .toList(growable: false);
    if (tryRequireProduction(
      fixture.id,
      fixture.command,
      fixture.state,
      state,
      events,
    )) {
      return;
    }
    switch (fixture.command) {
      case AutoExploreUnitCommand() ||
          MoveUnitCommand() ||
          AssignMerchantTradeRouteCommand() ||
          MoveMerchantToCityCommand():
        requireAcceptedUnitAction(
          fixtureId: fixture.id,
          command: fixture.command,
          before: fixture.state,
          after: state,
          events: events,
        );
      case AttackHexCommand(:final attackerUnitId):
        requireAcceptedCombat(fixture.id, attackerUnitId, state, events);
      case final DetachTroopCommand command:
        final failure = validateAcceptedDetachment(
          command: command,
          before: fixture.state,
          after: state,
          actorPlayerId: fixture.actorPlayerId,
          events: events,
        );
        if (failure != null) _fail(fixture, failure);
      case SelectTechnologyCommand(:final playerId, :final technologyId):
        if (state.research.forPlayer(playerId).activeTechnologyId !=
            technologyId) {
          _fail(fixture, 'must commit the reviewed research selection');
        }
      case OpenResourceTradeCommand() || OpenResourceExchangeCommand():
        if (!_jsonDeepEquals(
          fixture.expectedSave,
          reducerParitySave(fixture.save),
        )) {
          _fail(fixture, 'must preserve save metadata for resource trade');
        }
        requireAcceptedResourceTrade(
          fixtureId: fixture.id,
          command: fixture.command,
          before: fixture.state,
          after: state,
          events: events,
        );
      case ConfirmWorkerImprovementCommand(
        :final unitId,
        :final improvementType,
      ):
        final worker = state.units.byId(unitId);
        if (improvementType == null ||
            worker?.workerJob?.improvementType != improvementType ||
            worker?.movementPoints != 0) {
          _fail(fixture, 'must commit the reviewed worker job');
        }
      case final SubmitTurnCommand command:
        requireAcceptedTurnSubmission(
          fixtureId: fixture.id,
          command: command,
          inputTurn: fixture.save.turn,
          playerIds: fixture.save.players.map((player) => player.id),
          expectedTurn: fixture.expectedSave['turn'],
          expectedPlayerStates: _asMap(
            fixture.expectedSave['playerStates'],
            '${fixture.id}.expected.save.playerStates',
          ),
          before: fixture.state,
          after: state,
          now: fixture.now,
          events: events,
        );
      default:
        _fail(fixture, 'uses a command outside the reviewed parity corpus');
    }
  }

  static Never _fail(ReducerParityFixture fixture, String message) =>
      throw FormatException('${fixture.id} $message.');
}

Map<String, dynamic> reducerParitySave(GameSave save) {
  return Map<String, dynamic>.from(save.toJson())..remove('savedAt');
}

List<Map<String, dynamic>> reducerParityEvents(Iterable<GameEvent> events) {
  return events.map(GameEventSerializer.toJson).toList(growable: false);
}

Map<String, dynamic> _asMap(Object? value, String field) {
  if (value is Map<Object?, Object?>) return Map<String, dynamic>.from(value);
  throw FormatException('$field must be a JSON object.');
}

List<Map<String, dynamic>> _asMapList(Object? value, String field) {
  if (value is! List<Object?>) {
    throw FormatException('$field must be a JSON array.');
  }
  return [
    for (var index = 0; index < value.length; index++)
      _asMap(value[index], '$field[$index]'),
  ];
}

String _asNonEmptyString(Object? value, String field) {
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('$field must be a non-empty string.');
}

String? _asNullableString(Object? value, String field) {
  if (value == null) return null;
  return _asNonEmptyString(value, field);
}

int _asInt(Object? value, String field) {
  if (value is int) return value;
  throw FormatException('$field must be an integer.');
}

bool _asBool(Object? value, String field) {
  if (value is bool) return value;
  throw FormatException('$field must be a boolean.');
}

void _requireExactKeys(
  Map<String, dynamic> value,
  Set<String> expected,
  String field,
) {
  final actual = value.keys.toSet();
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    throw FormatException(
      '$field keys must be exactly ${expected.toList()..sort()}.',
    );
  }
}

void _requireCanonicalJson(
  String id,
  String field,
  Object? canonical,
  Object? input,
) {
  if (!_jsonDeepEquals(canonical, input)) {
    throw FormatException('$id.$field is not in canonical serialized form.');
  }
}

bool _jsonDeepEquals(Object? left, Object? right) {
  if (identical(left, right)) return true;
  if (left is Map<Object?, Object?> && right is Map<Object?, Object?>) {
    if (left.length != right.length || !left.keys.every(right.containsKey)) {
      return false;
    }
    return left.entries.every(
      (entry) => _jsonDeepEquals(entry.value, right[entry.key]),
    );
  }
  if (left is List<Object?> && right is List<Object?>) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!_jsonDeepEquals(left[index], right[index])) return false;
    }
    return true;
  }
  return left == right;
}

Object? _reverseJsonMapEntries(Object? value) {
  if (value is Map<Object?, Object?>) {
    return <String, dynamic>{
      for (final entry in value.entries.toList(growable: false).reversed)
        entry.key as String: _reverseJsonMapEntries(entry.value),
    };
  }
  if (value is List<Object?>) {
    return [for (final element in value) _reverseJsonMapEntries(element)];
  }
  return value;
}

String _basename(String path) {
  return path.split(RegExp(r'[/\\]')).last;
}
