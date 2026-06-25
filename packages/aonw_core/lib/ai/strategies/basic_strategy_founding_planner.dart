import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/city_site_scorer.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_founding_move_planner.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class BasicStrategyFoundingPlanner {
  const BasicStrategyFoundingPlanner({
    this.movePlanner = const BasicStrategyFoundingMovePlanner(),
    this.siteScorer = const AiCitySiteScorer(),
  });

  final BasicStrategyFoundingMovePlanner movePlanner;
  final AiCitySiteScorer siteScorer;

  List<GameCommand> plan(
    GameView view,
    AiContext context,
    AiEmpireAssessment assessment,
  ) {
    if (view.ownUnits.isEmpty) return const [];

    final knownCities = _knownCities(view);
    final plannedCities = <GameCity>[];
    final commands = <GameCommand>[];
    final reservedCenters = <CityHex>{
      for (final city in knownCities) city.center,
      for (final city in knownCities) ...city.controlledHexes,
    };
    final pathfinder = UnitMovementPathfinder(
      mapData: view.mapData,
      units: view.movementBlockingUnits,
    );
    final occupied = <String>{
      for (final unit in view.ownUnits) _key(unit.col, unit.row),
      for (final unit in view.visibleEnemyUnits) _key(unit.col, unit.row),
    };
    final useStrategicMapKnowledge = view.ownCities.isNotEmpty;

    final founders = [...view.ownUnits]..sort((a, b) => a.id.compareTo(b.id));

    for (final unit in founders) {
      if (!CityFoundingRules.canFoundCityWith(unit)) continue;
      if (unit.queuedPath != null || unit.isWorking) continue;

      final cityContext = [...knownCities, ...plannedCities];
      final currentSite = siteScorer.scoreCurrentSite(
        founder: unit,
        view: view,
        context: context,
        assessment: assessment,
        knownCities: cityContext,
        reservedHexes: reservedCenters,
      );
      final assignedCenter = view.ownCities.isEmpty
          ? null
          : context.strategicPlan?.settlerAssignments[unit.id];
      final assignedSite = assignedCenter == null
          ? null
          : siteScorer.scoreSite(
              founder: unit,
              center: assignedCenter,
              view: view,
              context: context,
              assessment: assessment,
              knownCities: cityContext,
              reservedHexes: reservedCenters,
              requireKnownExclusionZone: false,
              useStrategicMapKnowledge: useStrategicMapKnowledge,
            );
      final openingSite = currentSite;
      if (openingSite != null &&
          _shouldFoundOpeningSite(view: view, currentSite: openingSite) &&
          _canFoundSiteNow(view: view, site: openingSite)) {
        commands.add(
          FoundCityCommand(
            unit.id,
            controlledHexes: openingSite.controlledHexes,
          ),
        );
        reservedCenters
          ..add(openingSite.center)
          ..addAll(openingSite.controlledHexes);
        plannedCities.add(_plannedCityFor(unit, openingSite));
        continue;
      }

      if (assignedSite != null) {
        if (!assignedSite.isCenterFor(unit) &&
            currentSite != null &&
            _canFoundSiteNow(view: view, site: currentSite) &&
            _shouldFoundCurrentUnderExpansionPressure(
              view: view,
              context: context,
              assessment: assessment,
              currentSite: currentSite,
              targetSite: assignedSite,
            )) {
          commands.add(
            FoundCityCommand(
              unit.id,
              controlledHexes: currentSite.controlledHexes,
            ),
          );
          reservedCenters
            ..add(currentSite.center)
            ..addAll(currentSite.controlledHexes);
          plannedCities.add(_plannedCityFor(unit, currentSite));
          continue;
        }

        if (assignedSite.isCenterFor(unit)) {
          if (_canFoundSiteNow(view: view, site: assignedSite)) {
            commands.add(
              FoundCityCommand(
                unit.id,
                controlledHexes: assignedSite.controlledHexes,
              ),
            );
            reservedCenters
              ..add(assignedSite.center)
              ..addAll(assignedSite.controlledHexes);
            plannedCities.add(_plannedCityFor(unit, assignedSite));
            continue;
          }

          final revealMove = movePlanner.revealAssignedSiteMove(
            unit: unit,
            view: view,
            center: assignedSite.center,
            occupied: occupied,
            pathfinder: pathfinder,
          );
          if (revealMove != null) {
            commands.add(revealMove.command);
            occupied
              ..remove(_key(unit.col, unit.row))
              ..addAll(
                revealMove.reservedHexes.map((hex) => _key(hex.col, hex.row)),
              );
            reservedCenters
              ..add(assignedSite.center)
              ..addAll(assignedSite.controlledHexes);
            plannedCities.add(_plannedCityFor(unit, assignedSite));
            continue;
          }
        }

        final plannedMove = movePlanner.moveTowardSite(
          unit: unit,
          site: assignedSite,
          view: view,
          pathfinder: pathfinder,
        );
        if (plannedMove != null) {
          commands.add(plannedMove.command);
          occupied
            ..remove(_key(unit.col, unit.row))
            ..addAll(
              plannedMove.reservedHexes.map((hex) => _key(hex.col, hex.row)),
            );
          reservedCenters
            ..add(assignedSite.center)
            ..addAll(assignedSite.controlledHexes);
          plannedCities.add(_plannedCityFor(unit, assignedSite));
          continue;
        }
      }

      final bestSite = siteScorer.bestNearbySite(
        founder: unit,
        view: view,
        context: context,
        assessment: assessment,
        knownCities: cityContext,
        reservedHexes: reservedCenters,
        requireKnownExclusionZone: false,
        useStrategicMapKnowledge: useStrategicMapKnowledge,
      );

      if (currentSite != null &&
          !_canFoundSiteNow(view: view, site: currentSite) &&
          bestSite != null &&
          bestSite.center != currentSite.center) {
        final plannedMove = movePlanner.moveTowardSite(
          unit: unit,
          site: bestSite,
          view: view,
          pathfinder: pathfinder,
        );
        if (plannedMove != null) {
          commands.add(plannedMove.command);
          occupied
            ..remove(_key(unit.col, unit.row))
            ..addAll(
              plannedMove.reservedHexes.map((hex) => _key(hex.col, hex.row)),
            );
          reservedCenters
            ..add(bestSite.center)
            ..addAll(bestSite.controlledHexes);
          plannedCities.add(_plannedCityFor(unit, bestSite));
          continue;
        }
      }

      if (bestSite != null &&
          currentSite != null &&
          _canFoundSiteNow(view: view, site: currentSite) &&
          _shouldFoundCurrentUnderExpansionPressure(
            view: view,
            context: context,
            assessment: assessment,
            currentSite: currentSite,
            targetSite: bestSite,
          )) {
        commands.add(
          FoundCityCommand(
            unit.id,
            controlledHexes: currentSite.controlledHexes,
          ),
        );
        reservedCenters
          ..add(currentSite.center)
          ..addAll(currentSite.controlledHexes);
        plannedCities.add(_plannedCityFor(unit, currentSite));
        continue;
      }

      if (bestSite != null &&
          siteScorer.shouldRelocate(target: bestSite, current: currentSite)) {
        final plannedMove = movePlanner.moveTowardSite(
          unit: unit,
          site: bestSite,
          view: view,
          pathfinder: pathfinder,
        );
        if (plannedMove != null) {
          commands.add(plannedMove.command);
          occupied
            ..remove(_key(unit.col, unit.row))
            ..addAll(
              plannedMove.reservedHexes.map((hex) => _key(hex.col, hex.row)),
            );
          reservedCenters
            ..add(bestSite.center)
            ..addAll(bestSite.controlledHexes);
          plannedCities.add(_plannedCityFor(unit, bestSite));
          continue;
        }
      }

      final retreatMove = movePlanner.retreatMove(
        unit: unit,
        view: view,
        occupied: occupied,
        pathfinder: pathfinder,
      );
      if (retreatMove != null) {
        commands.add(retreatMove.command);
        occupied
          ..remove(_key(unit.col, unit.row))
          ..addAll(
            retreatMove.reservedHexes.map((hex) => _key(hex.col, hex.row)),
          );
        continue;
      }
      if (movePlanner.isFounderThreatened(unit: unit, view: view)) {
        continue;
      }

      if (currentSite == null) {
        final scoutingMove = movePlanner.frontierMove(
          unit: unit,
          view: view,
          context: context,
          occupied: occupied,
          pathfinder: pathfinder,
          forceMove: true,
        );
        if (scoutingMove != null) {
          commands.add(scoutingMove.command);
          occupied
            ..remove(_key(unit.col, unit.row))
            ..addAll(
              scoutingMove.reservedHexes.map((hex) => _key(hex.col, hex.row)),
            );
          continue;
        }
        continue;
      }
      if (!_canFoundSiteNow(view: view, site: currentSite)) {
        continue;
      }
      commands.add(
        FoundCityCommand(unit.id, controlledHexes: currentSite.controlledHexes),
      );
      reservedCenters
        ..add(currentSite.center)
        ..addAll(currentSite.controlledHexes);
      plannedCities.add(_plannedCityFor(unit, currentSite));
    }

    return List.unmodifiable(commands);
  }

  bool _shouldFoundOpeningSite({
    required GameView view,
    required AiCitySiteScore? currentSite,
  }) {
    if (view.ownCities.isNotEmpty || currentSite == null) return false;
    return currentSite.score >= 0;
  }

  bool _shouldFoundCurrentUnderExpansionPressure({
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required AiCitySiteScore currentSite,
    required AiCitySiteScore targetSite,
  }) {
    if (!assessment.wantsExpansion) return false;
    if (view.ownCities.length != 1 && view.ownCities.length != 2) {
      return false;
    }
    if (!currentSite.hasKnownExclusionZone) return false;
    if (currentSite.center == targetSite.center) return false;

    final pressureTurn = view.ownCities.length == 1
        ? _secondCityPressureTurn(context)
        : _thirdCityPressureTurn(context);
    if (context.turn < pressureTurn) return false;

    final minimumGoodEnoughScore = view.ownCities.length == 1 ? 8.0 : 0.0;
    if (currentSite.score < minimumGoodEnoughScore) return false;
    if (view.ownCities.length == 2) return true;
    if (targetSite.score <= currentSite.score) return true;

    final scoreGap = targetSite.score - currentSite.score;
    final lateTurns = (context.turn - pressureTurn).clamp(0, 12);
    final maxAcceptedSacrifice = view.ownCities.length == 1
        ? 5.0 + lateTurns * 0.25
        : 6.0 + lateTurns * 0.3;
    final minimumRelativeScore = view.ownCities.length == 1 ? 0.7 : 0.5;
    return scoreGap <= maxAcceptedSacrifice &&
        currentSite.score >= targetSite.score * minimumRelativeScore;
  }

  int _secondCityPressureTurn(AiContext context) {
    final raw =
        20 *
        context.ruleset.paceBalance.unitProductionCostMultiplier *
        context.civProfile.expansionDistance;
    return raw.round().clamp(14, 24).toInt();
  }

  int _thirdCityPressureTurn(AiContext context) {
    final raw =
        28 *
        context.ruleset.paceBalance.unitProductionCostMultiplier *
        context.civProfile.expansionDistance;
    return raw.round().clamp(24, 36).toInt();
  }

  bool _canFoundSiteNow({
    required GameView view,
    required AiCitySiteScore? site,
  }) {
    if (site == null || !site.hasKnownExclusionZone) return false;
    return movePlanner.isFounderMoveSafe(
      target: site.center.toCoordinate(),
      view: view,
    );
  }

  GameCity _plannedCityFor(GameUnit founder, AiCitySiteScore site) {
    return GameCity(
      id: 'planned_${founder.id}_${site.center.col}_${site.center.row}',
      ownerPlayerId: founder.ownerPlayerId,
      name: 'Planned',
      center: site.center,
      controlledHexes: site.controlledHexes,
    );
  }

  List<GameCity> _knownCities(GameView view) {
    final byId = <String, GameCity>{};
    for (final city in view.ownCities) {
      byId[city.id] = city;
    }
    for (final city in view.rememberedEnemyCities) {
      byId[city.id] = city;
    }
    return byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  String _key(int col, int row) => '$col:$row';
}
