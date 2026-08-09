import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';

typedef InitialGameSnapshot = ({GameSave save, CanonicalGameSnapshot snapshot});

InitialGameSnapshot createInitialGameSnapshot({
  required String id,
  required DateTime now,
  required NewGameRequest request,
  required int startPositionSeed,
}) {
  final save = _initialSave(id: id, now: now, request: request);
  final entities = _initialEntities(request, startPositionSeed);
  final domain = DomainState.snapshot(
    turn: save.turn,
    matchRules: save.matchRules,
    participants: request.players,
    units: entities.units,
    artifacts: entities.artifacts,
    fogOfWar: entities.fogOfWar,
    diplomacy: entities.diplomacy,
    gameMode: save.gameMode,
    turnStatesByPlayerId: save.playerStates,
  );
  return (save: save, snapshot: _initialSnapshot(save, domain));
}

GameSave _initialSave({
  required String id,
  required DateTime now,
  required NewGameRequest request,
}) => GameSave(
  id: id,
  name: request.name,
  mapName: request.mapName,
  mapSource: request.mapSource,
  turn: 1,
  playerStates: {
    for (final player in request.players) player.id: PlayerTurnState.active,
  },
  savedAt: now,
  camera: CameraState.zero,
  matchRules: request.matchRules,
  players: request.players,
  gameMode: request.gameMode,
  origin: GameSaveOrigin.local,
);

({
  List<GameUnit> units,
  List<WorldArtifact> artifacts,
  FogOfWarState fogOfWar,
  DiplomacyState diplomacy,
})
_initialEntities(NewGameRequest request, int startPositionSeed) {
  final units = StartingUnits.unitsForPlayers(
    request.players,
    mapData: request.mapData,
    startPositionSeed: startPositionSeed,
  );
  final artifacts = request.mapData == null
      ? const <WorldArtifact>[]
      : WorldArtifactGenerator.generate(
          mapData: request.mapData!,
          startingUnits: units,
          seed: startPositionSeed,
        );
  final fogOfWar = request.mapData == null
      ? FogOfWarState.empty
      : const FogOfWarService().recompute(
          current: FogOfWarState.empty,
          mapData: request.mapData!,
          playerIds: request.players.map((player) => player.id),
          units: units,
          cities: const [],
        );
  final diplomacy = DiplomaticContact.mergeDiscoveredContacts(
    diplomacy: DiplomacyState.empty,
    fogOfWar: fogOfWar,
    units: units,
    cities: const [],
    playerIds: request.players.map((player) => player.id),
  );
  return (
    units: units,
    artifacts: artifacts,
    fogOfWar: fogOfWar,
    diplomacy: diplomacy,
  );
}

CanonicalGameSnapshot _initialSnapshot(GameSave save, DomainState domain) {
  return CanonicalGameSnapshot.snapshot(
    domain: domain,
    metadata: GameSnapshotMetadata(
      id: save.id,
      schemaVersion: save.schemaVersion,
      name: save.name,
      world: WorldReference(name: save.mapName, source: save.mapSource),
      savedAtUtc: save.savedAt,
      origin: save.origin,
      camera: GameSnapshotCamera(
        x: save.camera.x,
        y: save.camera.y,
        zoom: save.camera.zoom,
      ),
    ),
  );
}
