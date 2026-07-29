import 'package:aonw_core/game/application/engine/game_engine_context.dart';
import 'package:aonw_core/game/application/engine/game_engine_result.dart';
import 'package:aonw_core/game/domain/city/domain_city_production_resolver.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/state.dart';

/// Applies authoritative city production, project, wonder and rush commands.
final class ProductionEngineHandler {
  const ProductionEngineHandler({
    this.resolver = const DomainCityProductionResolver(),
  });

  final DomainCityProductionResolver resolver;

  GameEngineResult apply({
    required CanonicalGameSnapshot snapshot,
    required DomainCommand command,
    required GameEngineContext context,
  }) {
    if (command is StartBuildingCommand) {
      return _startBuilding(snapshot, command, context);
    }
    if (command is StartUnitProductionCommand) {
      return _startUnit(snapshot, command, context);
    }
    if (command is StartCityProjectCommand) {
      return _startProject(snapshot, command, context);
    }
    if (command is StartWonderCommand) {
      return _startWonder(snapshot, command, context);
    }
    if (command is SetCitySpecializationCommand) {
      return _setSpecialization(snapshot, command, context);
    }
    if (command is RushProductionCommand) {
      return _rush(snapshot, command, context);
    }
    return GameEngineResult.rejected(
      snapshot: snapshot,
      reason: 'unsupported_domain_command',
    );
  }

  GameEngineResult _startBuilding(
    CanonicalGameSnapshot snapshot,
    StartBuildingCommand command,
    GameEngineContext context,
  ) => _result(
    snapshot,
    resolver.startBuilding(
      state: snapshot.domain,
      command: command,
      actorPlayerId: context.actorPlayerId,
      mapTiles: context.mapView,
      cityRuleset: context.ruleset.city,
      technologyRuleset: context.ruleset.technology,
      paceBalance: context.ruleset.paceBalance,
    ),
  );

  GameEngineResult _startUnit(
    CanonicalGameSnapshot snapshot,
    StartUnitProductionCommand command,
    GameEngineContext context,
  ) => _result(
    snapshot,
    resolver.startUnitProduction(
      state: snapshot.domain,
      command: command,
      actorPlayerId: context.actorPlayerId,
      mapView: context.mapView,
      cityRuleset: context.ruleset.city,
      technologyRuleset: context.ruleset.technology,
      paceBalance: context.ruleset.paceBalance,
    ),
  );

  GameEngineResult _startProject(
    CanonicalGameSnapshot snapshot,
    StartCityProjectCommand command,
    GameEngineContext context,
  ) => _result(
    snapshot,
    resolver.startCityProject(
      state: snapshot.domain,
      command: command,
      actorPlayerId: context.actorPlayerId,
      cityRuleset: context.ruleset.city,
      paceBalance: context.ruleset.paceBalance,
    ),
  );

  GameEngineResult _startWonder(
    CanonicalGameSnapshot snapshot,
    StartWonderCommand command,
    GameEngineContext context,
  ) => _result(
    snapshot,
    resolver.startWonder(
      state: snapshot.domain,
      command: command,
      actorPlayerId: context.actorPlayerId,
      mapTiles: context.mapView,
      wonderRuleset: context.ruleset.wonders,
      paceBalance: context.ruleset.paceBalance,
    ),
  );

  GameEngineResult _setSpecialization(
    CanonicalGameSnapshot snapshot,
    SetCitySpecializationCommand command,
    GameEngineContext context,
  ) => _result(
    snapshot,
    resolver.setCitySpecialization(
      state: snapshot.domain,
      command: command,
      actorPlayerId: context.actorPlayerId,
    ),
  );

  GameEngineResult _rush(
    CanonicalGameSnapshot snapshot,
    RushProductionCommand command,
    GameEngineContext context,
  ) => _result(
    snapshot,
    resolver.rushProduction(
      state: snapshot.domain,
      command: command,
      actorPlayerId: context.actorPlayerId,
      mapTiles: context.mapView,
      cityRuleset: context.ruleset.city,
      technologyRuleset: context.ruleset.technology,
      stabilityRuleset: context.ruleset.stability,
      wonderRuleset: context.ruleset.wonders,
      paceBalance: context.ruleset.paceBalance,
    ),
  );

  GameEngineResult _result(
    CanonicalGameSnapshot snapshot,
    DomainCityProductionResult result,
  ) {
    if (!result.accepted) {
      return GameEngineResult.rejected(
        snapshot: snapshot,
        reason: result.reason ?? 'command_rejected',
      );
    }
    return GameEngineResult.accepted(
      snapshot: identical(result.state, snapshot.domain)
          ? snapshot
          : snapshot.copyWith(domain: result.state),
      events: [for (final event in result.events) event as DomainEvent],
    );
  }
}
