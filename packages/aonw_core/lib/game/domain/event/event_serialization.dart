import 'package:aonw_core/game/domain/event/artifact_event_serialization.dart';
import 'package:aonw_core/game/domain/event/city_event_serialization.dart';
import 'package:aonw_core/game/domain/event/combat_event_serialization.dart';
import 'package:aonw_core/game/domain/event/diplomacy_event_serialization.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/event/progress_event_serialization.dart';
import 'package:aonw_core/game/domain/event/system_event_serialization.dart';
import 'package:aonw_core/game/domain/event/unit_event_serialization.dart';
import 'package:aonw_core/util/wire_json.dart';

/// Stable serialization boundary for authoritative game events.
///
/// Event-family codecs own the wire details of their respective subdomains.
/// This facade remains exhaustive so adding a new [GameEvent] cannot silently
/// skip serialization support.
abstract final class GameEventSerializer {
  static Map<String, dynamic> toJson(GameEvent event) {
    return switch (event) {
      WorldEntityLifecycleEvent() => ArtifactEventSerializer.toJson(event),
      UnitPresentationEvent() => UnitEventSerializer.toJson(event),
      CityBuiltBuildingEvent() => CityEventSerializer.toJson(event),
      CityBuiltWonderEvent() => CityEventSerializer.toJson(event),
      WonderProductionRefundedEvent() => CityEventSerializer.toJson(event),
      CityProducedUnitEvent() => CityEventSerializer.toJson(event),
      CityClaimedHexEvent() => CityEventSerializer.toJson(event),
      UnitAttackedEvent() => CombatEventSerializer.toJson(event),
      CombatResolvedEvent() => CombatEventSerializer.toJson(event),
      UnitKilledEvent() => CombatEventSerializer.toJson(event),
      UnitRetreatedEvent() => CombatEventSerializer.toJson(event),
      CityAttackedEvent() => CombatEventSerializer.toJson(event),
      CityCapturedEvent() => CombatEventSerializer.toJson(event),
      CityDestroyedEvent() => CombatEventSerializer.toJson(event),
      TurnEndedEvent() => ProgressEventSerializer.toJson(event),
      StabilityBandChangedEvent() => ProgressEventSerializer.toJson(event),
      WorkerCompletedJobEvent() => ProgressEventSerializer.toJson(event),
      DominationThresholdReachedEvent() => ProgressEventSerializer.toJson(
        event,
      ),
      ResearchPointsGainedEvent() => ProgressEventSerializer.toJson(event),
      TechnologyResearchedEvent() => ProgressEventSerializer.toJson(event),
      StrategicResourceDiscoveredEvent() => ProgressEventSerializer.toJson(
        event,
      ),
      MapObjectiveSecuredEvent() => ProgressEventSerializer.toJson(event),
      CivilizationMetEvent() => DiplomacyEventSerializer.toJson(event),
      DiplomaticProposalSentEvent() => DiplomacyEventSerializer.toJson(event),
      DiplomaticProposalRespondedEvent() => DiplomacyEventSerializer.toJson(
        event,
      ),
      DiplomaticProposalExpiredEvent() => DiplomacyEventSerializer.toJson(
        event,
      ),
      DiplomaticRelationChangedEvent() => DiplomacyEventSerializer.toJson(
        event,
      ),
      DiplomaticMessageSentEvent() => DiplomacyEventSerializer.toJson(event),
      DiplomaticMessageRespondedEvent() => DiplomacyEventSerializer.toJson(
        event,
      ),
      DiplomaticScoreChangedEvent() => DiplomacyEventSerializer.toJson(event),
      DiplomaticPromiseBrokenEvent() => DiplomacyEventSerializer.toJson(event),
      CommandRejectedEvent() => SystemEventSerializer.toJson(event),
      AllPlayersSubmittedEvent() => SystemEventSerializer.toJson(event),
      PlayerTimedOutEvent() => SystemEventSerializer.toJson(event),
      TurnAutoResolvedEvent() => SystemEventSerializer.toJson(event),
      PlayerKickedEvent() => SystemEventSerializer.toJson(event),
    };
  }

  static GameEvent fromJson(Map<String, dynamic> json) {
    final event = tryFromJson(json);
    if (event == null) {
      throw ArgumentError('Unknown GameEvent type: ${json['type']}');
    }
    return event;
  }

  static GameEvent? tryFromJson(Map<String, dynamic> json) {
    final type = requiredStringField(json, 'GameEvent', 'type');
    return ArtifactEventSerializer.tryFromJson(json, type) ??
        UnitEventSerializer.tryFromJson(json, type) ??
        CityEventSerializer.tryFromJson(json, type) ??
        CombatEventSerializer.tryFromJson(json, type) ??
        ProgressEventSerializer.tryFromJson(json, type) ??
        DiplomacyEventSerializer.tryFromJson(json, type) ??
        SystemEventSerializer.tryFromJson(json, type);
  }
}
