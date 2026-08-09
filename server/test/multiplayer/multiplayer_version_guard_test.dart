import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_version_guard.dart';
import 'package:test/test.dart';

void main() {
  test('accepts the current functional multiplayer revision', () {
    expect(
      () => requireCompatibleMultiplayerClient(kCurrentMultiplayerVersion),
      returnsNormally,
    );
  });

  test('rejects missing, older, and future multiplayer revisions', () {
    for (final version in <int?>[
      null,
      kCurrentMultiplayerVersion - 1,
      kCurrentMultiplayerVersion + 1,
    ]) {
      expect(
        () => requireCompatibleMultiplayerClient(version),
        throwsA(
          isA<MultiplayerException>().having(
            (error) => error.code,
            'code',
            'unsupported_multiplayer_version',
          ),
        ),
        reason: 'version $version',
      );
    }
  });
}
