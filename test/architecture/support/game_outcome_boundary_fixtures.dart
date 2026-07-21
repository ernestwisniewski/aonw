part of '../game_outcome_boundary_test.dart';

const _canonicalSnapshotReferenceFixtures = {
  'direct': '''
part of 'server_command_reducer.dart';

extension ExtraReducerPath on ServerCommandReducer {
  void apply() {
    _canonicalSnapshot(save: save, state: state, eventLogOffset: 0);
  }
}
''',
  'tear-off': '''
part of 'server_command_reducer.dart';

extension ExtraReducerPath on ServerCommandReducer {
  void apply() {
    final conversion = _canonicalSnapshot;
    conversion;
  }
}
''',
  'explicit .call': '''
part of 'server_command_reducer.dart';

extension ExtraReducerPath on ServerCommandReducer {
  void apply() {
    _canonicalSnapshot.call(
      save: save,
      state: state,
      eventLogOffset: 0,
    );
  }
}
''',
};

const _canonicalSnapshotShadowingFixtures = {
  'variable': (
    source: '''
part of 'server_command_reducer.dart';

extension ExtraReducerPath on ServerCommandReducer {
  void _acceptedReduction() {
    final _canonicalSnapshot = _wrongConverter;
    _canonicalSnapshot();
  }
}
''',
    violation:
        'reducer library must not declare _canonicalSnapshot variables; '
        'found 1',
  ),
  'declared identifier': (
    source: '''
part of 'server_command_reducer.dart';

extension ExtraReducerPath on ServerCommandReducer {
  void _acceptedReduction() {
    for (final _canonicalSnapshot in converters) {
      _canonicalSnapshot();
    }
  }
}
''',
    violation:
        'reducer library must not declare _canonicalSnapshot variables; '
        'found 1',
  ),
  'declared variable pattern': (
    source: '''
part of 'server_command_reducer.dart';

extension ExtraReducerPath on ServerCommandReducer {
  void _acceptedReduction() {
    var [_canonicalSnapshot] = converters;
    _canonicalSnapshot();
  }
}
''',
    violation:
        'reducer library must not declare _canonicalSnapshot variables; '
        'found 1',
  ),
  'catch parameter': (
    source: '''
part of 'server_command_reducer.dart';

extension ExtraReducerPath on ServerCommandReducer {
  void _acceptedReduction() {
    try {
      run();
    } catch (_canonicalSnapshot) {
      _canonicalSnapshot();
    }
  }
}
''',
    violation:
        'reducer library must not declare _canonicalSnapshot variables; '
        'found 1',
  ),
  'parameter': (
    source: '''
part of 'server_command_reducer.dart';

extension ExtraReducerPath on ServerCommandReducer {
  void _acceptedReduction(void Function() _canonicalSnapshot) {
    _canonicalSnapshot();
  }
}
''',
    violation:
        'reducer library must not declare _canonicalSnapshot parameters; '
        'found 1',
  ),
  'method': (
    source: '''
part of 'server_command_reducer.dart';

extension ExtraReducerPath on ServerCommandReducer {
  void _acceptedReduction() {
    _canonicalSnapshot();
  }

  void _canonicalSnapshot() {}
}
''',
    violation:
        'reducer library must not declare _canonicalSnapshot methods; found 1',
  ),
  'local function': (
    source: '''
part of 'server_command_reducer.dart';

extension ExtraReducerPath on ServerCommandReducer {
  void _acceptedReduction() {
    void _canonicalSnapshot() {}
    _canonicalSnapshot();
  }
}
''',
    violation:
        'reducer library must not declare other _canonicalSnapshot functions; '
        'found 1',
  ),
};

const _canonicalSnapshotProviderFixtures = {
  'direct': '''
part of 'server_command_reducer.dart';

extension ExtraReducerPath on ServerCommandReducer {
  _CommandApplication apply() {
    return _CommandApplication.accept(
      save: save,
      state: state,
      canonicalSnapshot: snapshot,
    );
  }
}
''',
  'tear-off': '''
part of 'server_command_reducer.dart';

extension ExtraReducerPath on ServerCommandReducer {
  _CommandApplication apply() {
    final accept = _CommandApplication.accept;
    return accept(
      save: save,
      state: state,
      canonicalSnapshot: staleSnapshot,
    );
  }
}
''',
};

const _acceptFactoryForwardingFixtures = {
  'throwaway construction': '''
class _CommandApplication {
  _CommandApplication({this.canonicalSnapshot});

  final CanonicalGameSnapshot? canonicalSnapshot;

  factory _CommandApplication.accept({
    CanonicalGameSnapshot? canonicalSnapshot,
  }) {
    _CommandApplication(canonicalSnapshot: canonicalSnapshot);
    return _CommandApplication();
  }
}
''',
  'parameter mutation': '''
class _CommandApplication {
  _CommandApplication({this.canonicalSnapshot});

  final CanonicalGameSnapshot? canonicalSnapshot;

  factory _CommandApplication.accept({
    CanonicalGameSnapshot? canonicalSnapshot,
  }) {
    canonicalSnapshot = null;
    return _CommandApplication(canonicalSnapshot: canonicalSnapshot);
  }
}
  ''',
};

