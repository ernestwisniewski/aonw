import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/resource.dart';

abstract final class MctsStrategicResourceScores {
  static double stateScore(SimulatedState state) {
    final view = state.view;
    if (view.strategicResourceEconomy !=
        StrategicResourceEconomyProfile.stockpileV1) {
      return 0;
    }
    final production = StrategicResourceProductionRules.forPlayer(
      playerId: view.forPlayerId,
      cities: view.ownCities,
      fieldImprovements: view.ownImprovements,
      mapTiles: view.mapData,
      research: view.research,
    );
    final stored = ResourceCatalog.stockpiledResources.fold<int>(
      0,
      (sum, resource) => sum + view.ownStrategicResources.amountFor(resource),
    );
    final domestic = ResourceCatalog.stockpiledResources.fold<int>(
      0,
      (sum, resource) => sum + production.output.amountFor(resource),
    );
    var imports = 0;
    var exports = 0;
    for (final agreement in view.resourceTradeAgreements) {
      if (!agreement.isActive ||
          !ResourceCatalog.isStockpiled(agreement.resource)) {
        continue;
      }
      if (agreement.importerPlayerId == view.forPlayerId) {
        imports += agreement.amountPerTurn;
      }
      if (agreement.exporterPlayerId == view.forPlayerId) {
        exports += agreement.amountPerTurn;
      }
    }
    final positiveFlow = (domestic + imports - exports).clamp(0, 2);
    final stockScore = (stored / 4).clamp(0.0, 1.0);
    final flowScore = (positiveFlow / 2).clamp(0.0, 1.0);
    return stockScore * 0.65 + flowScore * 0.35;
  }
}
