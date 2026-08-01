import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';

class CommandTransportResult {
  final GameState state;
  final List<UiEffect> uiEffects;
  final List<GameEvent> events;
  final List<CombatAnimationFact> combatAnimations;
  final List<MovementCommandExecution> movementExecutions;

  /// Snapshot produced or observed by this dispatch, when one exists.
  ///
  /// Network commands handled only on the client or managed entirely by the
  /// server do not fabricate a persistence snapshot.
  final SaveSnapshot? snapshot;
  final int offset;
  final bool storedSnapshot;

  const CommandTransportResult({
    required this.state,
    required this.snapshot,
    required this.offset,
    this.uiEffects = const [],
    this.events = const [],
    this.combatAnimations = const [],
    this.movementExecutions = const [],
    this.storedSnapshot = false,
  }) : assert(!storedSnapshot || snapshot != null);
}

abstract interface class CommandTransport {
  Future<CommandTransportResult> dispatch({
    required String saveId,
    required GameState currentState,
    required DomainCommand command,
    GameCommandContext context = const GameCommandContext(),
    bool fromMovePreviewConfirmation = false,
  });
}
