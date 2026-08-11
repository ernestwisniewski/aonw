import 'package:aonw_core/game/domain/event.dart';

enum DomainEventAnimationKind { rendererEffects, noAnimation }

/// The exhaustive, reviewable presentation policy for every domain event.
///
/// Adding a concrete [GameEvent] requires adding exactly one branch here. The
/// architecture inventory verifies that this switch and the deterministic
/// parity corpus remain complete.
final class DomainEventAnimationPolicy {
  const DomainEventAnimationPolicy._(this.kind, this.reviewReason);

  const DomainEventAnimationPolicy.effects(String reviewReason)
    : this._(DomainEventAnimationKind.rendererEffects, reviewReason);

  const DomainEventAnimationPolicy.none(String reviewReason)
    : this._(DomainEventAnimationKind.noAnimation, reviewReason);

  final DomainEventAnimationKind kind;
  final String reviewReason;

  bool get hasRendererEffects =>
      kind == DomainEventAnimationKind.rendererEffects;

  static const byEventType = <Type, DomainEventAnimationPolicy>{
    ArtifactExcavationStartedEvent: .effects('artifact excavation cue'),
    ArtifactCarriedEvent: .effects('artifact carried cue'),
    ArtifactStoredEvent: .effects('artifact storage cue'),
    CityFoundedEvent: .effects('city founding burst'),
    CityBuiltBuildingEvent: .none('persistent city state renders the building'),
    CityBuiltWonderEvent: .none('persistent city state renders the wonder'),
    WonderProductionRefundedEvent: .none('notification-only economy outcome'),
    CityProducedUnitEvent: .effects('city production burst'),
    CityClaimedHexEvent: .effects('claimed-hex burst'),
    UnitMovedEvent: .effects(
      'movement animation requires authoritative movement evidence',
    ),
    FortifiedUnitThreatenedEvent: .effects(
      'visible-enemy threat markers without idle camera focus',
    ),
    UnitGainedExperienceEvent: .none(
      'persistent unit state renders experience',
    ),
    UnitAttackedEvent: .none('CombatResolvedEvent owns the combat sequence'),
    CityAttackedEvent: .none('CombatResolvedEvent owns the combat sequence'),
    CombatResolvedEvent: .effects('combat, camera and result cues'),
    UnitKilledEvent: .effects('visible death cue'),
    UnitRetreatedEvent: .effects('visible retreat cue after combat'),
    CityCapturedEvent: .none('persistent city state renders ownership'),
    CityDestroyedEvent: .none('persistent world state removes the city'),
    TurnEndedEvent: .none('turn lifecycle has no transient map effect'),
    WorkerCompletedJobEvent: .effects('visible improvement completion cue'),
    DominationThresholdReachedEvent: .none(
      'notification-only victory progress',
    ),
    StabilityBandChangedEvent: .none('notification-only stability outcome'),
    ResearchPointsGainedEvent: .none(
      'persistent research state renders points',
    ),
    TechnologyResearchedEvent: .effects('visible research completion cue'),
    StrategicResourceDiscoveredEvent: .none(
      'notification and map-state update',
    ),
    MapObjectiveSecuredEvent: .none('notification and objective-state update'),
    CivilizationMetEvent: .none('diplomacy popup and notification own the UI'),
    DiplomaticProposalSentEvent: .none('diplomacy popup owns the UI'),
    DiplomaticProposalRespondedEvent: .none('diplomacy popup owns the UI'),
    DiplomaticProposalExpiredEvent: .none('notification-only expiry'),
    DiplomaticRelationChangedEvent: .none('diplomacy state and notification'),
    DiplomaticMessageSentEvent: .none('diplomacy popup owns the UI'),
    DiplomaticMessageRespondedEvent: .none('diplomacy popup owns the UI'),
    DiplomaticScoreChangedEvent: .none(
      'persistent diplomacy state renders score',
    ),
    DiplomaticPromiseBrokenEvent: .none('notification-only diplomatic outcome'),
    CommandRejectedEvent: .none('HUD feedback is interaction presentation'),
    AllPlayersSubmittedEvent: .none('turn lifecycle status is state-driven'),
    PlayerTimedOutEvent: .none('notification-only system outcome'),
    TurnAutoResolvedEvent: .none('notification-only system outcome'),
    PlayerKickedEvent: .none('lobby and notification state own the UI'),
  };

  static DomainEventAnimationPolicy forEvent(GameEvent event) {
    final policy = byEventType[event.runtimeType];
    if (policy != null) return policy;
    throw StateError('Missing animation policy for ${event.runtimeType}.');
  }
}
