import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/city_founding_safety.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

part 'city_site_scorecard.dart';

class AiCitySiteScore {
  final CityHex center;
  final List<CityHex> controlledHexes;
  final double score;
  final int distanceFromFounder;
  final bool hasKnownExclusionZone;

  AiCitySiteScore({
    required this.center,
    required Iterable<CityHex> controlledHexes,
    required this.score,
    required this.distanceFromFounder,
    required this.hasKnownExclusionZone,
  }) : controlledHexes = List.unmodifiable(controlledHexes);

  bool isCenterFor(GameUnit unit) => center.occupies(unit.col, unit.row);
}

class AiCitySiteScorer {
  static const defaultSearchRadius = 3;
  static const relocationScoreMargin = 2.5;
  static const unknownExclusionZonePenalty = 6.0;

  const AiCitySiteScorer();

  AiCitySiteScore? scoreCurrentSite({
    required GameUnit founder,
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required Iterable<GameCity> knownCities,
    required Set<CityHex> reservedHexes,
    bool requireKnownExclusionZone = true,
    bool useStrategicMapKnowledge = false,
  }) {
    return scoreSite(
      founder: founder,
      center: CityHex(col: founder.col, row: founder.row),
      view: view,
      context: context,
      assessment: assessment,
      knownCities: knownCities,
      reservedHexes: reservedHexes,
      requireKnownExclusionZone: requireKnownExclusionZone,
      useStrategicMapKnowledge: useStrategicMapKnowledge,
    );
  }

  AiCitySiteScore? bestNearbySite({
    required GameUnit founder,
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required Iterable<GameCity> knownCities,
    required Set<CityHex> reservedHexes,
    int searchRadius = defaultSearchRadius,
    bool requireKnownExclusionZone = true,
    bool useStrategicMapKnowledge = false,
  }) {
    final scores = <AiCitySiteScore>[];
    for (final tile in view.mapData.tiles) {
      if (!_canUseStaticTile(
        view: view,
        tile: tile,
        useStrategicMapKnowledge: useStrategicMapKnowledge,
      )) {
        continue;
      }
      final center = CityHex(col: tile.col, row: tile.row);
      final distance = HexDistance.between(
        HexCoordinate(col: founder.col, row: founder.row),
        HexCoordinate(col: center.col, row: center.row),
      );
      if (distance > searchRadius) continue;

      final score = scoreSite(
        founder: founder,
        center: center,
        view: view,
        context: context,
        assessment: assessment,
        knownCities: knownCities,
        reservedHexes: reservedHexes,
        requireKnownExclusionZone: requireKnownExclusionZone,
        useStrategicMapKnowledge: useStrategicMapKnowledge,
      );
      if (score == null) continue;
      scores.add(score);
    }

    scores.sort(_compareScores);
    return scores.isEmpty ? null : scores.first;
  }

  AiCitySiteScore? scoreSite({
    required GameUnit founder,
    required CityHex center,
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required Iterable<GameCity> knownCities,
    required Set<CityHex> reservedHexes,
    bool requireKnownExclusionZone = true,
    bool useStrategicMapKnowledge = false,
  }) {
    if (reservedHexes.contains(center)) return null;

    final centerTile = view.mapData.tileAt(center.col, center.row);
    if (centerTile == null ||
        !_canUseStaticTile(
          view: view,
          tile: centerTile,
          useStrategicMapKnowledge: useStrategicMapKnowledge,
        )) {
      return null;
    }
    final hasKnownExclusionZone =
        AiCityFoundingSafety.hasKnownCenterExclusionZone(
          view: view,
          center: center,
        );
    if (requireKnownExclusionZone && !hasKnownExclusionZone) {
      return null;
    }

    final hypotheticalFounder = founder.copyWith(
      col: center.col,
      row: center.row,
    );
    if (!CityFoundingRules.canStart(
      unit: hypotheticalFounder,
      centerTile: centerTile,
      cities: knownCities,
    )) {
      return null;
    }

    final controlledHexes = _pickControlledHexes(
      founder: hypotheticalFounder,
      view: view,
      knownCities: knownCities,
      reservedHexes: reservedHexes,
      useStrategicMapKnowledge: useStrategicMapKnowledge,
    );
    if (controlledHexes.length < CityFoundingDraft.requiredControlledHexes) {
      return null;
    }

    final distance = HexDistance.between(
      HexCoordinate(col: founder.col, row: founder.row),
      HexCoordinate(col: center.col, row: center.row),
    );
    return AiCitySiteScore(
      center: center,
      controlledHexes: controlledHexes,
      score:
          _CitySiteScorecard(
            centerTile: centerTile,
            controlledHexes: controlledHexes,
            view: view,
            context: context,
            assessment: assessment,
            knownCities: knownCities,
            distanceFromFounder: distance,
          ).score() -
          (hasKnownExclusionZone ? 0 : unknownExclusionZonePenalty),
      distanceFromFounder: distance,
      hasKnownExclusionZone: hasKnownExclusionZone,
    );
  }

