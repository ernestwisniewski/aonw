import 'package:aonw_core/ai/ai_strategy.dart';
import 'package:aonw_core/ai/ai_strategy_id.dart';

class AiStrategyRegistry {
  final Map<AiStrategyId, AiStrategy> _strategies;

  AiStrategyRegistry(Map<AiStrategyId, AiStrategy> strategies)
    : _strategies = Map.unmodifiable(strategies);

  AiStrategy resolve(AiStrategyId strategyId) {
    final strategy = _strategies[strategyId];
    if (strategy == null) {
      throw StateError('Missing AI strategy for ${strategyId.name}');
    }
    return strategy;
  }

  bool contains(AiStrategyId strategyId) => _strategies.containsKey(strategyId);
}
