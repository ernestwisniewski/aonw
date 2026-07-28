import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/util/collection_equality.dart';

/// Cache fingerprint for the canonical world state observed by AI.
///
/// Turn and rules belong to separate cache-key fields. Session, interaction,
/// diplomacy, trades, and victory progress remain intentionally excluded to
/// preserve the reviewed invalidation policy.
abstract final class AiDomainStateFingerprint {
  static int hash(DomainState state, {bool includeIntendedAttacks = false}) {
    return Object.hash(
      mapHash(state.playerColors),
      mapHash(state.playerCountries),
      mapHash(state.playerGold),
      mapHash(state.playerWarWeariness),
      mapHash(state.playerStabilityNet),
      Object.hashAll(state.units),
      Object.hashAll(state.cities),
      Object.hashAll(state.artifacts),
      Object.hashAll(state.fieldImprovements),
      state.fogOfWar,
      state.research,
      state.wonderRegistry,
      Object.hashAll(includeIntendedAttacks ? state.intendedAttacks : const []),
    );
  }
}
