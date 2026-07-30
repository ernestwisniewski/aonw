part of '../world_map_projection_boundary_test.dart';

void _registerLocalReducerMapViewFixtures() {
  test('local reducer map-view guard accepts one indexed view per root', () {
    expect(
      _localReducerMapViewViolationsFor(_localReducerGuardFixture()),
      isEmpty,
    );
  });

  test('local reducer map-view guard rejects raw and duplicate map reads', () {
    final sources = _localReducerGuardFixture();
    sources[_gameStateProviderPath] = '''
void build(session) {
  final reducer = GameStateReducer(mapData: session.mapData);
}
''';
    sources[_localCommandResolverPath] = '''
void finalize(reducer) {
  final duplicate = reducer.mapData.indexedReadView();
  CanonicalTurnPipelineRequest.simultaneousFinalize(mapView: duplicate);
}
''';

    expect(
      _localReducerMapViewViolationsFor(sources),
      containsAll([
        '$_gameStateProviderPath must pass an approved indexed MapReadView '
            'to GameStateReducer.mapData; found session.mapData',
        '$_gameStateProviderPath must call indexedReadView exactly 1 time(s); '
            'found 0',
        '$_localCommandResolverPath must reuse reducer.mapData without '
            'building another indexed view',
      ]),
    );
  });

  test('local reducer map-view guard rejects a new construction root', () {
    final sources = _localReducerGuardFixture();
    sources['lib/feature/raw_reducer_factory.dart'] = '''
void create(session) {
  GameStateReducer(mapData: session.mapData.indexedReadView());
}
''';

    expect(
      _localReducerMapViewViolationsFor(sources),
      contains(
        'lib/feature/raw_reducer_factory.dart must not construct '
        'GameStateReducer outside the indexed local composition roots',
      ),
    );
  });

  test('local reducer map-view guard rejects a raw AI map root', () {
    final sources = _localReducerGuardFixture();
    sources[_aiTurnProcessPreparerPath] = '''
void prepare(currentSession) {
  RunAiTurnUseCase(mapData: currentSession.mapData);
}
''';

    expect(
      _localReducerMapViewViolationsFor(sources),
      containsAll([
        '$_aiTurnProcessPreparerPath must pass an approved indexed '
            'MapReadView to RunAiTurnUseCase.mapData; found '
            'currentSession.mapData',
        '$_aiTurnProcessPreparerPath must call indexedReadView exactly 1 '
            'time(s); found 0',
      ]),
    );
  });

  test('local reducer map-view guard rejects a new AI construction root', () {
    final sources = _localReducerGuardFixture();
    sources['lib/feature/raw_ai_factory.dart'] = '''
void create(mapView) {
  RunAiTurnUseCase(mapData: mapView);
}
''';

    expect(
      _localReducerMapViewViolationsFor(sources),
      contains(
        'lib/feature/raw_ai_factory.dart must not construct RunAiTurnUseCase '
        'outside the indexed AI composition roots',
      ),
    );
  });
}

Map<String, String> _localReducerGuardFixture() => {
  _gameStateProviderPath: '''
void build(session) {
  final reducer = GameStateReducer(
    mapData: session.mapData.indexedReadView(),
  );
}
''',
  _replayProvidersPath: '''
void replay(session) {
  final reducer = GameStateReducer(
    mapData: session.mapData.indexedReadView(),
  );
}
''',
  _localCommandResolverPath: '''
void finalize(reducer) {
  CanonicalTurnPipelineRequest.simultaneousFinalize(
    mapView: reducer.mapData,
  );
}
''',
  _saveAiBenchmarkPath: '''
void prepare(mapData) {
  final mapView = mapData.indexedReadView();
}
void execute(context) {
  BenchmarkCommandDispatcher(mapView: context.mapData);
}
''',
  _multiTurnReplayPath: '''
void replay(context) {
  BenchmarkCommandDispatcher(mapView: context.mapData);
}
''',
  _benchmarkSyntheticHelpersPath: '''
void reduce(prepared) {
  BenchmarkCommandDispatcher(mapView: prepared.context.mapData);
}
void compare(prepared) {
  BenchmarkCommandDispatcher(mapView: prepared.context.mapData);
}
''',
  _runtimeSmokePath: '''
void create(mapView) {
  RunAiTurnUseCase(mapData: mapView);
}
''',
  _syntheticSuitePath: '''
void run(firstMap, secondMap) {
  final firstView = firstMap.indexedReadView();
  final secondView = secondMap.indexedReadView();
}
''',
  _replayWorkloadPath: '''
void measure() {
  final mapView = map().indexedReadView();
  GameStateReducer(mapData: mapView);
}
''',
  _aiTurnProcessPreparerPath: '''
void prepare(currentSession) {
  RunAiTurnUseCase(
    mapData: currentSession.mapData.indexedReadView(),
  );
}
''',
  _aiTurnPreparationBuilderPath: '''
void prepare(mapView) {}
''',
  _runAiTurnUseCasePath: '''
void execute(mapView) {}
''',
};