final _acceptedReductionEncodeFixtures = {
  'previous state from result': (
    source: _acceptedReductionFixture(
      previousState: 'final previousState = result.state;',
    ),
    violation:
        '_acceptedReduction must declare final previousState from '
        'decodedSnapshot.state',
  ),
  'identity save comparison': (
    source: _acceptedReductionFixture(
      encode:
          '_runningMatchSnapshotCodec.encode(decodedSnapshot, '
          'save: identical(nextSave, decodedSnapshot.save) ? null : nextSave, '
          'state: result.state == previousState ? null : result.state)',
    ),
    violation:
        '_acceptedReduction must use value equality (==), never identical',
  ),
  'inequality state comparison': (
    source: _acceptedReductionFixture(
      encode:
          '_runningMatchSnapshotCodec.encode(decodedSnapshot, '
          'save: nextSave == decodedSnapshot.save ? null : nextSave, '
          'state: result.state != previousState ? null : result.state)',
    ),
    violation:
        '_acceptedReduction encode must receive decodedSnapshot and '
        'change-only save/state values',
  ),
  'missing codec encode': (
    source: _acceptedReductionFixture(encode: 'decodedSnapshot.wire'),
    violation:
        '_acceptedReduction must call _runningMatchSnapshotCodec.encode '
        'exactly once; found 0',
  ),
  'second codec encode': (
    source: _acceptedReductionFixture(
      afterEncode: '''
    _runningMatchSnapshotCodec.encode(
      decodedSnapshot,
      save: nextSave,
      state: result.state,
    );''',
    ),
    violation:
        '_acceptedReduction must call _runningMatchSnapshotCodec.encode '
        'exactly once; found 2',
  ),
  'wire snapshot construction': (
    source: _acceptedReductionFixture(
      afterEncode:
          'WireSnapshot(save: nextSave.toJson(), state: result.state.toJson());',
    ),
    violation: '_acceptedReduction must not construct a WireSnapshot',
  ),
  'direct snapshot patch': (
    source: _acceptedReductionFixture(
      afterEncode:
          'decodedSnapshot.wire.copyWith('
          'save: nextSave.toJson(), state: result.state.toJson());',
    ),
    violation: '_acceptedReduction must not patch snapshot save/state directly',
  ),
  'discarded codec result': (
    source: _acceptedReductionFixture(
      reductionSnapshot: 'decodedSnapshot.wire',
    ),
    violation: '_acceptedReduction must return the codec-encoded snapshot',
  ),
  'wrong reduction previous state': (
    source: _acceptedReductionFixture(
      reductionPreviousState: 'decodedSnapshot.state',
    ),
    violation:
        '_acceptedReduction must expose previousState: previousState and '
        'state: result.state',
  ),
  'wrong reduction next state': (
    source: _acceptedReductionFixture(reductionState: 'previousState'),
    violation:
        '_acceptedReduction must expose previousState: previousState and '
        'state: result.state',
  ),
};

final _acceptedReductionFallbackFixtures = {
  'wrong fallback save': (
    source: _acceptedReductionFallbackFixture('''_canonicalSnapshot(
        save: decodedSnapshot.save,
        state: result.state,
        eventLogOffset: decodedSnapshot.eventLogOffset,
      )'''),
    violation:
        '_acceptedReduction canonicalSnapshot fallback must use nextSave, '
        'result.state, and decodedSnapshot.eventLogOffset',
  ),
  'wrong fallback offset': (
    source: _acceptedReductionFallbackFixture('''_canonicalSnapshot(
        save: nextSave,
        state: result.state,
        eventLogOffset: 0,
      )'''),
    violation:
        '_acceptedReduction canonicalSnapshot fallback must use nextSave, '
        'result.state, and decodedSnapshot.eventLogOffset',
  ),
};

const _acceptedReductionForwardingFixtures = {
  'normal reduction mutation': (
    source: '''
class Reducer {
  void reduce() {
    _acceptedReduction(
      decodedSnapshot: decodedSnapshot.withState(result.state),
    );
  }
}
''',
    methodName: 'reduce',
    violation:
        'reduce must forward decodedSnapshot unchanged to _acceptedReduction',
  ),
  'timeout reduction mutation': (
    source: '''
class Reducer {
  void reduceTimedOutTurn() {
    _acceptedReduction(decodedSnapshot: otherSnapshot);
  }
}
''',
    methodName: 'reduceTimedOutTurn',
    violation:
        'reduceTimedOutTurn must forward decodedSnapshot unchanged to '
        '_acceptedReduction',
  ),
};

String _acceptedReductionFixture({
  String previousState = 'final previousState = decodedSnapshot.state;',
  String encode =
      '_runningMatchSnapshotCodec.encode(decodedSnapshot, '
      'save: nextSave == decodedSnapshot.save ? null : nextSave, '
      'state: result.state == previousState ? null : result.state)',
  String afterEncode = '',
  String reductionSnapshot = 'nextSnapshot',
  String reductionPreviousState = 'previousState',
  String reductionState = 'result.state',
}) =>
    '''
extension Fixture on Reducer {
  ServerCommandReduction _acceptedReduction({
    required WireMatch match,
    required DecodedMatchSnapshot decodedSnapshot,
    required GameSave nextSave,
    required _CommandApplication result,
    required MapReadView mapView,
  }) {
    $previousState
    final nextSnapshot = $encode;
    $afterEncode
    return ServerCommandReduction(
      accepted: true,
      snapshot: $reductionSnapshot,
      previousState: $reductionPreviousState,
      state: $reductionState,
    );
  }
}
''';

String _acceptedReductionFallbackFixture(String fallback) =>
    '''
extension Fixture on Reducer {
  void _acceptedReduction({
    required WireMatch match,
    required DecodedMatchSnapshot decodedSnapshot,
    required GameSave nextSave,
    required _CommandApplication result,
    required MapReadView mapView,
  }) {
    final canonicalSnapshot = result.canonicalSnapshot ?? $fallback;
    _gameOutcome(
      domain: canonicalSnapshot.domain,
      session: canonicalSnapshot.session,
    );
  }
}
''';
