import 'package:aonw_server/src/multiplayer/invite_code_generator.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_endpoint.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_input_validator.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:test/test.dart';

void main() {
  const validator = MultiplayerInputValidator();

  test('normalizes bounded match IDs and invite codes', () {
    expect(validator.matchId('  match-safe_1  '), 'match-safe_1');
    expect(validator.inviteCode('  abcdefghjkmnp  '), 'ABCDEFGHJKMNP');
  });

  test('rejects malformed or oversized match IDs', () {
    for (final value in [
      '',
      '../match',
      'match with spaces',
      List.filled(MultiplayerInputValidator.maxMatchIdLength + 1, 'x').join(),
    ]) {
      expect(
        () => validator.matchId(value),
        throwsA(_error('invalid_match_id')),
      );
    }
  });

  test('rejects invite codes outside the generated alphabet and length', () {
    for (final value in [
      'short',
      'ABCDEFGHIJKLM',
      'ABCDEFGHJKMN0',
      '${SecureInviteCodeGenerator.alphabet.substring(0, 12)}!',
    ]) {
      expect(
        () => validator.inviteCode(value),
        throwsA(_error('private_match_not_found')),
      );
    }
  });

  test('bounds event offsets', () {
    expect(validator.afterOffset(0), 0);
    expect(
      validator.afterOffset(MultiplayerInputValidator.maxEventOffset),
      MultiplayerInputValidator.maxEventOffset,
    );
    for (final value in [-1, MultiplayerInputValidator.maxEventOffset + 1]) {
      expect(
        () => validator.afterOffset(value),
        throwsA(_error('invalid_event_offset')),
      );
    }
  });

  test('hub validates private invites before opening a transaction', () async {
    final store = _TransactionTrackingStore();

    await expectLater(
      RealtimeMatchHub().joinPrivateMatch(
        store: store,
        userIdentifier: 'user-1',
        inviteCode: 'not-an-invite',
      ),
      throwsA(_error('private_match_not_found')),
    );
    expect(store.transactionCalled, isFalse);
  });

  test(
    'hub validates match IDs and offsets before reading the store',
    () async {
      final store = _ReadTrackingStore();
      final hub = RealtimeMatchHub();

      await expectLater(
        hub.loadMatch(
          store: store,
          userIdentifier: 'user-1',
          matchId: '../unsafe',
        ),
        throwsA(_error('invalid_match_id')),
      );
      expect(
        () => hub.listEvents(
          store: store,
          userIdentifier: 'user-1',
          matchId: 'match-safe',
          afterOffset: -1,
        ),
        throwsA(_error('invalid_event_offset')),
      );
      expect(store.findStateCalled, isFalse);
    },
  );
}

Matcher _error(String code) {
  return isA<MultiplayerException>().having(
    (error) => error.code,
    'code',
    code,
  );
}

final class _TransactionTrackingStore implements MultiplayerMatchStore {
  bool transactionCalled = false;

  @override
  Future<T> transaction<T>(
    Future<T> Function(MultiplayerMatchStore store) action,
  ) {
    transactionCalled = true;
    throw StateError('Validation must happen before a transaction.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ReadTrackingStore implements MultiplayerMatchStore {
  bool findStateCalled = false;

  @override
  Future<StoredMatchState?> findState(
    String matchId, {
    bool lock = false,
  }) async {
    findStateCalled = true;
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
