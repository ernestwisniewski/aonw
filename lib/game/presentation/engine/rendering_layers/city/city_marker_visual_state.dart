import 'dart:math' as math;
import 'dart:ui';

import 'package:aonw/game/presentation/engine/rendering_layers/city/city_sprite_catalog.dart';
import 'package:flutter/foundation.dart';

@immutable
final class CityMarkerVisualState {
  final Offset worldPosition;
  final int colorValue;
  final String name;
  final int population;
  final bool showLabel;
  final bool showHealthBar;
  final bool isCapital;
  final bool selected;
  final int visualLevel;
  final CitySpriteTechnologyProfile technologyProfile;
  final double healthFraction;
  final bool hasStoredArtifact;
  final double markerWorldScale;
  final bool reduceMotion;

  factory CityMarkerVisualState({
    required Offset worldPosition,
    required int colorValue,
    String name = '',
    int population = 1,
    bool showLabel = true,
    bool showHealthBar = true,
    bool isCapital = false,
    bool selected = false,
    int visualLevel = 0,
    CitySpriteTechnologyProfile technologyProfile =
        CitySpriteTechnologyProfile.growthCivic,
    double healthFraction = 1.0,
    bool hasStoredArtifact = false,
    double markerWorldScale = 1.0,
    bool reduceMotion = false,
  }) {
    return CityMarkerVisualState._(
      worldPosition: worldPosition,
      colorValue: colorValue,
      name: name,
      population: math.max(1, population),
      showLabel: showLabel,
      showHealthBar: showHealthBar,
      isCapital: isCapital,
      selected: selected,
      visualLevel: visualLevel,
      technologyProfile: technologyProfile,
      healthFraction: healthFraction.clamp(0.0, 1.0).toDouble(),
      hasStoredArtifact: hasStoredArtifact,
      markerWorldScale: _normalizeMarkerWorldScale(markerWorldScale),
      reduceMotion: reduceMotion,
    );
  }

  const CityMarkerVisualState._({
    required this.worldPosition,
    required this.colorValue,
    required this.name,
    required this.population,
    required this.showLabel,
    required this.showHealthBar,
    required this.isCapital,
    required this.selected,
    required this.visualLevel,
    required this.technologyProfile,
    required this.healthFraction,
    required this.hasStoredArtifact,
    required this.markerWorldScale,
    required this.reduceMotion,
  });

  CityMarkerVisualState copyWith({
    Offset? worldPosition,
    int? colorValue,
    String? name,
    int? population,
    bool? showLabel,
    bool? showHealthBar,
    bool? isCapital,
    bool? selected,
    int? visualLevel,
    CitySpriteTechnologyProfile? technologyProfile,
    double? healthFraction,
    bool? hasStoredArtifact,
    double? markerWorldScale,
    bool? reduceMotion,
  }) {
    return CityMarkerVisualState(
      worldPosition: worldPosition ?? this.worldPosition,
      colorValue: colorValue ?? this.colorValue,
      name: name ?? this.name,
      population: population ?? this.population,
      showLabel: showLabel ?? this.showLabel,
      showHealthBar: showHealthBar ?? this.showHealthBar,
      isCapital: isCapital ?? this.isCapital,
      selected: selected ?? this.selected,
      visualLevel: visualLevel ?? this.visualLevel,
      technologyProfile: technologyProfile ?? this.technologyProfile,
      healthFraction: healthFraction ?? this.healthFraction,
      hasStoredArtifact: hasStoredArtifact ?? this.hasStoredArtifact,
      markerWorldScale: markerWorldScale ?? this.markerWorldScale,
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }
}

double _normalizeMarkerWorldScale(double value) =>
    value.isFinite ? value.clamp(1.0, 3.0).toDouble() : 1.0;
