import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'reducer_parity_fixture.dart';

void main() {
  test(
    'StartBuilding corpus fails closed when one reviewed path is removed',
    () {
      final repository = _copyCorpus();
      File(
        '${repository.path}/test/fixtures/reducer_parity/'
        'city-production-building-map-requirement-rejected.json',
      ).deleteSync();

      expect(
        () => ReducerParityCorpus.load(repository),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('StartBuilding fixture ids must be exactly'),
          ),
        ),
      );
    },
  );

  test('StartBuilding corpus rejects a mislabeled unavailable cause', () {
    final repository = _copyCorpus();
    final fixture = File(
      '${repository.path}/test/fixtures/reducer_parity/'
      'city-production-building-locked-rejected.json',
    );
    _unlockWorkshop(fixture, playerId: 'player_1');

    expect(
      () => ReducerParityCorpus.load(repository),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains(
            'does not isolate its reviewed building_not_available cause',
          ),
        ),
      ),
    );
  });

  test('StartBuilding corpus rejects wrong-actor availability mode drift', () {
    final repository = _copyCorpus();
    final fixture = File(
      '${repository.path}/test/fixtures/reducer_parity/'
      'city-production-building-wrong-actor-unavailable-rejected.json',
    );
    _unlockWorkshop(fixture, playerId: 'player_2');

    expect(
      () => ReducerParityCorpus.load(repository),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('reviewed city_not_controlled availability mode'),
        ),
      ),
    );
  });
}

void _unlockWorkshop(File fixture, {required String playerId}) {
  final json = jsonDecode(fixture.readAsStringSync()) as Map<String, dynamic>;
  final input = json['input'] as Map<String, dynamic>;
  final state = input['state'] as Map<String, dynamic>;
  state['research'] = {
    'players': {
      playerId: {
        'unlockedTechnologyIds': ['craftsmanship'],
        'progressByTechnologyId': <String, dynamic>{},
      },
    },
  };
  final expected = json['expected'] as Map<String, dynamic>;
  expected['state'] = jsonDecode(jsonEncode(state));
  fixture.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(json)}\n',
  );
}

Directory _copyCorpus() {
  final repository = Directory.systemTemp.createTempSync(
    'aonw-reducer-parity-guard-',
  );
  addTearDown(() => repository.deleteSync(recursive: true));
  final target = Directory('${repository.path}/test/fixtures/reducer_parity')
    ..createSync(recursive: true);
  final source = Directory('test/fixtures/reducer_parity');
  for (final entry in source.listSync()) {
    if (entry is File) {
      entry.copySync('${target.path}/${entry.uri.pathSegments.last}');
    }
  }
  return repository;
}
