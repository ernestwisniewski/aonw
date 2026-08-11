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
const int kSnapshotEventVersion = 4;

/// Previous durable schema accepted during the v3 -> v4 expand phase.
///
/// Revision 3 does not contain authoritative road infrastructure. Current
/// readers treat missing transport state as empty and migrate the envelope to
/// revision 4 on the next authoritative write.
const int kLegacySnapshotEventVersion = 3;

/// Durable schemas that current clients and servers can decode safely.
const Set<int> kReadableSnapshotEventVersions = {
  kLegacySnapshotEventVersion,
  kSnapshotEventVersion,
};

bool isReadableSnapshotEventVersion(int version) =>
    kReadableSnapshotEventVersions.contains(version);

/// Current functional multiplayer contract revision.
///
/// Every player-visible or server-side multiplayer contract change increments
/// this value, including compatible additive changes that do not alter the
/// serialized wire-envelope schema.
const int kCurrentMultiplayerVersion = 6;

/// Version represented by clients released before the compatibility
/// declaration was added to the app-status handshake.
const int kLegacyUndeclaredMultiplayerVersion = 1;

/// Older multiplayer revisions that the current deployment can safely serve.
///
/// Remove a revision when a change is incompatible. Clients on a removed or
/// future revision receive the translated update notice before entering
/// multiplayer.
const Set<int> kCompatibleMultiplayerVersions = {6};

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
