import 'package:flutter_test/flutter_test.dart';

import 'support/immutable_snapshot_constructor_guard.dart';

const _snapshotTypes = {'GameCity', 'GameRuntimeState'};

void main() {
  test('runtime production state uses immutable snapshot constructors', () {
    expect(scanRuntimeLegacyConstructors(_snapshotTypes), isEmpty);
  });

  test('guard distinguishes runtime and constant construction', () {
    final violations = runtimeLegacyConstructorViolations(
      '''
GameCity runtimeCity() => GameCity(id: '1');
GameCity snapshotCity() => GameCity.snapshot(id: '2');
GameRuntimeState runtimeState() => GameRuntimeState();
GameRuntimeState snapshotState() => GameRuntimeState.snapshot();
const explicitCity = GameCity(id: '3');
const implicitCity = [GameCity(id: '4')];
const explicitState = GameRuntimeState();
const implicitState = [GameRuntimeState()];
''',
      'fixture.dart',
      _snapshotTypes,
    );

    expect(violations, hasLength(2));
    expect(violations.join('\n'), contains('GameCity runtime construction'));
    expect(
      violations.join('\n'),
      contains('GameRuntimeState runtime construction'),
    );
  });

  test('guard rejects direct aliases but permits containing records', () {
    final directAliases = runtimeLegacyConstructorViolations(
      '''
typedef City = GameCity;
typedef Runtime = GameRuntimeState;
''',
      'alias_fixture.dart',
      _snapshotTypes,
    );
    final containingRecords = runtimeLegacyConstructorViolations(
      '''
typedef CityResult = ({GameCity city});
typedef RuntimeResult = ({GameRuntimeState state});
''',
      'record_fixture.dart',
      _snapshotTypes,
    );

    expect(directAliases, hasLength(2));
    expect(directAliases.join('\n'), contains('GameCity type alias'));
    expect(directAliases.join('\n'), contains('GameRuntimeState type alias'));
    expect(containingRecords, isEmpty);
  });

  test('guard rejects direct new and constructor tear-offs', () {
    final violations = runtimeLegacyConstructorViolations(
      '''
GameCity runtimeCity() => GameCity.new(id: '1');
GameRuntimeState runtimeState() => GameRuntimeState.new();
final createCity = GameCity.new;
final createState = GameRuntimeState.new;
''',
      'tear_off_fixture.dart',
      _snapshotTypes,
    );

    expect(violations, isNotEmpty);
    expect(violations.join('\n'), contains('GameCity legacy constructor'));
    expect(
      violations.join('\n'),
      contains('GameRuntimeState legacy constructor'),
    );
  });
}
