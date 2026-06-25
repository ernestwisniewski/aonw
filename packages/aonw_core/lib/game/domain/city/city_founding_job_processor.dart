import 'package:aonw_core/game/domain/city/city_founding.dart';
import 'package:aonw_core/game/domain/city/city_name_catalog.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class CityFoundingJobBatchResult {
  const CityFoundingJobBatchResult({
    required this.cities,
    required this.units,
    this.events = const [],
    this.foundedCities = const [],
    required this.changed,
  });

  final List<GameCity> cities;
  final List<GameUnit> units;
  final List<GameEvent> events;
  final List<GameCity> foundedCities;
  final bool changed;
}

abstract final class CityFoundingJobProcessor {
  static CityFoundingJobBatchResult advanceForPlayer({
    required String playerId,
    required List<GameUnit> units,
    required List<GameCity> cities,
    required MapData mapData,
    required PlayerCountry Function(String playerId) countryForPlayer,
    CityRuleset cityRuleset = CityRulesets.standard,
  }) {
    final updatedUnits = List<GameUnit>.of(units);
    final updatedCities = List<GameCity>.of(cities);
    final foundedCities = <GameCity>[];
    final events = <GameEvent>[];
    var changed = false;

    for (var index = 0; index < updatedUnits.length; index++) {
      final unit = updatedUnits[index];
      if (unit.ownerPlayerId != playerId) continue;

      final job = unit.cityFoundingJob;
      if (job == null) continue;

      changed = true;
      if (!_jobStillValid(
        unit: unit,
        cities: updatedCities,
        mapData: mapData,
      )) {
        updatedUnits[index] = unit
            .copyWithCityFoundingJob(null)
            .copyWithQueuedPath(null);
        continue;
      }

      final draft = CityFoundingDraft(
        unitId: unit.id,
        ownerPlayerId: unit.ownerPlayerId,
        center: job.center,
        controlledHexes: job.controlledHexes,
      );
      if (CityFoundingRules.confirmFailure(draft) != null ||
          !_controlledHexesAreValid(draft, mapData, updatedCities)) {
        updatedUnits[index] = unit
            .copyWithCityFoundingJob(null)
            .copyWithQueuedPath(null);
        continue;
      }

      if (job.remainingTurns > 1) {
        updatedUnits[index] = unit
            .copyWithCityFoundingJob(
              job.copyWith(remainingTurns: job.remainingTurns - 1),
            )
            .copyWithQueuedPath(null);
        continue;
      }

      final city = GameCity.founded(
        founder: unit,
        name: CityNameCatalog.nextName(
          country: countryForPlayer(unit.ownerPlayerId),
          sequence: _nextCitySequenceForPlayer(
            updatedCities,
            unit.ownerPlayerId,
          ),
        ),
        controlledHexes: job.controlledHexes,
        sequence: updatedCities.length + 1,
        progression: cityRuleset.progression,
      );
      updatedCities.add(city);
      foundedCities.add(city);
      events.add(
        CityFoundedEvent(cityId: city.id, ownerPlayerId: city.ownerPlayerId),
      );

      if (unit.type == GameUnitType.settler) {
        updatedUnits.removeAt(index);
        index--;
      } else {
        updatedUnits[index] = unit
            .consumeSettler()
            .copyWithCityFoundingJob(null)
            .copyWithQueuedPath(null);
      }
    }

    return CityFoundingJobBatchResult(
      cities: List<GameCity>.unmodifiable(updatedCities),
      units: List<GameUnit>.unmodifiable(updatedUnits),
      events: List<GameEvent>.unmodifiable(events),
      foundedCities: List<GameCity>.unmodifiable(foundedCities),
      changed: changed,
    );
  }

  static bool _jobStillValid({
    required GameUnit unit,
    required Iterable<GameCity> cities,
    required MapData mapData,
  }) {
    final job = unit.cityFoundingJob;
    if (job == null) return false;
    if (!unit.occupies(job.center.col, job.center.row)) return false;
    return CityFoundingRules.startFailure(
          unit: unit,
          centerTile: mapData.tileAt(job.center.col, job.center.row),
          cities: cities,
        ) ==
        null;
  }

  static bool _controlledHexesAreValid(
    CityFoundingDraft draft,
    MapData mapData,
    Iterable<GameCity> cities,
  ) {
    final unique = draft.controlledHexes.toSet();
    if (unique.length != draft.controlledHexes.length) return false;
    for (final hex in draft.controlledHexes) {
      final tile = mapData.tileAt(hex.col, hex.row);
      if (tile == null) return false;
      if (!CityFoundingRules.isControlledHexCandidate(
        draft: draft,
        tile: tile,
        mapData: mapData,
        cities: cities,
      )) {
        return false;
      }
    }
    return true;
  }

  static int _nextCitySequenceForPlayer(
    Iterable<GameCity> cities,
    String playerId,
  ) {
    return cities.where((city) => city.ownerPlayerId == playerId).length + 1;
  }
}
