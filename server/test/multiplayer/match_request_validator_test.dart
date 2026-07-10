import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/match_request_validator.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_endpoint.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:test/test.dart';

void main() {
  const validator = MatchRequestValidator();

  test('normalizes user-controlled labels', () {
    final validated = validator.validate(
      _request(name: '  Friendly lobby  ', mapName: '  MYRANTH  '),
    );

    expect(validated.name, 'Friendly lobby');
    expect(validated.mapName, 'myranth');
  });

  test('rejects empty, oversized, and control-character match names', () {
    for (final name in [
      '   ',
      _repeated('x', MatchRequestValidator.maxNameLength + 1),
      'Lobby\nforged',
    ]) {
      expect(
        () => validator.validate(_request(name: name)),
        throwsA(_error('invalid_match_name')),
      );
    }
  });

  test('rejects unsafe and oversized map names', () {
    for (final mapName in [
      '../verdantia',
      'map/name',
      'map name',
      _repeated('x', MatchRequestValidator.maxMapNameLength + 1),
    ]) {
      expect(
        () => validator.validate(_request(mapName: mapName)),
        throwsA(_error('invalid_map_name')),
      );
    }
  });

  test('rejects player counts outside global bounds', () {
    for (final request in [
      _request(minPlayers: 1),
      _request(maxPlayers: 5),
      _request(minPlayers: 4, maxPlayers: 3),
    ]) {
      expect(
        () => validator.validate(request),
        throwsA(_error('invalid_player_count')),
      );
    }
  });

  test('enforces the capacity of official maps', () {
    expect(
      () => validator.validate(_request(mapName: 'myranth', maxPlayers: 4)),
      throwsA(_error('invalid_player_count')),
    );
  });

  test('allows quickplay to expand onto a larger start map', () {
    final validated = validator.validate(
      _request(mapName: 'terenos', maxPlayers: 4),
      enforceMapCapacity: false,
    );

    expect(validated.maxPlayers, 4);
  });

  test('hub rejects an invalid request before opening a transaction', () async {
    final store = _TransactionTrackingStore();

    await expectLater(
      RealtimeMatchHub().createMatch(
        store: store,
        userIdentifier: 'owner-user',
        request: _request(maxPlayers: 5),
      ),
      throwsA(_error('invalid_player_count')),
    );
    expect(store.transactionCalled, isFalse);
  });
}

CreateMatchRequest _request({
  String name = 'Test match',
  String mapName = 'test_map',
  int maxPlayers = 3,
  int minPlayers = 2,
}) {
  return CreateMatchRequest(
    name: name,
    mapName: mapName,
    maxPlayers: maxPlayers,
    minPlayers: minPlayers,
    private: false,
  );
}

Matcher _error(String code) {
  return isA<MultiplayerException>().having(
    (error) => error.code,
    'code',
    code,
  );
}

String _repeated(String value, int count) => List.filled(count, value).join();

final class _TransactionTrackingStore implements MultiplayerMatchStore {
  bool transactionCalled = false;

  @override
  Future<T> transaction<T>(
    Future<T> Function(MultiplayerMatchStore store) action,
  ) {
    transactionCalled = true;
    throw StateError('Validation must run before a transaction is opened.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
