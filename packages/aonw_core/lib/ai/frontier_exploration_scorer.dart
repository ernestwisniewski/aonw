import 'package:aonw_core/ai/city_founding_safety.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class AiFrontierExplorationScorer {
  static const int observerRevealRadius = 2;
  static const int citySiteApproachRadius = 6;

  const AiFrontierExplorationScorer();

  double score({
    required GameView view,
    required HexCoordinate origin,
    bool citySiteDiscoveryFocus = false,
  }) {
    return genericFrontierScore(view: view, origin: origin) +
        (citySiteDiscoveryFocus
            ? citySiteDiscoveryScore(view: view, origin: origin)
            : 0);
  }

  double genericFrontierScore({
    required GameView view,
    required HexCoordinate origin,
  }) {
    var hidden = 0;
    var discovered = 0;
    for (final tile in view.mapData.tiles) {
      final hex = HexCoordinate.fromTile(tile);
      if (HexDistance.between(origin, hex) > observerRevealRadius) continue;
      if (!view.visibility.canInspectTile(tile)) {
        hidden += 1;
      } else if (!view.visibility.canSeeDynamicAt(tile.col, tile.row)) {
        discovered += 1;
      }
    }

    return hidden * 5.0 +
        discovered * 1.2 +
        nearestOwnCityDistance(view: view, origin: origin) * 0.35;
  }

  double citySiteDiscoveryScore({
    required GameView view,
    required HexCoordinate origin,
  }) {
    if (view.ownCities.isEmpty) return 0;

    final knownCities = [...view.ownCities, ...view.rememberedEnemyCities];
    var hiddenCenters = 0.0;
    var staleCenters = 0.0;
    var approachScore = 0.0;
    var ringReveal = 0;
    for (final tile in view.mapData.tiles) {
      final center = HexCoordinate.fromTile(tile);
      final distanceFromOrigin = HexDistance.between(origin, center);
      if (distanceFromOrigin > citySiteApproachRadius) continue;
      if (!_couldBecomeKnownLegalCenter(
        view: view,
        tile: tile,
        knownCities: knownCities,
      )) {
        continue;
      }

      final ownDistance = nearestOwnCityDistance(view: view, origin: center);
      if (ownDistance < CityFoundingRules.minimumCenterDistance) continue;

      final spacingBonus =
          ownDistance
              .clamp(CityFoundingRules.minimumCenterDistance, 8)
              .toDouble() *
          0.08;
      if (!view.visibility.canInspectTile(tile)) {
        if (distanceFromOrigin <= observerRevealRadius) {
          hiddenCenters += 1.0 + spacingBonus;
        } else {
          approachScore += _approachScore(
            distance: distanceFromOrigin,
            spacingBonus: spacingBonus,
            hidden: true,
          );
        }
        continue;
      }
      if (!view.visibility.canSeeDynamicAt(tile.col, tile.row)) {
        if (distanceFromOrigin <= observerRevealRadius) {
          staleCenters += 1.0 + spacingBonus * 0.5;
        } else {
          approachScore += _approachScore(
            distance: distanceFromOrigin,
            spacingBonus: spacingBonus,
            hidden: false,
          );
        }
        continue;
      }

      final unknownRing = AiCityFoundingSafety.unknownCenterExclusionTiles(
        view: view,
        center: CityHex(col: tile.col, row: tile.row),
      );
      for (final unknownTile in unknownRing) {
        if (HexDistance.between(origin, HexCoordinate.fromTile(unknownTile)) <=
            observerRevealRadius) {
          ringReveal += 1;
        }
      }
    }

    return hiddenCenters * 6.5 +
        staleCenters * 2.0 +
        approachScore +
        ringReveal * 1.4;
  }

  bool _couldBecomeKnownLegalCenter({
    required GameView view,
    required TileData tile,
    required List<GameCity> knownCities,
  }) {
    if (!CitySiteRules.canFoundCityOn(tile)) return false;
    final center = CityHex(col: tile.col, row: tile.row);
    for (final city in knownCities) {
      if (city.center == center || city.controlledHexes.contains(center)) {
        return false;
      }
    }
    if (!CityFoundingRules.isCenterFarEnoughFromCities(center, knownCities)) {
      return false;
    }

    final draft = CityFoundingDraft(
      unitId: '_ai_site_probe',
      ownerPlayerId: view.forPlayerId,
      center: center,
    );
    var potentialControlledHexes = 0;
    for (final hex in HexNeighbors.existingAround(
      HexCoordinate(col: tile.col, row: tile.row),
      view.mapData,
    )) {
      final candidateTile = view.mapData.tileAt(hex.col, hex.row);
      if (candidateTile == null) continue;
      final cityHex = CityHex(col: hex.col, row: hex.row);
      var claimed = false;
      for (final city in knownCities) {
        if (city.center == cityHex || city.controlledHexes.contains(cityHex)) {
          claimed = true;
          break;
        }
      }
      if (claimed) continue;
      if (view.visibility.canInspectTile(candidateTile) &&
          !CityFoundingRules.isControlledHexCandidate(
            draft: draft,
            tile: candidateTile,
            mapData: view.mapData,
            cities: knownCities,
          )) {
        continue;
      }
      potentialControlledHexes += 1;
      if (potentialControlledHexes >=
          CityFoundingDraft.requiredControlledHexes) {
        return true;
      }
    }
    return false;
  }

  double _approachScore({
    required int distance,
    required double spacingBonus,
    required bool hidden,
  }) {
    final remaining = (citySiteApproachRadius - distance + 1)
        .clamp(0, citySiteApproachRadius)
        .toDouble();
    final multiplier = hidden ? 0.62 : 0.34;
    return remaining * multiplier + spacingBonus * (hidden ? 0.8 : 0.4);
  }

  static bool needsCitySiteDiscovery({
    required GameView view,
    required StrategicPlan? plan,
  }) {
    if (view.ownCities.isEmpty) return false;

    var hasUnassignedFounder = false;
    for (final unit in view.ownUnits) {
      if (!CityFoundingRules.canFoundCityWith(unit)) continue;
      if (unit.isWorking || unit.queuedPath != null) continue;
      if (plan?.settlerAssignments.containsKey(unit.id) ?? false) continue;
      hasUnassignedFounder = true;
      break;
    }
    if (!hasUnassignedFounder) return false;

    return plan == null ||
        plan.citySiteRanking.isEmpty ||
        plan.settlerAssignments.isEmpty;
  }

  static int nearestOwnCityDistance({
    required GameView view,
    required HexCoordinate origin,
  }) {
    var nearest = 1 << 30;
    for (final city in view.ownCities) {
      final distance = HexDistance.between(origin, city.center.toCoordinate());
      if (distance < nearest) nearest = distance;
    }
    return nearest == 1 << 30 ? 0 : nearest;
  }
}
