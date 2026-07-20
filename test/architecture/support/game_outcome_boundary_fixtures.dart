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
