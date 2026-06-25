import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/id_generator.dart';
import 'package:aonw/game/application/ports/replay_store.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/infrastructure/persistence/json_event_log.dart';
import 'package:aonw/game/infrastructure/persistence/json_game_repository.dart';
import 'package:aonw/game/infrastructure/persistence/json_replay_store.dart';
import 'package:aonw/game/infrastructure/persistence/json_snapshot_store.dart';

GameRepository createPlatformGameRepository({
  required Clock clock,
  required IdGenerator idGenerator,
}) {
  return JsonGameRepository(clock: clock, idGenerator: idGenerator);
}

EventLog createPlatformEventLog() {
  return const JsonEventLog();
}

SnapshotStore createPlatformSnapshotStore({required Clock clock}) {
  return JsonSnapshotStore(clock: clock);
}

ReplayStore createPlatformReplayStore() {
  return const JsonReplayStore();
}
