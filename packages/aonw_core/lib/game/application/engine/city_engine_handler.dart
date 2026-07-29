import 'package:aonw_core/game/application/engine/game_engine_context.dart';
import 'package:aonw_core/game/application/engine/game_engine_result.dart';
import 'package:aonw_core/game/domain/city/domain_city_expansion_resolver.dart';
import 'package:aonw_core/game/domain/city/domain_city_founding_resolver.dart';
import 'package:aonw_core/game/domain/city/domain_city_worked_hex_resolver.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state.dart';

/// Applies authoritative city-founding, worked-hex and expansion commands.
final class CityEngineHandler {
  const CityEngineHandler({
    this.foundingResolver = const DomainCityFoundingResolver(),
    this.workedHexResolver = const DomainCityWorkedHexResolver(),
    this.expansionResolver = const DomainCityExpansionResolver(),
  });

  final DomainCityFoundingResolver foundingResolver;
  final DomainCityWorkedHexResolver workedHexResolver;
  final DomainCityExpansionResolver expansionResolver;

  GameEngineResult apply({
    required CanonicalGameSnapshot snapshot,
    required DomainCommand command,
    required GameEngineContext context,
  }) {
    return switch (command) {
      final FoundCityCommand value => _foundCity(snapshot, value, context),
      final ToggleWorkedHexCommand value => _toggleWorkedHex(
        snapshot,
        value,
        context,
      ),
      final SelectCityExpansionHexCommand value => _selectExpansionHex(
        snapshot,
        value,
        context,
      ),
      _ => GameEngineResult.rejected(
        snapshot: snapshot,
        reason: 'unsupported_domain_command',
      ),
    };
  }

  GameEngineResult _foundCity(
    CanonicalGameSnapshot snapshot,
    FoundCityCommand command,
    GameEngineContext context,
  ) {
    final result = foundingResolver.foundCity(
      state: snapshot.domain,
      interaction: snapshot.interaction,
      command: command,
      actorPlayerId: context.actorPlayerId,
      mapTiles: context.mapView,
    );
    if (!result.accepted) return _reject(snapshot, result.reason);
    return _accept(
      snapshot,
      domain: result.state,
      interaction: result.interaction,
    );
  }

  GameEngineResult _toggleWorkedHex(
    CanonicalGameSnapshot snapshot,
    ToggleWorkedHexCommand command,
    GameEngineContext context,
  ) {
    final result = workedHexResolver.toggleWorkedHex(
      state: snapshot.domain,
      command: command,
      actorPlayerId: context.actorPlayerId,
      cityRuleset: context.ruleset.city,
    );
    if (!result.accepted) return _reject(snapshot, result.reason);
    return _accept(snapshot, domain: result.state);
  }

  GameEngineResult _selectExpansionHex(
    CanonicalGameSnapshot snapshot,
    SelectCityExpansionHexCommand command,
    GameEngineContext context,
  ) {
    final result = expansionResolver.selectExpansionHex(
      state: snapshot.domain,
      command: command,
      actorPlayerId: context.actorPlayerId,
      mapTiles: context.mapView,
      cityRuleset: context.ruleset.city,
      technologyRuleset: context.ruleset.technology,
    );
    if (!result.accepted) return _reject(snapshot, result.reason);
    return _accept(snapshot, domain: result.state);
  }

  static GameEngineResult _accept(
    CanonicalGameSnapshot snapshot, {
    required DomainState domain,
    PersistedInteractionState? interaction,
  }) {
    final nextInteraction = interaction ?? snapshot.interaction;
    final domainChanged = !identical(domain, snapshot.domain);
    final interactionChanged = !identical(
      nextInteraction,
      snapshot.interaction,
    );
    return GameEngineResult.accepted(
      snapshot: domainChanged || interactionChanged
          ? snapshot.copyWith(
              domain: domainChanged ? domain : null,
              interaction: interactionChanged ? nextInteraction : null,
            )
          : snapshot,
    );
  }

  static GameEngineResult _reject(
    CanonicalGameSnapshot snapshot,
    String? reason,
  ) {
    return GameEngineResult.rejected(
      snapshot: snapshot,
      reason: reason ?? 'command_rejected',
    );
  }
}
