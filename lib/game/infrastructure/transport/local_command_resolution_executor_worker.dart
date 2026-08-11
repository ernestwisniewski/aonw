import 'dart:io';
import 'dart:isolate';

import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/application/services/local_movement_presentation_origin.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state.dart';

Future<LocalCommandResolution> executeLocalCommandResolution({
  required LocalCommandResolver resolver,
  required CanonicalGameSnapshot baseSnapshot,
  required GameClientState currentState,
  required DomainCommand command,
  required DateTime savedAt,
  required GameCommandContext context,
  required LocalMovementPresentationOrigin movementPresentationOrigin,
  required bool useBackgroundWorker,
}) {
  LocalCommandResolution resolve() => resolver.resolve(
    baseSnapshot: baseSnapshot,
    currentState: currentState,
    command: command,
    savedAt: savedAt,
    context: context,
    movementPresentationOrigin: movementPresentationOrigin,
  );

  // Widget tests advance a synthetic frame clock and must not depend on real
  // isolate startup latency. Production macOS builds still use the worker.
  if (!useBackgroundWorker || Platform.environment['FLUTTER_TEST'] == 'true') {
    return Future.value(resolve());
  }
  return Isolate.run(resolve, debugName: 'aonw-turn-resolution');
}
