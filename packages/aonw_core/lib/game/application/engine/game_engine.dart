import 'package:aonw_core/game/application/engine/artifact_trade_engine_handler.dart';
import 'package:aonw_core/game/application/engine/city_engine_handler.dart';
import 'package:aonw_core/game/application/engine/combat_engine_handler.dart';
import 'package:aonw_core/game/application/engine/game_engine_context.dart';
import 'package:aonw_core/game/application/engine/game_engine_result.dart';
import 'package:aonw_core/game/application/engine/movement_engine_handler.dart';
import 'package:aonw_core/game/application/engine/production_engine_handler.dart';
import 'package:aonw_core/game/application/engine/unit_action_engine_handler.dart';
import 'package:aonw_core/game/application/engine/worker_engine_handler.dart';
import 'package:aonw_core/game/domain/command/game_command.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';

enum GameEngineCommandFamily {
  unitAction,
  movement,
  combat,
  city,
  production,
  worker,
  artifactTrade,
}

/// Deterministic dispatcher for authoritative player commands.
///
/// Command families are registered incrementally during the engine migration.
final class GameEngine {
  const GameEngine();

  static GameEngineCommandFamily? commandFamily(DomainCommand command) {
    return _unitActionFamily(command) ??
        _movementFamily(command) ??
        _combatFamily(command) ??
        _cityFamily(command) ??
        _productionFamily(command) ??
        _workerFamily(command) ??
        _artifactTradeFamily(command);
  }

  static GameEngineCommandFamily? _unitActionFamily(DomainCommand command) {
    return switch (command) {
      SkipUnitTurnCommand() ||
      FortifyUnitCommand() => GameEngineCommandFamily.unitAction,
      _ => null,
    };
  }

  static GameEngineCommandFamily? _movementFamily(DomainCommand command) {
    return switch (command) {
      MoveUnitCommand() ||
      CancelUnitActionCommand() ||
      AutoExploreUnitCommand() ||
      AssignMerchantTradeRouteCommand() ||
      MoveMerchantToCityCommand() ||
      DetachTroopCommand() => GameEngineCommandFamily.movement,
      _ => null,
    };
  }

  static GameEngineCommandFamily? _combatFamily(DomainCommand command) {
    return switch (command) {
      AttackHexCommand() => GameEngineCommandFamily.combat,
      _ => null,
    };
  }

  static GameEngineCommandFamily? _cityFamily(DomainCommand command) {
    return switch (command) {
      FoundCityCommand() ||
      ToggleWorkedHexCommand() ||
      SelectCityExpansionHexCommand() => GameEngineCommandFamily.city,
      _ => null,
    };
  }

  static GameEngineCommandFamily? _productionFamily(DomainCommand command) {
    return switch (command) {
      StartBuildingCommand() ||
      StartUnitProductionCommand() ||
      StartCityProjectCommand() ||
      StartWonderCommand() ||
      SetCitySpecializationCommand() ||
      RushProductionCommand() => GameEngineCommandFamily.production,
      _ => null,
    };
  }

  static GameEngineCommandFamily? _workerFamily(DomainCommand command) {
    return switch (command) {
      SelectWorkerImprovementCommand() ||
      ConfirmWorkerImprovementCommand() ||
      CancelWorkerJobCommand() ||
      AssignWorkerToHexCommand() ||
      CancelWorkerAssignmentCommand() => GameEngineCommandFamily.worker,
      _ => null,
    };
  }

  static GameEngineCommandFamily? _artifactTradeFamily(DomainCommand command) {
    return switch (command) {
      StartArtifactExcavationCommand() ||
      StoreArtifactInCityCommand() ||
      TradeArtifactCommand() ||
      OpenResourceTradeCommand() ||
      OpenResourceExchangeCommand() => GameEngineCommandFamily.artifactTrade,
      _ => null,
    };
  }

  GameEngineResult apply({
    required CanonicalGameSnapshot snapshot,
    required DomainCommand command,
    required GameEngineContext context,
  }) {
    return switch (commandFamily(command)) {
      GameEngineCommandFamily.unitAction =>
        const UnitActionEngineHandler().apply(
          snapshot: snapshot,
          command: command,
          context: context,
        ),
      GameEngineCommandFamily.movement => const MovementEngineHandler().apply(
        snapshot: snapshot,
        command: command,
        context: context,
      ),
      GameEngineCommandFamily.combat => const CombatEngineHandler().apply(
        snapshot: snapshot,
        command: command,
        context: context,
      ),
      GameEngineCommandFamily.city => const CityEngineHandler().apply(
        snapshot: snapshot,
        command: command,
        context: context,
      ),
      GameEngineCommandFamily.production =>
        const ProductionEngineHandler().apply(
          snapshot: snapshot,
          command: command,
          context: context,
        ),
      GameEngineCommandFamily.worker => const WorkerEngineHandler().apply(
        snapshot: snapshot,
        command: command,
        context: context,
      ),
      GameEngineCommandFamily.artifactTrade =>
        const ArtifactTradeEngineHandler().apply(
          snapshot: snapshot,
          command: command,
          context: context,
        ),
      null => GameEngineResult.rejected(
        snapshot: snapshot,
        reason: 'unsupported_domain_command',
      ),
    };
  }
}
