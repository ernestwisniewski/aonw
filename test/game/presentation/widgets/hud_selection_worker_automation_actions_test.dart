import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/selection/hud_selection_actions.dart';
import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts automatic worker activity from the worker action group', () {
    final worker = _worker();
    var started = false;
    final actions = _actions(worker, onAutomateWorker: () => started = true);

    final autoWork = _action(actions, 'Auto work');
    expect(autoWork?.actionId, 'autoWork');
    expect(autoWork?.icon, gameAutoWorkIcon);
    expect(autoWork?.enabled, isTrue);
    autoWork?.onTap?.call();
    expect(started, isTrue);
  });

  test('automatic worker travel shows one dedicated cancel action', () {
    final worker = _worker().copyWithPosture(UnitPosture.autoWorking);
    var cancelled = false;
    final actions = _actions(
      worker,
      onCancelUnitAction: () => cancelled = true,
    );

    expect(_labels(actions), ['Cancel auto work']);
    _action(actions, 'Cancel auto work')?.onTap?.call();
    expect(cancelled, isTrue);
  });

  test('assigned worker shows one dedicated end-work action', () {
    final worker = _worker().copyWithWorkerAssignment(
      const WorkerAssignment(targetHex: CityHex(col: 0, row: 0)),
    );
    var cancelled = false;
    final actions = _actions(
      worker,
      onCancelAssignment: () => cancelled = true,
    );

    expect(_labels(actions), ['End work']);
    _action(actions, 'End work')?.onTap?.call();
    expect(cancelled, isTrue);
  });
}

List<Widget> _actions(
  GameUnit worker, {
  VoidCallback? onAutomateWorker,
  VoidCallback? onCancelUnitAction,
  VoidCallback? onCancelAssignment,
}) {
  return buildHudSelectionActionChips(
    gameState: GameClientState(
      units: [worker],
      interaction: InteractionState(selection: GameSelection.unit(worker)),
    ),
    mapData: _mapData,
    activePlayerId: worker.ownerPlayerId,
    actionsLocked: false,
    moveModeActive: false,
    armyDetailActive: false,
    workerAction: null,
    cityBuildingsModeActive: false,
    cityDescriptionActive: false,
    cityBuildingsDetailActive: false,
    l10n: AppLocalizationsEn(),
    cityRuleset: CityRulesets.standard,
    technologyRuleset: TechnologyRulesets.standard,
    canStartCityFounding: false,
    cityFoundingActive: false,
    onMoveSelectedUnit: _noop,
    onAutoExploreSelectedUnit: _noop,
    onAutomateSelectedWorker: onAutomateWorker ?? _noop,
    onStartAttackTargeting: _noop,
    onCancelAttackTargeting: _noop,
    onShowArmy: _noop,
    onStartWorkerActionSelection: _noop,
    onCancelWorkerActionSelection: _noop,
    onCancelWorkerJob: _noop,
    onCancelWorkerAssignment: onCancelAssignment ?? _noop,
    onStartMerchantTradeRouteSelection: _noop,
    onCancelMerchantTradeRouteSelection: _noop,
    onAssignMerchantTradeRoute: _ignore,
    onStartMerchantMoveToCitySelection: _noop,
    onCancelMerchantMoveToCitySelection: _noop,
    onMoveMerchantToCity: _ignore,
    onStartArtifactExcavation: _noop,
    onStoreArtifactInCity: _noop,
    onStartCityFounding: _noop,
    onConfirmCityFounding: _noop,
    onCancelCityFounding: _noop,
    onSkipSelectedUnitTurn: _noop,
    onFortifySelectedUnit: _noop,
    onCancelSelectedUnitAction: onCancelUnitAction ?? _noop,
    onToggleCityDescription: _noop,
    onToggleCityBuildingDetails: _noop,
    onStartCityExpansionSelection: _noop,
    onCancelCityExpansionSelection: _noop,
    onToggleCityBuildings: _noop,
  );
}

SelectionCommandChip? _action(List<Widget> actions, String label) => actions
    .whereType<SelectionCommandChip>()
    .where((action) => action.label == label)
    .firstOrNull;

List<String> _labels(List<Widget> actions) => [
  for (final action in actions)
    if (action case SelectionCommandChip(:final label)) label,
];

GameUnit _worker() => GameUnit(
  id: 'worker_1',
  ownerPlayerId: 'player_1',
  type: GameUnitType.worker,
  name: GameUnitType.worker.defaultNameToken,
  col: 0,
  row: 0,
);

final _mapData = WorldMap(
  cols: 1,
  rows: 1,
  tiles: [
    WorldTile(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);

void _noop() {}

void _ignore(String _) {}
