import 'package:aonw_core/game/domain/city/city_founding_command_resolver.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class DomainCityFoundingResult {
  const DomainCityFoundingResult({
    required this.accepted,
    required this.state,
    required this.interaction,
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final PersistedInteractionState interaction;
  final String? reason;
}

/// Canonical-state adapter for the state-neutral city-founding resolver.
final class DomainCityFoundingResolver {
  const DomainCityFoundingResolver();

  DomainCityFoundingResult foundCity({
    required DomainState state,
    required PersistedInteractionState interaction,
    required FoundCityCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
  }) {
    final result = CityFoundingCommandResolver.foundCity(
      units: state.units,
      cities: state.cities,
      cityFoundingDraft: interaction.cityFoundingDraft,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
    );
    if (!result.accepted) {
      return DomainCityFoundingResult(
        accepted: false,
        state: state,
        interaction: interaction,
        reason: result.reason,
      );
    }

    final interactionChanged = !identical(
      result.cityFoundingDraft,
      interaction.cityFoundingDraft,
    );
    return DomainCityFoundingResult(
      accepted: true,
      state: state.copyWith(units: result.units),
      interaction: interactionChanged
          ? interaction.copyWith(cityFoundingDraft: result.cityFoundingDraft)
          : interaction,
    );
  }
}
