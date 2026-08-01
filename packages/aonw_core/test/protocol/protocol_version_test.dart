import 'package:aonw_core/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('reviewed multiplayer compatibility inventory is explicit', () {
    expect(kCurrentMultiplayerVersion, 2);
    expect(kLegacyUndeclaredMultiplayerVersion, 1);
    expect(kCompatibleMultiplayerVersions, {1, 2});
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

  test('legacy undeclared clients use the reviewed compatible revision', () {
    expect(
      multiplayerVersionCompatibility(null),
      MultiplayerVersionCompatibility.backwardCompatible,
    );
    expect(
      multiplayerVersionCompatibility(kLegacyUndeclaredMultiplayerVersion),
      MultiplayerVersionCompatibility.backwardCompatible,
    );
  });

  test('removed, malformed-equivalent, and future revisions fail closed', () {
    for (final version in const [-1, 0, 3]) {
      expect(
        multiplayerVersionCompatibility(version),
        MultiplayerVersionCompatibility.unsupported,
        reason: 'version $version',
      );
      expect(isCompatibleMultiplayerVersion(version), isFalse);
    }
  });
}
