import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/invite_code_generator.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_endpoint.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:test/test.dart';

void main() {
  test('private match creation rejects an invalid generated code', () async {
    final inviteCodeGenerator = _InvalidInviteCodeGenerator();
    final hub = RealtimeMatchHub(inviteCodeGenerator: inviteCodeGenerator);

    await expectLater(
      hub.createMatch(
        store: const _UnusedMatchStore(),
        userIdentifier: 'owner-user',
        request: CreateMatchRequest(
          name: 'Private lobby',
          mapName: 'verdantia',
          maxPlayers: 3,
          minPlayers: 2,
          private: true,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('invalid code'),
        ),
      ),
    );
    expect(inviteCodeGenerator.calls, 1);
  });
}

final class _InvalidInviteCodeGenerator implements InviteCodeGenerator {
  var calls = 0;

  @override
  String generate() {
    calls += 1;
    return 'invalid-code';
  }
}

final class _UnusedMatchStore implements MultiplayerMatchStore {
  const _UnusedMatchStore();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('The store must stay untouched.');
}
