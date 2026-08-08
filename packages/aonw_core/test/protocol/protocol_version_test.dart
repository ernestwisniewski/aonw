import 'package:aonw_core/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('reviewed multiplayer compatibility inventory is explicit', () {
    expect(kCurrentMultiplayerVersion, 3);
    expect(kLegacyUndeclaredMultiplayerVersion, 1);
    expect(kCompatibleMultiplayerVersions, {3});
  });

  test('current multiplayer version is explicitly compatible', () {
    expect(
      multiplayerVersionCompatibility(kCurrentMultiplayerVersion),
      MultiplayerVersionCompatibility.current,
    );
    expect(
      kCompatibleMultiplayerVersions,
      contains(kCurrentMultiplayerVersion),
    );
  });

  test('legacy undeclared clients are no longer compatible', () {
    expect(
      multiplayerVersionCompatibility(null),
      MultiplayerVersionCompatibility.unsupported,
    );
    expect(
      multiplayerVersionCompatibility(kLegacyUndeclaredMultiplayerVersion),
      MultiplayerVersionCompatibility.unsupported,
    );
  });

  test('removed, malformed-equivalent, and future revisions fail closed', () {
    for (final version in const [-1, 0, 1, 2, 4]) {
      expect(
        multiplayerVersionCompatibility(version),
        MultiplayerVersionCompatibility.unsupported,
        reason: 'version $version',
      );
      expect(isCompatibleMultiplayerVersion(version), isFalse);
    }
  });
}
