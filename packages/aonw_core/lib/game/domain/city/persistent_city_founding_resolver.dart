import 'package:aonw_core/game/domain/city/city_founding_command_resolver.dart';
import 'package:aonw_core/game/domain/city/city_founding_draft.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class PersistentCityFoundingResult {
  const PersistentCityFoundingResult({
    required this.accepted,
    required this.state,
    this.events = const [],
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final List<GameEvent> events;
  final String? reason;
}

/// Persistence adapter for the state-neutral city-founding resolver.
final class PersistentCityFoundingResolver {
  const PersistentCityFoundingResolver();

  PersistentCityFoundingResult foundCity({
    required PersistentGameState state,
    required FoundCityCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
  }) {
    final result = CityFoundingCommandResolver.foundCity(
      units: state.units,
      cities: state.cities,
      cityFoundingDraft: state.runtimeState.cityFoundingDraft,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
    );
    if (!result.accepted) {
      return PersistentCityFoundingResult(
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }

    final runtimeState = _runtimeStateAfterFounding(
      state.runtimeState,
      result.cityFoundingDraft,
    );
    return PersistentCityFoundingResult(
      accepted: true,
      state: state.copyWith(
        units: result.units,
        runtimeState: identical(runtimeState, state.runtimeState)
            ? null
            : runtimeState,
      ),
    );
  }

  static GameRuntimeState _runtimeStateAfterFounding(
    GameRuntimeState runtimeState,
    CityFoundingDraft? cityFoundingDraft,
  ) {
    if (identical(cityFoundingDraft, runtimeState.cityFoundingDraft)) {
      return runtimeState;
    }
    return runtimeState.copyWith(cityFoundingDraft: cityFoundingDraft);
  }
}
