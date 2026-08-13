import 'package:aonw_core/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('reviewed multiplayer compatibility inventory is explicit', () {
    expect(kProtocolVersion, 4);
    expect(kSnapshotEventVersion, 6);
    expect(kPreviousSnapshotEventVersion, 5);
    expect(kLegacySnapshotEventVersion, 4);
    expect(kOldestSnapshotEventVersion, 3);
    expect(kReadableSnapshotEventVersions, {3, 4, 5, 6});
    expect(kCurrentMultiplayerVersion, 8);
    expect(kLegacyUndeclaredMultiplayerVersion, 1);
    expect(kCompatibleMultiplayerVersions, {8});
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
    for (final version in const [-1, 0, 1, 2, 3, 4, 5, 6, 7, 9]) {
      expect(
        multiplayerVersionCompatibility(version),
        MultiplayerVersionCompatibility.unsupported,
        reason: 'version $version',
      );
      expect(isCompatibleMultiplayerVersion(version), isFalse);
    }
  });

  test('durable readers accept only the reviewed v3 to v6 expand window', () {
    expect(isReadableSnapshotEventVersion(3), isTrue);
    expect(isReadableSnapshotEventVersion(4), isTrue);
    expect(isReadableSnapshotEventVersion(2), isFalse);
    expect(isReadableSnapshotEventVersion(5), isTrue);
    expect(isReadableSnapshotEventVersion(6), isTrue);
    expect(isReadableSnapshotEventVersion(7), isFalse);
  });
}
