import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_command_line_view_model.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

const _player = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4);
const _player2 = Player(id: 'player_2', name: 'Bob', colorValue: 0xFFc45050);

final _save = GameSave(
  id: 'save',
  name: 'Game',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 1,
  playerStates: const {'player_1': PlayerTurnState.active},
  savedAt: DateTime.utc(2026, 4, 16),
  camera: CameraState.zero,
  players: const [_player],
);

void main() {
  final l10n = AppLocalizationsEn();

  test('builds hotseat status with selected unit label', () {
    final unit = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 1,
      row: 1,
    );

    final viewModel = HudCommandLineViewModel.create(
      gameSave: _save,
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      gameState: GameState(units: [unit], selection: GameSelection.unit(unit)),
      isUnitAnimating: false,
      readyToEndTurn: true,
      actionHintLabel: null,
      l10n: l10n,
    );

    expect(viewModel.playerName, 'Alice');
    expect(viewModel.statusLabel, 'Move');
    expect(viewModel.selectionLabel, 'Warrior');
    expect(viewModel.actionHintLabel, isNull);
    expect(viewModel.showActionHint, isFalse);
    expect(viewModel.activePlayerFinished, isFalse);
    expect(viewModel.multiplayer, isFalse);
  });

  test('shows action hint only while player can act before end turn', () {
    final viewModel = HudCommandLineViewModel.create(
      gameSave: _save,
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      gameState: const GameState(),
      isUnitAnimating: false,
      readyToEndTurn: false,
      actionHintLabel: 'Next step: Warrior',
      l10n: l10n,
    );

    final animating = HudCommandLineViewModel.create(
      gameSave: _save,
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      gameState: const GameState(),
      isUnitAnimating: true,
      readyToEndTurn: false,
      actionHintLabel: 'Next step: Warrior',
      l10n: l10n,
    );

    expect(viewModel.showActionHint, isTrue);
    expect(viewModel.actionHintLabel, 'Next step: Warrior');
    expect(animating.showActionHint, isFalse);
  });

  test('builds multiplayer waiting label after submit', () {
    final save = _save.copyWith(
      gameMode: GameMode.multiplayer,
      players: const [_player, _player2],
    );

    final viewModel = HudCommandLineViewModel.create(
      gameSave: save,
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      gameState: const GameState(
        activePlayerId: 'player_1',
        submittedPlayerIds: {'player_1'},
      ),
      isUnitAnimating: false,
      readyToEndTurn: false,
      actionHintLabel: 'Next step: Warrior',
      l10n: l10n,
    );

    expect(viewModel.waitingForLabel, 'Waiting: Bob');
    expect(viewModel.statusLabel, 'Waiting: Bob');
    expect(viewModel.activePlayerFinished, isTrue);
    expect(viewModel.showActionHint, isFalse);
    expect(viewModel.multiplayer, isTrue);
  });
}
