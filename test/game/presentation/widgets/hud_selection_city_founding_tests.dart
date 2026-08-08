part of 'hud_selection_actions_test.dart';

void _registerHudSelectionCityFoundingTests() {
  test('highlights settler city founding when it can start', () {
    final settler = _settler();

    final actions = _actions(
      gameState: GameClientState(
        units: [settler],
        interaction: InteractionState(selection: GameSelection.unit(settler)),
      ),
      canStartCityFounding: true,
    );

    final foundCity = _action(actions, 'Found city');

    expect(foundCity?.enabled, isTrue);
    expect(foundCity?.color, GameUiTheme.success);
    expect(foundCity?.pulseBorder, isTrue);
  });

  test('keeps settler city founding action disabled when it cannot start', () {
    final settler = _settler();

    final actions = _actions(
      gameState: GameClientState(
        units: [settler],
        interaction: InteractionState(selection: GameSelection.unit(settler)),
      ),
    );

    expect(_actionLabels(actions), ['Move', 'Found city', 'Skip', 'Fortify']);
    expect(_action(actions, 'Found city')?.enabled, isFalse);
    expect(_action(actions, 'Found city')?.disabledReason, isNotNull);
  });

  test('uses the selected map tile to explain invalid city founding', () {
    final settler = _settler();
    final mountain = WorldTile(
      col: 0,
      row: 0,
      terrains: [TerrainType.mountain],
      resources: [],
      height: 1,
    );

    final actions = _actions(
      gameState: GameClientState(
        units: [settler],
        interaction: InteractionState(
          selection: GameSelection.unit(settler, tile: mountain),
        ),
      ),
    );

    expect(
      _action(actions, 'Found city')?.disabledReason,
      AppLocalizationsEn().selectionActionFoundCityInvalidCenter,
    );
  });

  test('shows disabled city founding progress next to cancel before ready', () {
    final settler = _settler();
    var started = false;
    var cancelled = false;

    final actions = _actions(
      gameState: GameClientState(
        units: [settler],
        interaction: InteractionState(selection: GameSelection.unit(settler)),
      ),
      cityFoundingActive: true,
      onStartCityFounding: () => started = true,
      onCancelCityFounding: () => cancelled = true,
    );

    final confirm = _action(actions, 'Found city (0/2)');
    final cancel = _action(actions, 'Cancel');

    expect(_actionLabels(actions), ['Found city (0/2)', 'Cancel']);
    expect(confirm?.enabled, isFalse);
    expect(confirm?.showLabel, isTrue);
    expect(cancel?.enabled, isTrue);
    expect(cancel?.active, isTrue);
    expect(cancel?.showLabel, isTrue);
    expect(cancel?.dangerOutlined, isTrue);

    cancel?.onTap?.call();

    expect(started, isFalse);
    expect(cancelled, isTrue);
  });

  test('shows found city next to cancel when city founding is ready', () {
    final settler = _settler();
    var confirmed = false;
    var cancelled = false;

    final actions = _actions(
      gameState:
          GameClientState(
            units: [settler],
            interaction: InteractionState(
              selection: GameSelection.unit(settler),
            ),
          ).copyWithInteraction(
            cityFoundingDraft: CityFoundingDraft(
              unitId: settler.id,
              ownerPlayerId: settler.ownerPlayerId,
              center: const CityHex(col: 0, row: 0),
              controlledHexes: const [
                CityHex(col: 1, row: 0),
                CityHex(col: 0, row: 1),
              ],
            ),
          ),
      cityFoundingActive: true,
      onConfirmCityFounding: () => confirmed = true,
      onCancelCityFounding: () => cancelled = true,
    );

    expect(_actionLabels(actions), ['Found city (2/2)', 'Cancel']);
    expect(_action(actions, 'Found city (2/2)')?.enabled, isTrue);
    expect(_action(actions, 'Found city (2/2)')?.showLabel, isTrue);
    expect(_action(actions, 'Cancel')?.enabled, isTrue);
    expect(_action(actions, 'Cancel')?.showLabel, isTrue);
    expect(_action(actions, 'Cancel')?.dangerOutlined, isTrue);
    expect(
      _action(actions, 'Found city (2/2)')?.mainExtent,
      SelectionCommandChip.expandedLabeledExtent,
    );
    expect(
      _action(actions, 'Cancel')?.mainExtent,
      SelectionCommandChip.labeledExtent,
    );

    _action(actions, 'Found city (2/2)')?.onTap?.call();
    _action(actions, 'Cancel')?.onTap?.call();

    expect(confirmed, isTrue);
    expect(cancelled, isTrue);
  });
}
