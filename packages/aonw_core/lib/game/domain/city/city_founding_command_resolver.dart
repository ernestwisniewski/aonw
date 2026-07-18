import 'package:aonw_core/game/domain/city/city_founding.dart';
import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Persistence-neutral result of scheduling a city founding job.
///
/// Rejections preserve the identity of [units] and [cityFoundingDraft]. An
/// accepted collection is owned by the result and cannot be mutated.
final class CityFoundingCommandResult {
  const CityFoundingCommandResult._accepted({
    required this.units,
    required this.cityFoundingDraft,
  }) : accepted = true,
       reason = null;

  const CityFoundingCommandResult._rejected({
    required this.units,
    required this.cityFoundingDraft,
    required this.reason,
  }) : accepted = false;

  final bool accepted;
  final String? reason;
  final List<GameUnit> units;
  final CityFoundingDraft? cityFoundingDraft;
}

/// Applies the authoritative city-founding command without a state container.
abstract final class CityFoundingCommandResolver {
  static CityFoundingCommandResult foundCity({
    required List<GameUnit> units,
    required List<GameCity> cities,
    required CityFoundingDraft? cityFoundingDraft,
    required FoundCityCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
  }) {
    final validation = _validateFounder(
      units: units,
      cities: cities,
      founderId: command.founderId,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
    );
    if (validation.reason case final reason?) {
      return _reject(units, cityFoundingDraft, reason);
    }
    final founderIndex = validation.index!;
    final founder = validation.founder!;

    final foundingDraft = CityFoundingDraft(
      unitId: founder.id,
      ownerPlayerId: founder.ownerPlayerId,
      center: CityHex(col: founder.col, row: founder.row),
      controlledHexes: command.controlledHexes,
    );
    if (CityFoundingRules.confirmFailure(foundingDraft) != null ||
        !_controlledHexesAreValid(foundingDraft, mapTiles, cities)) {
      return _reject(units, cityFoundingDraft, 'city_controlled_hexes_invalid');
    }

    final updatedFounder = founder
        .copyWith(movementPoints: 0)
        .copyWithQueuedPath(null)
        .copyWithCityFoundingJob(
          CityFoundingJob(
            center: foundingDraft.center,
            controlledHexes: foundingDraft.controlledHexes,
            remainingTurns: 1,
            totalTurns: 1,
          ),
        );
    return CityFoundingCommandResult._accepted(
      units: List<GameUnit>.unmodifiable([
        for (var index = 0; index < units.length; index++)
          if (index == founderIndex) updatedFounder else units[index],
      ]),
      cityFoundingDraft: cityFoundingDraft?.unitId == founder.id
          ? null
          : cityFoundingDraft,
    );
  }

  static ({int? index, GameUnit? founder, String? reason}) _validateFounder({
    required List<GameUnit> units,
    required List<GameCity> cities,
    required String founderId,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
  }) {
    final founderIndex = _unitIndexById(units, founderId);
    if (founderIndex == null) {
      return (index: null, founder: null, reason: 'city_founder_not_found');
    }
    final founder = units[founderIndex];
    if (founder.ownerPlayerId != actorPlayerId) {
      return (
        index: null,
        founder: null,
        reason: 'city_founder_not_controlled',
      );
    }
    if (founder.isWorking) {
      return (index: null, founder: null, reason: 'city_founder_busy');
    }
    final failure = CityFoundingRules.startFailure(
      unit: founder,
      centerTile: mapTiles.tileAt(founder.col, founder.row),
      cities: cities,
    );
    return (
      index: failure == null ? founderIndex : null,
      founder: failure == null ? founder : null,
      reason: failure == null ? null : _reasonForStartFailure(failure),
    );
  }

  static bool _controlledHexesAreValid(
    CityFoundingDraft draft,
    MapTileLookup mapTiles,
    Iterable<GameCity> cities,
  ) {
    final unique = draft.controlledHexes.toSet();
    if (unique.length != draft.controlledHexes.length) return false;
    for (final hex in draft.controlledHexes) {
      final tile = mapTiles.tileAt(hex.col, hex.row);
      if (tile == null ||
          !CityFoundingRules.isControlledHexCandidate(
            draft: draft,
            tile: tile,
            mapTiles: mapTiles,
            cities: cities,
          )) {
        return false;
      }
    }
    return true;
  }

  static String _reasonForStartFailure(CityFoundingFailure failure) {
    return switch (failure) {
      CityFoundingFailure.noCommander => 'city_founder_invalid',
      CityFoundingFailure.noSettlers => 'city_founder_no_settlers',
      CityFoundingFailure.invalidCenter => 'city_site_invalid',
      CityFoundingFailure.cityAlreadyExists => 'city_center_occupied',
      CityFoundingFailure.centerOccupied => 'city_center_claimed',
      CityFoundingFailure.tooCloseToCity => 'city_center_too_close',
      CityFoundingFailure.invalidControlledHexes =>
        'city_controlled_hexes_invalid',
    };
  }

  static int? _unitIndexById(List<GameUnit> units, String unitId) {
    for (var index = 0; index < units.length; index++) {
      if (units[index].id == unitId) return index;
    }
    return null;
  }

  static CityFoundingCommandResult _reject(
    List<GameUnit> units,
    CityFoundingDraft? cityFoundingDraft,
    String reason,
  ) {
    return CityFoundingCommandResult._rejected(
      units: units,
      cityFoundingDraft: cityFoundingDraft,
      reason: reason,
    );
  }
}
