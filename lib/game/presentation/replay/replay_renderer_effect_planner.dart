import 'package:aonw/game/application/services/queued_movement_effect_builder.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_renderer_effect_sequence_builder.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/event.dart';

abstract final class ReplayRendererEffectPlanner {
  static const int _artifactCueColor = 0xFFFFD166;
  static const Duration _artifactTextDelay = Duration(milliseconds: 120);

  static List<RendererEffect> effectsForStep({
    required Iterable<RendererEffect> commandEffects,
    required Iterable<GameEvent> events,
    required GameState state,
    required GameState previousState,
    AppLocalizations? l10n,
  }) {
    final replayCommandEffects = [
      ...commandEffects,
      ..._missingMovementEffects(
        commandEffects: commandEffects,
        state: state,
        previousState: previousState,
      ),
      ..._artifactStateEffects(
        state: state,
        previousState: previousState,
        l10n: l10n,
      ),
    ];
    return GameRendererEffectSequenceBuilder.build(
      commandEffects: replayCommandEffects,
      events: events,
      state: state,
      previousState: previousState,
      l10n: l10n,
    );
  }

  static bool hasPerspectiveVisibleEffect({
    required Iterable<RendererEffect> effects,
    required GameState state,
    required GameState previousState,
    required String? perspectivePlayerId,
  }) {
    if (hasPerspectiveVisibleMovement(
      effects: effects,
      state: state,
      previousState: previousState,
      perspectivePlayerId: perspectivePlayerId,
    )) {
      return true;
    }
    for (final effect in effects) {
      switch (effect) {
        case ShowFloatingTextEffect(:final col, :final row) ||
            SpawnParticleBurstEffect(:final col, :final row) ||
            ShowCityProductionBubbleEffect(:final col, :final row) ||
            ShowCombatHexAlertEffect(:final col, :final row) ||
            JumpCameraEffect(:final col, :final row) ||
            SmoothCameraEffect(:final col, :final row):
          if (_canSeeEffectAt(
            col,
            row,
            state: state,
            previousState: previousState,
            perspectivePlayerId: perspectivePlayerId,
          )) {
            return true;
          }
        case AnimateUnitMoveEffect() ||
            PlayCombatAnimationEffect() ||
            ShakeCameraEffect():
          break;
      }
    }
    return false;
  }

  static bool hasPerspectiveVisibleMovement({
    required Iterable<RendererEffect> effects,
    required GameState state,
    required GameState previousState,
    required String? perspectivePlayerId,
  }) {
    final perspective = perspectivePlayerId;
    for (final effect in effects.whereType<AnimateUnitMoveEffect>()) {
      if (perspective == null || perspective.isEmpty) return true;

      final unit =
          state.unitById(effect.unitId) ??
          previousState.unitById(effect.unitId);
      if (unit?.ownerPlayerId == perspective) return true;

      if (_canSeeMovement(effect, previousState) ||
          _canSeeMovement(effect, state)) {
        return true;
      }
    }
    return false;
  }

  static List<RendererEffect> _artifactStateEffects({
    required GameState state,
    required GameState previousState,
    AppLocalizations? l10n,
  }) {
    if (state.artifacts.isEmpty || previousState.artifacts.isEmpty) {
      return const [];
    }
    final previousById = {
      for (final artifact in previousState.artifacts) artifact.id: artifact,
    };
    final effects = <RendererEffect>[];
    for (final artifact in state.artifacts) {
      final previous = previousById[artifact.id];
      if (previous == null || previous.location == artifact.location) {
        continue;
      }
      final cue = _artifactCueForTransition(
        previous: previous,
        artifact: artifact,
        state: state,
        previousState: previousState,
        l10n: l10n,
      );
      if (cue == null) continue;
      effects.addAll(_artifactCueEffects(cue));
    }
    return effects;
  }

