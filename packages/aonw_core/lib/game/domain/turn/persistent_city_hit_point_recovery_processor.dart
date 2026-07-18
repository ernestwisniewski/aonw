import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/turn/city_hit_point_recovery_processor.dart';

/// Compatibility wrapper for the persistence-neutral recovery processor.
abstract final class PersistentCityHitPointRecoveryProcessor {
  static const int hitPointsPerTurn =
      CityHitPointRecoveryProcessor.hitPointsPerTurn;

  static List<GameCity> recoverForPlayer({
    required Iterable<GameCity> cities,
    required Iterable<WorldArtifact> artifacts,
    required Iterable<GameEvent> events,
    required CombatRuleset combatRuleset,
    required String playerId,
  }) {
    return CityHitPointRecoveryProcessor.recoverForPlayer(
      cities: cities,
      artifacts: artifacts,
      events: events,
      combatRuleset: combatRuleset,
      playerId: playerId,
    );
  }
}
