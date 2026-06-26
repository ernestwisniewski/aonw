import 'package:aonw/game/presentation/providers/game/game_state_provider.dart';
import 'package:aonw/game/presentation/providers/ruleset/ruleset_providers.dart';
import 'package:aonw/game/presentation/providers/session/session_providers.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'view_model_providers.g.dart';

@Riverpod(dependencies: [GameStateNotifier, activeGameSession])
TechnologyPanelViewModel technologyPanelViewModel(
  Ref ref,
  String saveId,
  String playerId,
) {
  final gameState = ref.watch(gameStateProvider(saveId)).value;
  final cityRuleset = ref.watch(cityRulesetProvider);
  final ruleset = ref.watch(technologyRulesetProvider);
  final session = ref.watch(activeGameSessionProvider);
  final save = ref.watch(gameSaveProvider(saveId)).value;
  return TechnologyPanelViewModelFactory.create(
    state: gameState,
    playerId: playerId,
    ruleset: ruleset,
    cityRuleset: cityRuleset,
    mapData: session?.mapData,
    currentTurn: save?.turn,
    paceBalance: save?.matchRules.paceBalance ?? PaceBalance.unlimited,
  );
}
