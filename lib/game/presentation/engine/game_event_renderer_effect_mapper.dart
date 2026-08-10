import 'package:aonw/game/application/services/game_event_descriptor.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/artifact_event_renderer_effect_mapper.dart';
import 'package:aonw/game/presentation/engine/domain_event_animation_policy.dart';
import 'package:aonw/game/presentation/engine/game_camera_effect_normalizer.dart';
import 'package:aonw/game/presentation/engine/game_event_renderer_combat_effects.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/services/map_focus_visibility.dart';
import 'package:aonw/game/presentation/widgets/theme/player_color_theme.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/city/field_improvement_catalog.dart';
import 'package:aonw_core/game/domain/city/field_improvement_type.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';

part 'fortification_threat_renderer_effect_mapper.dart';
part 'game_event_renderer_city_effects.dart';
part 'game_event_renderer_unit_status_effects.dart';
part 'game_event_renderer_visibility.dart';
part 'unit_movement_renderer_effect_mapper.dart';

typedef _S = GameClientState;

const Duration _combatResultCueDelay = Duration(milliseconds: 180);
const int _damageTextColor = 0xFFF87171;
const int _combatCueColor = 0xFFFBBF24;

abstract final class GameEventRendererEffectMapper {
  static List<RendererEffect> effectsFor({
    required Iterable<GameEvent> events,
    required GameClientState state,
    GameClientState? previousState,
    Set<String> skipUnitMoveIds = const {},
    AppLocalizations? l10n,
    String? viewerPlayerId,
    int? turn,
    Iterable<CombatAnimationFact> combatAnimations = const [],
  }) => _effectsForEvents(
    events: events,
    state: state,
    previousState: previousState,
    skipUnitMoveIds: skipUnitMoveIds,
    l10n: l10n,
    viewerPlayerId: viewerPlayerId,
    turn: turn,
    combatAnimations: combatAnimations,
  );

  static List<RendererEffect> _effectsForEvent(
    GameEvent event,
    GameClientState state,
    GameClientState? previousState, {
    required Set<String> skipUnitMoveIds,
    AppLocalizations? l10n,
    String? viewerPlayerId,
    int? turn,
    CombatAnimationFact? combatAnimation,
  }) {
    return switch (GameEventDescriptor.forEvent(event).rendererEffectKind) {
      GameEventRendererEffectKind.unitMoved => unitMovementRendererEffects(
        event as UnitMovedEvent,
        skipUnitMoveIds,
      ),
      GameEventRendererEffectKind.fortifiedUnitThreatened =>
        fortificationThreatRendererEffects(
          state,
          event as FortifiedUnitThreatenedEvent,
          previousState: previousState,
          viewerPlayerId: viewerPlayerId,
        ),
      GameEventRendererEffectKind.cityFounded => _single(
        _cityFoundedEffect(
          state,
          (event as CityFoundedEvent).cityId,
          event.ownerPlayerId,
          viewerPlayerId: viewerPlayerId,
        ),
      ),
      GameEventRendererEffectKind.cityProducedUnit => _single(
        _cityProducedUnitEffect(
          state,
          (event as CityProducedUnitEvent).cityId,
          viewerPlayerId: viewerPlayerId,
        ),
      ),
      GameEventRendererEffectKind.cityClaimedHex => _single(
        _claimedHexEffect(
          state,
          (event as CityClaimedHexEvent).cityId,
          event.col,
          event.row,
          viewerPlayerId: viewerPlayerId,
        ),
      ),
      GameEventRendererEffectKind.unitKilled => _unitKilledEffects(
        state,
        previousState,
        (event as UnitKilledEvent).unitId,
        event.ownerPlayerId,
        viewerPlayerId: viewerPlayerId,
      ),
      GameEventRendererEffectKind.unitRetreated =>
        _canRenderTransientAt(
              state,
              (event as UnitRetreatedEvent).toCol,
              event.toRow,
              viewerPlayerId: viewerPlayerId,
            )
            ? [
                ShowFloatingTextEffect(
                  text: l10n?.modeBannerAttackRetreatProgress ?? '↩',
                  col: event.toCol,
                  row: event.toRow,
                  colorValue: _combatCueColor,
                  delay: _combatResultCueDelay,
                ),
              ]
            : const [],
      GameEventRendererEffectKind.combatResolved =>
        GameEventRendererCombatEffects.combatResolvedEffects(
          state,
          previousState,
          event as CombatResolvedEvent,
          viewerPlayerId: viewerPlayerId,
          turn: turn,
          animationFact: combatAnimation,
        ),
      GameEventRendererEffectKind.workerCompletedJob => _single(
        _workerCompletedJobEffect(
          state,
          previousState,
          (event as WorkerCompletedJobEvent).unitId,
          l10n: l10n,
          viewerPlayerId: viewerPlayerId,
        ),
      ),
      GameEventRendererEffectKind.technologyResearched => _single(
        _technologyResearchedEffect(
          state,
          (event as TechnologyResearchedEvent).playerId,
          viewerPlayerId: viewerPlayerId,
        ),
      ),
      GameEventRendererEffectKind.none => const [],
    };
  }

  static List<RendererEffect> _single(RendererEffect? effect) {
    return effect == null ? const [] : [effect];
  }
}

List<RendererEffect> rendererEffectsForEvent({
  required GameEvent event,
  required GameClientState state,
  GameClientState? previousState,
  AppLocalizations? l10n,
  String? viewerPlayerId,
  int? turn,
  CombatAnimationFact? combatAnimation,
}) {
  final policy = DomainEventAnimationPolicy.forEvent(event);
  if (!policy.hasRendererEffects) return const [];
  if (event is ArtifactLifecycleEvent) {
    return ArtifactEventRendererEffectMapper.effectsFor(
      event,
      state,
      l10n: l10n,
      viewerPlayerId: viewerPlayerId,
    );
  }
  return GameEventRendererEffectMapper._effectsForEvent(
    event,
    state,
    previousState,
    skipUnitMoveIds: const {},
    l10n: l10n,
    viewerPlayerId: viewerPlayerId,
    turn: turn,
    combatAnimation: combatAnimation,
  );
}

List<RendererEffect> _effectsForEvents({
  required Iterable<GameEvent> events,
  required GameClientState state,
  required GameClientState? previousState,
  required Set<String> skipUnitMoveIds,
  required AppLocalizations? l10n,
  required String? viewerPlayerId,
  required int? turn,
  required Iterable<CombatAnimationFact> combatAnimations,
}) {
  final effects = <RendererEffect>[];
  final combatByEventIndex = {
    for (final fact in combatAnimations) fact.eventIndex: fact,
  };
  var eventIndex = 0;
  for (final event in events) {
    effects.addAll(
      event is ArtifactLifecycleEvent
          ? ArtifactEventRendererEffectMapper.effectsFor(
              event,
              state,
              l10n: l10n,
              viewerPlayerId: viewerPlayerId,
            )
          : GameEventRendererEffectMapper._effectsForEvent(
              event,
              state,
              previousState,
              skipUnitMoveIds: skipUnitMoveIds,
              l10n: l10n,
              viewerPlayerId: viewerPlayerId,
              turn: turn,
              combatAnimation: combatByEventIndex[eventIndex],
            ),
    );
    eventIndex += 1;
  }
  return effects;
}
