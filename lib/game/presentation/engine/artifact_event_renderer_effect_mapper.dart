import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/services/map_focus_visibility.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/event.dart';

abstract final class ArtifactEventRendererEffectMapper {
  static const _color = 0xFFFFD166;
  static const _textDelay = Duration(milliseconds: 120);

  static List<RendererEffect> effectsFor(
    ArtifactLifecycleEvent event,
    GameClientState state, {
    AppLocalizations? l10n,
    String? viewerPlayerId,
  }) {
    if (viewerPlayerId != null &&
        viewerPlayerId.isNotEmpty &&
        viewerPlayerId != event.ownerPlayerId) {
      return const [];
    }
    if (!MapFocusVisibility.canRenderTransientAt(
      state,
      event.col,
      event.row,
      viewerPlayerId: viewerPlayerId,
    )) {
      return const [];
    }
    final text = switch (event) {
      ArtifactExcavationStartedEvent() =>
        l10n?.worldArtifactStepExcavate ?? 'Excavate',
      ArtifactCarriedEvent() =>
        l10n?.artifactGuidanceCarriedTitle ?? 'Artifact carried',
      ArtifactStoredEvent() =>
        l10n?.artifactGuidanceStoredTitle ?? 'Artifact stored',
    };
    final anchor = switch (event) {
      ArtifactExcavationStartedEvent(:final unitId) ||
      ArtifactCarriedEvent(:final unitId) =>
        unitId == null
            ? const FloatingTextAnchor.tile()
            : FloatingTextAnchor.unit(unitId),
      ArtifactStoredEvent(:final cityId) => FloatingTextAnchor.city(cityId),
    };
    return [
      SpawnParticleBurstEffect(
        kind: ParticleBurstKind.technologyResearched,
        col: event.col,
        row: event.row,
        colorValue: _color,
      ),
      ShowFloatingTextEffect(
        text: text,
        col: event.col,
        row: event.row,
        colorValue: _color,
        delay: _textDelay,
        presentation: FloatingTextPresentation.bubble,
        anchor: anchor,
      ),
    ];
  }
}
