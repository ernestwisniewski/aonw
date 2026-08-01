import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/use_cases/autosave_camera_use_case.dart';
import 'package:aonw/game/application/use_cases/detach_troop_use_case.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGameRepository implements GameRepository {
  CameraState? savedCamera;

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) => mapDisplayName;

  @override
  Future<String> create(NewGameRequest request) async => 'save';

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<List<GameSaveIndex>> list() async => const [];

  @override
  Future<CanonicalGameSnapshot> load(String saveId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> save(CanonicalGameSnapshot snapshot) async {}

  @override
  Future<CanonicalGameSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    savedCamera = camera;
    return GameSnapshotFactory.create(save: _save.copyWith(camera: camera));
  }
}

final _save = GameSave(
  id: 'save_1',
  name: 'Game',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 1,
  playerStates: const {},
  savedAt: DateTime.utc(2026, 4, 16),
  camera: CameraState.zero,
);

void main() {
  test('AutosaveCameraUseCase persists a non-empty save id', () async {
    final repository = _FakeGameRepository();
    const camera = CameraState(x: 1, y: 2, zoom: 3);

    final saved = await AutosaveCameraUseCase(
      repository: repository,
    ).execute(saveId: 'save_1', camera: camera);

    expect(saved, isTrue);
    expect(repository.savedCamera, camera);
  });

  test('DetachTroopUseCase dispatches detach for the selected unit', () async {
    final commands = <DomainCommand>[];
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final state = GameClientState(
      interaction: InteractionState(selection: GameSelection.unit(commander)),
    );

    final dispatched = await const DetachTroopUseCase().execute(
      state: state,
      troopType: TroopType.warrior,
      dispatch: (command) async {
        commands.add(command);
        return const [];
      },
    );

    expect(dispatched, isTrue);
    expect(
      commands.single,
      isA<DetachTroopCommand>()
          .having((command) => command.unitId, 'unitId', commander.id)
          .having(
            (command) => command.troopType,
            'troopType',
            TroopType.warrior,
          ),
    );
  });
}