  bool shouldRelocate({
    required AiCitySiteScore target,
    required AiCitySiteScore? current,
  }) {
    if (current == null) return true;
    if (target.center == current.center) return false;
    final travelMargin =
        relocationScoreMargin + target.distanceFromFounder * 0.5;
    return target.score >= current.score + travelMargin;
  }

  List<CityHex> _pickControlledHexes({
    required GameUnit founder,
    required GameView view,
    required Iterable<GameCity> knownCities,
    required Set<CityHex> reservedHexes,
    required bool useStrategicMapKnowledge,
  }) {
    final draft = CityFoundingDraft(
      unitId: founder.id,
      ownerPlayerId: founder.ownerPlayerId,
      center: CityHex(col: founder.col, row: founder.row),
    );
    final visibleResourceTypes = _visibleResourceTypes(view);

    final candidates = <_ControlledCityHexCandidate>[];
    for (final hex in HexNeighbors.existingAround(
      HexCoordinate(col: founder.col, row: founder.row),
      view.mapData,
    )) {
      final tile = view.mapData.tileAt(hex.col, hex.row);
      if (tile == null ||
          !_canUseStaticTile(
            view: view,
            tile: tile,
            useStrategicMapKnowledge: useStrategicMapKnowledge,
          )) {
        continue;
      }
      final cityHex = CityHex(col: hex.col, row: hex.row);
      if (reservedHexes.contains(cityHex)) continue;
      if (!CityFoundingRules.isControlledHexCandidate(
        draft: draft,
        tile: tile,
        mapData: view.mapData,
        cities: knownCities,
      )) {
        continue;
      }
      candidates.add(
        _ControlledCityHexCandidate(
          hex: cityHex,
          score: _tileDevelopmentScore(tile, visibleResourceTypes),
        ),
      );
    }

    candidates.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      final colCompare = a.hex.col.compareTo(b.hex.col);
      if (colCompare != 0) return colCompare;
      return a.hex.row.compareTo(b.hex.row);
    });

    return [
      for (final candidate in candidates.take(
        CityFoundingDraft.requiredControlledHexes,
      ))
        candidate.hex,
    ];
  }

  bool _canUseStaticTile({
    required GameView view,
    required TileData tile,
    required bool useStrategicMapKnowledge,
  }) {
    return useStrategicMapKnowledge || view.visibility.canInspectTile(tile);
  }

  int _compareScores(AiCitySiteScore a, AiCitySiteScore b) {
    final scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) return scoreCompare;
    final distanceCompare = a.distanceFromFounder.compareTo(
      b.distanceFromFounder,
    );
    if (distanceCompare != 0) return distanceCompare;
    final colCompare = a.center.col.compareTo(b.center.col);
    if (colCompare != 0) return colCompare;
    return a.center.row.compareTo(b.center.row);
  }
}

final class _ControlledCityHexCandidate {
  final CityHex hex;
  final double score;

  const _ControlledCityHexCandidate({required this.hex, required this.score});
}

Set<ResourceType> _visibleResourceTypes(GameView view) {
  return ResourceVisibilityRules.visibleResourceTypes(
    playerId: view.forPlayerId,
    research: ResearchState(players: {view.forPlayerId: view.ownResearch}),
  );
}

Set<ResourceType> _missingStrategicResourceTypes(GameView view) {
  final network = EmpireResourceNetworkRules.forPlayer(
    playerId: view.forPlayerId,
    cities: view.ownCities,
    mapData: view.mapData,
    research: view.research,
    ruleset: view.ruleset.city,
    resourceTradeAgreements: view.resourceTradeAgreements,
  );
  return {
    for (final resource in _strategicResources)
      if (!network.controlsVisible(resource)) resource,
  };
}

double _tileDevelopmentScore(
  TileData tile,
  Set<ResourceType> visibleResourceTypes,
) {
  final yield = CityTileYieldRules.forTile(tile);
  return yield.food +
      yield.production +
      yield.gold * 0.5 +
      _visibleResourceCount(tile, visibleResourceTypes);
}

int _visibleResourceCount(
  TileData tile,
  Set<ResourceType> visibleResourceTypes,
) {
  return tile.resources.where(visibleResourceTypes.contains).length;
}

const _strategicResources = {
  ResourceType.iron,
  ResourceType.coal,
  ResourceType.oil,
  ResourceType.aluminium,
  ResourceType.uranium,
  ResourceType.horses,
  ResourceType.marble,
};
