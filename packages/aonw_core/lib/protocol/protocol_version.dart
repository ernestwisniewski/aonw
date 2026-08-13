/// Current transient command, ACK, and match envelope schema.
///
/// Snapshot and event storage deliberately have an independent version so a
/// transient protocol rollout never forces an irreversible data migration.
/// This is also independent from [kCurrentMultiplayerVersion].
const int kProtocolVersion = 4;

/// Current durable snapshot and event envelope schema.
///
/// Keep this stable while the persisted shapes remain decodable. Bump it only
/// with an explicit expand/contract and rollback plan for stored payloads.
const int kSnapshotEventVersion = 7;

/// Previous durable schema accepted during the v6 -> v7 expand phase.
///
/// Revision 6 stores movement costs in whole points. Current readers migrate
/// those costs to deterministic half-point units.
const int kPreviousSnapshotEventVersion = 6;

/// Previous durable schema accepted during the v5 -> v6 expand phase.
///
/// Revision 5 does not persist deterministic initial resource distribution.
const int kLegacySnapshotEventVersion = 5;

/// Revision 4 does not contain strategic-resource stockpiles.
const int kOlderSnapshotEventVersion = 4;

/// Oldest durable schema retained through the current expand window.
///
/// Revision 3 also lacks authoritative road infrastructure.
const int kOldestSnapshotEventVersion = 3;

/// Durable schemas that current clients and servers can decode safely.
const Set<int> kReadableSnapshotEventVersions = {
  kOldestSnapshotEventVersion,
  kOlderSnapshotEventVersion,
  kLegacySnapshotEventVersion,
  kPreviousSnapshotEventVersion,
  kSnapshotEventVersion,
};

bool isReadableSnapshotEventVersion(int version) =>
    kReadableSnapshotEventVersions.contains(version);

/// Current functional multiplayer contract revision.
///
/// Every player-visible or server-side multiplayer contract change increments
/// this value, including compatible additive changes that do not alter the
/// serialized wire-envelope schema.
const int kCurrentMultiplayerVersion = 9;

/// Version represented by clients released before the compatibility
/// declaration was added to the app-status handshake.
const int kLegacyUndeclaredMultiplayerVersion = 1;

/// Older multiplayer revisions that the current deployment can safely serve.
///
/// Remove a revision when a change is incompatible. Clients on a removed or
/// future revision receive the translated update notice before entering
/// multiplayer.
const Set<int> kCompatibleMultiplayerVersions = {9};

enum MultiplayerVersionCompatibility {
  current,
  backwardCompatible,
  unsupported,
}

MultiplayerVersionCompatibility multiplayerVersionCompatibility(
  int? declaredVersion,
) {
  final version = declaredVersion ?? kLegacyUndeclaredMultiplayerVersion;
  if (version == kCurrentMultiplayerVersion) {
    return MultiplayerVersionCompatibility.current;
  }
  if (kCompatibleMultiplayerVersions.contains(version)) {
    return MultiplayerVersionCompatibility.backwardCompatible;
  }
  return MultiplayerVersionCompatibility.unsupported;
}

bool isCompatibleMultiplayerVersion(int? declaredVersion) =>
    multiplayerVersionCompatibility(declaredVersion) !=
    MultiplayerVersionCompatibility.unsupported;
