part of 'hud_selection_actions_test.dart';

void _registerHudSelectionWorkerRoadTests() {
  test('keeps unit actions visible but disabled while locked', () {
    final worker = _worker();
    final actions = _actions(
      gameState: GameClientState(
        units: [worker],
        interaction: InteractionState(selection: GameSelection.unit(worker)),
      ),
      actionsLocked: true,
      workerAction: _workerAction(),
    );
    expect(_actionLabels(actions), contains('Auto work'));
    expect(
      actions.whereType<SelectionCommandChip>(),
      everyElement(
        isA<SelectionCommandChip>().having(
          (action) => action.enabled,
          'enabled',
          isFalse,
        ),
      ),
    );
  });

  test('builds worker unit actions', () {
    final worker = _worker();
    final actions = _actions(
      gameState: GameClientState(
        units: [worker],
        interaction: InteractionState(selection: GameSelection.unit(worker)),
      ),
      workerAction: _workerAction(),
    );
    expect(
      _actionLabels(actions),
      containsAll([
        'Move',
        'Improve',
        'Build road',
        'Auto work',
        'Skip',
        'Fortify',
      ]),
    );
    expect(_action(actions, 'Build road')?.icon, same(GameIcons.road));
  });
}
