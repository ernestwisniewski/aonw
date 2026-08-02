import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/artifacts/artifact_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_founding_preview_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_management_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_territory_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/cloud_drift_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/combat_hex_alert_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/era_tint_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/floating_text_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/particle_effects_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/improvements/field_improvement_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map/hover_intent_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/overlays/fog_of_war_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/overlays/threat_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_move_preview_layer.dart';
import 'package:aonw/game/presentation/engine/unit_animation_controller.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/rendering/map_objective_marker_layer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/objective.dart';

/// Stable bundle of visual layers constructed before the Flame world loads.
final class GameRendererComponents {
  GameRendererComponents({
    required WorldMap mapData,
    required bool reduceMotion,
    required int Function(String playerId) colorForPlayer,
    required void Function(String unitId) onUnitTapped,
    required void Function(WorldArtifact artifact) onArtifactTapped,
    required void Function(MapObjectiveProgress progress) onObjectiveTapped,
    required void Function(GameCity city) onCityTapped,
    required ActionPaletteWorkerOptionCallback onPreviewWorkerImprovement,
    required ActionPaletteWorkerCallback onConfirmWorkerImprovement,
    required ActionPaletteWorkerCallback onCancelWorkerActionSelection,
    required ActionPaletteMovePreviewCallback onConfirmMovePreview,
    AppLocalizations? l10n,
  }) {
    final turnCostLabelBuilder = l10n == null
        ? null
        : (int count) => l10n.turnCountLabel(count);
    final confirmationLabelBuilder = l10n == null
        ? null
        : (int count) =>
              l10n.selectionActionConfirmWithTurns(l10n.turnCountLabel(count));

    unitMarkers = UnitMarkerLayer(
      mapData: mapData,
      colorForPlayer: colorForPlayer,
      onUnitTapped: onUnitTapped,
      reduceMotion: reduceMotion,
    );
    movePreview = UnitMovePreviewLayer(
      turnCostLabelBuilder: turnCostLabelBuilder,
      confirmationLabelBuilder: confirmationLabelBuilder,
      confirmationLabel: l10n?.selectionActionConfirm,
    );
    fieldImprovements = FieldImprovementMarkerLayer();
    artifacts = ArtifactMarkerLayer(onArtifactTapped: onArtifactTapped);
    mapObjectives = MapObjectiveMarkerLayer(
      colorForPlayer: colorForPlayer,
      onObjectiveTapped: onObjectiveTapped,
    );
    cities = CityMarkerLayer(
      colorForPlayer: colorForPlayer,
      onCityTapped: onCityTapped,
      reduceMotion: reduceMotion,
    );
    cityTerritory = CityTerritoryOverlayLayer(colorForPlayer: colorForPlayer);
    eraTint = EraTintOverlayLayer();
    cityManagement = CityManagementOverlayLayer();
    cityFounding = CityFoundingPreviewLayer(colorForPlayer: colorForPlayer);
    fogOfWar = FogOfWarOverlayLayer();
    particles = ParticleEffectsLayer();
    cityProductionParticles = CityProductionParticleLayer(
      reduceMotion: reduceMotion,
    );
    cloudDrift = CloudDriftLayer(reduceMotion: reduceMotion);
    floatingText = FloatingTextLayer(
      reduceMotion: reduceMotion,
      unitPositionFor: unitMarkers.worldPositionForUnit,
    );
    combatAlerts = CombatHexAlertLayer();
    threats = ThreatOverlayLayer();
    hoverIntent = HoverIntentMarkerLayer();
    actionPalette = ActionPaletteLayer(
      onPreviewWorkerImprovement: onPreviewWorkerImprovement,
      onConfirmWorkerImprovement: onConfirmWorkerImprovement,
      onCancelWorkerActionSelection: onCancelWorkerActionSelection,
      onConfirmMovePreview: onConfirmMovePreview,
      turnCostLabelBuilder: turnCostLabelBuilder,
      confirmationLabelBuilder: confirmationLabelBuilder,
      confirmationLabel: l10n?.selectionActionConfirm,
    );
    unitAnimations = UnitAnimationController(unitMarkers);
  }

  late final UnitMarkerLayer unitMarkers;
  late final UnitMovePreviewLayer movePreview;
  late final FieldImprovementMarkerLayer fieldImprovements;
  late final ArtifactMarkerLayer artifacts;
  late final MapObjectiveMarkerLayer mapObjectives;
  late final CityMarkerLayer cities;
  late final CityTerritoryOverlayLayer cityTerritory;
  late final EraTintOverlayLayer eraTint;
  late final CityManagementOverlayLayer cityManagement;
  late final CityFoundingPreviewLayer cityFounding;
  late final FogOfWarOverlayLayer fogOfWar;
  late final ParticleEffectsLayer particles;
  late final CityProductionParticleLayer cityProductionParticles;
  late final CloudDriftLayer cloudDrift;
  late final FloatingTextLayer floatingText;
  late final CombatHexAlertLayer combatAlerts;
  late final ThreatOverlayLayer threats;
  late final HoverIntentMarkerLayer hoverIntent;
  late final ActionPaletteLayer actionPalette;
  late final UnitAnimationController unitAnimations;
}
