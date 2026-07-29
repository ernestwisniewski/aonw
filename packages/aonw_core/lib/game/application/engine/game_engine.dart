import 'package:aonw_core/game/application/engine/game_engine_context.dart';
import 'package:aonw_core/game/application/engine/game_engine_result.dart';
import 'package:aonw_core/game/domain/command/game_command.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';

/// Deterministic dispatcher for authoritative player commands.
///
/// Command families are registered incrementally during the engine migration.
final class GameEngine {
  const GameEngine();

  GameEngineResult apply({
    required CanonicalGameSnapshot snapshot,
    required DomainCommand command,
    required GameEngineContext context,
  }) {
    return GameEngineResult.rejected(
      snapshot: snapshot,
      reason: 'unsupported_domain_command',
    );
  }
}
