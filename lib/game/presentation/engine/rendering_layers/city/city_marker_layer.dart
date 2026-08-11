import 'dart:async';
import 'dart:ui';

import 'package:aonw/game/presentation/engine/rendering_layers/city/city_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_marker_visual_state.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_sprite_catalog.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:flame/components.dart';

class CityMarkerLayer extends Component with LayerAttachment {
  final int Function(String playerId) colorForPlayer;
  final void Function(GameCity city)? onCityTapped;
  final Map<String, CityMarker> _markers = {};
  final Set<String> _retainedAnimationCityIds = {};
  bool _reduceMotion;
  bool _showHealthBar = true;
  double _markerWorldScale = 1.0;

  CityMarkerLayer({
    required this.colorForPlayer,
    this.onCityTapped,
    bool reduceMotion = false,
  }) : _reduceMotion = reduceMotion;

  bool get reduceMotion => _reduceMotion;

  bool get showHealthBar => _showHealthBar;

  set showHealthBar(bool value) {
    if (_showHealthBar == value) return;
    _showHealthBar = value;
    for (final marker in _markers.values) {
      marker.applyVisualState(
        marker.visualState.copyWith(showHealthBar: value),
      );
    }
  }

  double get markerWorldScale => _markerWorldScale;

  set markerWorldScale(double value) {
    final next = value.isFinite ? value.clamp(1.0, 3.0).toDouble() : 1.0;
    if (_markerWorldScale == next) return;
    _markerWorldScale = next;
    for (final marker in _markers.values) {
      marker.applyVisualState(
        marker.visualState.copyWith(markerWorldScale: next),
      );
    }
  }

