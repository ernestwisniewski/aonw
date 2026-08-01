part of 'local_command_transport_test.dart';

extension _LocalTransportClientBoundary on LocalCommandTransport {
  Future<CommandTransportResult> dispatchAcrossBoundary({
    required String saveId,
    required GameState currentState,
    required Object command,
    GameCommandContext context = const GameCommandContext(),
  }) async {
    if (command is DomainCommand) {
      return dispatch(
        saveId: saveId,
        currentState: currentState,
        command: command,
        context: context,
      );
    }
    if (command is! GameIntent) {
      throw ArgumentError.value(command, 'command');
    }
    final resolution = GameIntentResolver(
      reducer: reducer,
      context: context,
    ).resolve(currentState.interaction, command, currentState);
    final domainCommand = resolution.domainCommand;
    if (domainCommand != null) {
      return dispatch(
        saveId: saveId,
        currentState: currentState,
        command: domainCommand,
        context: context,
        fromMovePreviewConfirmation:
            command is TileTappedCommand && domainCommand is MoveUnitCommand,
      );
    }
    final nextState = resolution.interaction == currentState.interaction
        ? currentState
        : currentState.copyWith(interaction: resolution.interaction);
    return CommandTransportResult(
      state: nextState,
      uiEffects: resolution.presentationFocus,
      snapshot: null,
      offset: -1,
    );
  }
}

MapData _map({int cols = 3, int rows = 3}) => MapData(
  cols: cols,
  rows: rows,
  tiles: [
    for (var row = 0; row < rows; row++)
      for (var col = 0; col < cols; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

const _damagedCity = GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'City 1',
  center: CityHex(col: 0, row: 0),
  hitPoints: 10,
);
