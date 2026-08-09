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
const int kSnapshotEventVersion = 3;

/// Current functional multiplayer contract revision.
///
/// Every player-visible or server-side multiplayer contract change increments
/// this value, including compatible additive changes that do not alter the
/// serialized wire-envelope schema.
const int kCurrentMultiplayerVersion = 5;

/// Version represented by clients released before the compatibility
/// declaration was added to the app-status handshake.
const int kLegacyUndeclaredMultiplayerVersion = 1;

/// Older multiplayer revisions that the current deployment can safely serve.
///
/// Remove a revision when a change is incompatible. Clients on a removed or
/// future revision receive the translated update notice before entering
/// multiplayer.
const Set<int> kCompatibleMultiplayerVersions = {5};

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