  set reduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    for (final marker in _markers.values) {
      marker.applyVisualState(marker.visualState.copyWith(reduceMotion: value));
    }
  }

  double? markerHealthFractionForTesting(String cityId) =>
      _markers[cityId]?.visualState.healthFraction;

  int? markerVisualLevelForTesting(String cityId) =>
      _markers[cityId]?.visualState.visualLevel;

  CitySpriteTechnologyProfile? markerTechnologyProfileForTesting(
    String cityId,
  ) => _markers[cityId]?.visualState.technologyProfile;

  Vector2? markerPositionForTesting(String cityId) =>
      _markers[cityId]?.position.clone();

  Vector2? markerRestingPositionForTesting(String cityId) =>
      switch (_markers[cityId]?.visualState.worldPosition) {
        final position? => Vector2(position.dx, position.dy),
        null => null,
      };

  String? markerCityNameForTesting(String cityId) =>
      _markers[cityId]?.visualState.name;

  int? markerPopulationForTesting(String cityId) =>
      _markers[cityId]?.visualState.population;

  bool markerIsCapitalForTesting(String cityId) =>
      _markers[cityId]?.visualState.isCapital ?? false;

  bool? markerLabelEnabledForTesting(String cityId) =>
      _markers[cityId]?.visualState.showLabel;

  bool? markerPaintsLabelForTesting(String cityId) =>
      _markers[cityId]?.debugSnapshot.paintsCityLabel;

  bool? markerPaintsLabelOwnerDotForTesting(String cityId) =>
      _markers[cityId]?.debugSnapshot.paintsCityLabelOwnerDot;

  bool markerShowHealthBarForTesting(String cityId) =>
      _markers[cityId]?.visualState.showHealthBar ?? false;

  bool markerPaintsHealthBarForTesting(String cityId) =>
      _markers[cityId]?.debugSnapshot.paintsCityHealthBar ?? false;

  bool markerPaintsCapitalStarForTesting(String cityId) =>
      _markers[cityId]?.debugSnapshot.paintsCapitalStar ?? false;

  bool markerPaintsSelectedLabelBorderForTesting(String cityId) =>
      _markers[cityId]?.debugSnapshot.paintsSelectedCityLabelBorder ?? false;

  bool markerPaintsStoredArtifactBadgeForTesting(String cityId) =>
      _markers[cityId]?.debugSnapshot.paintsStoredArtifactBadge ?? false;

  double markerCityLabelPulseForTesting(String cityId) =>
      _markers[cityId]?.debugSnapshot.cityLabelPulse ?? 0;

  bool markerReduceMotionForTesting(String cityId) =>
      _markers[cityId]?.visualState.reduceMotion ?? false;

  double? markerWorldScaleForTesting(String cityId) =>
      _markers[cityId]?.visualState.markerWorldScale;

  int? markerColorValueForTesting(String cityId) =>
      _markers[cityId]?.visualState.colorValue;

  bool markerHasAmbientFloatForTesting(String cityId) =>
      _markers[cityId]?.debugSnapshot.hasAmbientFloat ?? false;

  int? markerPriorityForTesting(String cityId) => _markers[cityId]?.priority;

  void retainPendingAnimationMarkers(Set<String> cityIds) {
    _retainedAnimationCityIds.addAll(cityIds);
  }

  void releasePendingAnimationMarkers(Set<String> cityIds) {
    _retainedAnimationCityIds.removeAll(cityIds);
  }

  void setLabelVisibility(bool visible) {
    for (final marker in _markers.values) {
      marker.applyVisualState(marker.visualState.copyWith(showLabel: visible));
    }
  }

  void sync({
    required Component parent,
    required Iterable<GameCity> cities,
    required String? selectedCityId,
    Map<String, double> healthFractions = const {},
    bool showLabels = true,
    Set<String> citiesWithStoredArtifacts = const {},
    ResearchState research = ResearchState.empty,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    ensureAttachedTo(parent);
    final owner = attachedOwner;
    final knownCities = cities.toList(growable: false);
    final capitalCityIds = _capitalCityIds(knownCities);
    final cityIds = knownCities.map((city) => city.id).toSet();
    for (final entry in _markers.entries.toList()) {
      if (cityIds.contains(entry.key)) continue;
      if (_retainedAnimationCityIds.contains(entry.key)) continue;
      entry.value.removeFromParent();
      _markers.remove(entry.key);
    }

    for (final city in knownCities) {
      if (_retainedAnimationCityIds.contains(city.id) &&
          _markers.containsKey(city.id)) {
        continue;
      }
      final position = _cityWorldPosition(city);
      final selected = city.id == selectedCityId;
      final healthFraction = healthFractions[city.id] ?? 1.0;
      final isCapital = capitalCityIds.contains(city.id);
      final hasStoredArtifact = citiesWithStoredArtifacts.contains(city.id);
      final visualLevel = _visualLevelFor(city);
      final technologyProfile = _technologyProfileFor(
        city,
        research: research,
        technologyRuleset: technologyRuleset,
      );
      final visualState = CityMarkerVisualState(
        worldPosition: Offset(position.x, position.y),
        colorValue: colorForPlayer(city.ownerPlayerId),
        name: city.name,
        population: city.population,
        showLabel: showLabels,
        showHealthBar: _showHealthBar,
        isCapital: isCapital,
        selected: selected,
        hasStoredArtifact: hasStoredArtifact,
        visualLevel: visualLevel,
        technologyProfile: technologyProfile,
        healthFraction: healthFraction,
        markerWorldScale: _markerWorldScale,
        reduceMotion: _reduceMotion,
      );
      final marker = _markers[city.id];
      if (marker == null) {
        final created = CityMarker.withVisualState(
          visualState: visualState,
          onTap: () => onCityTapped?.call(city),
        )..priority = _priorityFor(city);
        _markers[city.id] = created;
        unawaited(Future<void>.value(owner.add(created)));
      } else {
        marker
          ..applyVisualState(visualState)
          ..onTap = () {
            onCityTapped?.call(city);
          }
          ..priority = _priorityFor(city);
      }
    }
  }

  @override
  void onRemove() {
    for (final marker in _markers.values) {
      marker.removeFromParent();
    }
    _markers.clear();
    _retainedAnimationCityIds.clear();
    super.onRemove();
  }

  Vector2 _cityWorldPosition(GameCity city) {
    return worldPositionFor(city.center.col, city.center.row);
  }

  Set<String> _capitalCityIds(List<GameCity> cities) {
    final seenOwners = <String>{};
    final capitalIds = <String>{};
    for (final city in cities) {
      if (!seenOwners.add(city.capitalOwnerPlayerId)) continue;
      capitalIds.add(city.id);
    }
    return capitalIds;
  }

  static Vector2 worldPositionFor(int col, int row) {
    final hexRadius = MapConfig.defaultConfig.hexRadius;
    final tileCenter = HexGeometry.tilePosition(
      col: col,
      row: row,
      hexRadius: hexRadius,
    );
    final topFaceCenterY =
        (tileCenter.y + HexTileMetrics.topCenterAnchorOffsetY(hexRadius)) *
        HexGrid.perspectiveY;
    return Vector2(tileCenter.x, topFaceCenterY);
  }

  int _priorityFor(GameCity city) => MapPriority.perTile(
    MapPriority.city,
    col: city.center.col,
    row: city.center.row,
  );

  int _visualLevelFor(GameCity city) {
    if (city.population >= 14) return 5;
    if (city.population >= 10) return 4;
    if (city.population >= 8) return 3;
    if (city.population >= 6) return 2;
    if (city.population >= 4) return 1;
    return 0;
  }

  CitySpriteTechnologyProfile _technologyProfileFor(
    GameCity city, {
    required ResearchState research,
    required TechnologyRuleset technologyRuleset,
  }) {
    final scores = {
      for (final profile in CitySpriteTechnologyProfile.values) profile: 0,
    };
    final playerResearch = research.forPlayer(city.ownerPlayerId);
    for (final technologyId in playerResearch.unlockedTechnologyIds) {
      final profile = _profileForTechnology(technologyId);
      final technology = technologyRuleset.technologies[technologyId];
      final weight = 1 + (technology?.treePosition.column ?? 0);
      scores[profile] = scores[profile]! + weight;
    }

    var bestProfile = CitySpriteTechnologyProfile.growthCivic;
    var bestScore = 0;
    for (final profile in CitySpriteTechnologyProfile.values) {
      final score = scores[profile]!;
      if (score <= bestScore) continue;
      bestProfile = profile;
      bestScore = score;
    }
    return bestProfile;
  }

  CitySpriteTechnologyProfile _profileForTechnology(TechnologyId id) {
    return switch (id) {
      TechnologyId.agriculture ||
      TechnologyId.animalHusbandry ||
      TechnologyId.storage ||
      TechnologyId.waterEngineering ||
      TechnologyId.irrigation ||
      TechnologyId.construction ||
      TechnologyId.medicine ||
      TechnologyId.administration ||
      TechnologyId.civilService ||
      TechnologyId.law ||
      TechnologyId.urbanPlanning ||
      TechnologyId.bureaucracy ||
      TechnologyId.specialization ||
      TechnologyId.urbanization => CitySpriteTechnologyProfile.growthCivic,
      TechnologyId.trade ||
      TechnologyId.writing ||
      TechnologyId.advancedTrade ||
      TechnologyId.banking ||
      TechnologyId.economy ||
      TechnologyId.education ||
      TechnologyId.mathematics ||
      TechnologyId.scientificMethod ||
      TechnologyId.fishing ||
      TechnologyId.navigation ||
      TechnologyId.shipbuilding ||
      TechnologyId.cartography ||
      TechnologyId.navalDoctrine =>
        CitySpriteTechnologyProfile.tradeKnowledgeMaritime,
      TechnologyId.hunting ||
      TechnologyId.militaryOrganization ||
      TechnologyId.horsebackRiding ||
      TechnologyId.logistics ||
      TechnologyId.tactics ||
      TechnologyId.fortifications ||
      TechnologyId.siegecraft ||
      TechnologyId.strategy ||
      TechnologyId.nationalism => CitySpriteTechnologyProfile.militaryFortified,
      TechnologyId.mining ||
      TechnologyId.woodworking ||
      TechnologyId.craftsmanship ||
      TechnologyId.stoneworking ||
      TechnologyId.metallurgy ||
      TechnologyId.engineering ||
      TechnologyId.guilds ||
      TechnologyId.ironWorking ||
      TechnologyId.coalMining ||
      TechnologyId.machinery ||
      TechnologyId.steel ||
      TechnologyId.steamPower ||
      TechnologyId.electricity ||
      TechnologyId.combustion ||
      TechnologyId.flight ||
      TechnologyId.massProduction ||
      TechnologyId.radio ||
      TechnologyId.nuclearPhysics => CitySpriteTechnologyProfile.industryModern,
    };
  }
}
