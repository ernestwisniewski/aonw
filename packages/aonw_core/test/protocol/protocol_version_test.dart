import 'package:aonw_core/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('reviewed multiplayer compatibility inventory is explicit', () {
    expect(kProtocolVersion, 4);
    expect(kSnapshotEventVersion, 3);
    expect(kCurrentMultiplayerVersion, 5);
    expect(kLegacyUndeclaredMultiplayerVersion, 1);
    expect(kCompatibleMultiplayerVersions, {5});
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
    for (final version in const [-1, 0, 1, 2, 3, 4, 6]) {
      expect(
        multiplayerVersionCompatibility(version),
        MultiplayerVersionCompatibility.unsupported,
        reason: 'version $version',
      );
      expect(isCompatibleMultiplayerVersion(version), isFalse);
    }
  });
}
