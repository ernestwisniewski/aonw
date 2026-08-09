import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_errors.dart';

/// Rejects clients whose functional multiplayer contract cannot be served.
///
/// A missing declaration represents a legacy client and is intentionally not
/// accepted. Keeping the check at the endpoint boundary prevents older builds
/// from mutating a lobby before the streaming connection is established.
void requireCompatibleMultiplayerClient(int? declaredVersion) {
  if (isCompatibleMultiplayerVersion(declaredVersion)) return;

  final version = declaredVersion ?? kLegacyUndeclaredMultiplayerVersion;
  throw multiplayerException(
    'unsupported_multiplayer_version',
    'Multiplayer version $version is not supported by this server.',
  );
}