  static _ArtifactCue? _artifactCueForTransition({
    required WorldArtifact previous,
    required WorldArtifact artifact,
    required GameState state,
    required GameState previousState,
    AppLocalizations? l10n,
  }) {
    final previousLocation = previous.location;
    final location = artifact.location;
    if (previousLocation.isOnMap && location.isBeingExcavated) {
      return _ArtifactCue(
        text: l10n?.worldArtifactStepExcavate ?? 'Excavate',
        col: location.col ?? previousLocation.col ?? 0,
        row: location.row ?? previousLocation.row ?? 0,
      );
    }

    if (!previousLocation.isCarried && location.isCarried) {
      final unit =
          state.unitById(location.unitId ?? '') ??
          previousState.unitById(location.unitId ?? '');
      return _ArtifactCue(
        text: l10n?.artifactGuidanceCarriedTitle ?? 'Artifact carried',
        col: unit?.col ?? previousLocation.col ?? 0,
        row: unit?.row ?? previousLocation.row ?? 0,
      );
    }

    final movedIntoStorage =
        !previousLocation.isStored && location.isStored ||
        previousLocation.isStored &&
            location.isStored &&
            previousLocation.cityId != location.cityId;
    if (movedIntoStorage) {
      final city =
          state.cityById(location.cityId ?? '') ??
          previousState.cityById(location.cityId ?? '');
      final unit = previousLocation.unitId == null
          ? null
          : previousState.unitById(previousLocation.unitId!);
      return _ArtifactCue(
        text: l10n?.artifactGuidanceStoredTitle ?? 'Artifact stored',
        col: city?.center.col ?? unit?.col ?? 0,
        row: city?.center.row ?? unit?.row ?? 0,
      );
    }

    return null;
  }

  static List<RendererEffect> _artifactCueEffects(_ArtifactCue cue) {
    return [
      SpawnParticleBurstEffect(
        kind: ParticleBurstKind.technologyResearched,
        col: cue.col,
        row: cue.row,
        colorValue: _artifactCueColor,
      ),
      ShowFloatingTextEffect(
        text: cue.text,
        col: cue.col,
        row: cue.row,
        colorValue: _artifactCueColor,
        delay: _artifactTextDelay,
        presentation: FloatingTextPresentation.bubble,
      ),
    ];
  }

  static List<AnimateUnitMoveEffect> _missingMovementEffects({
    required Iterable<RendererEffect> commandEffects,
    required GameState state,
    required GameState previousState,
  }) {
    final animatedUnitIds = {
      for (final effect in commandEffects.whereType<AnimateUnitMoveEffect>())
        effect.unitId,
    };
    if (animatedUnitIds.length == state.units.length) {
      return const [];
    }

    return [
      for (final effect in QueuedMovementEffectBuilder.fromUnitDelta(
        beforeUnits: previousState.units,
        afterUnits: state.units,
      ))
        if (!animatedUnitIds.contains(effect.unitId)) effect,
    ];
  }

  static bool _canSeeMovement(AnimateUnitMoveEffect effect, GameState state) {
    if (_canSeeDynamicAt(state, effect.fromCol, effect.fromRow)) return true;
    for (final step in effect.steps) {
      if (_canSeeDynamicAt(state, step.col, step.row)) return true;
    }
    return false;
  }

  static bool _canSeeEffectAt(
    int col,
    int row, {
    required GameState state,
    required GameState previousState,
    required String? perspectivePlayerId,
  }) {
    if (perspectivePlayerId == null || perspectivePlayerId.isEmpty) {
      return true;
    }
    return _canSeeDynamicAt(previousState, col, row) ||
        _canSeeDynamicAt(state, col, row);
  }

  static bool _canSeeDynamicAt(GameState state, int col, int row) {
    final visibility = state.activePlayerVisibility;
    if (!visibility.isEnabled ||
        !state.fogOfWar.playerIds.contains(visibility.playerId)) {
      return true;
    }
    return visibility.canSeeDynamicAt(col, row);
  }
}

class _ArtifactCue {
  const _ArtifactCue({
    required this.text,
    required this.col,
    required this.row,
  });

  final String text;
  final int col;
  final int row;
}
