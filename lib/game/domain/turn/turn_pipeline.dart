import 'package:aonw/game/domain/turn/phases/advance_turn_phase.dart';
import 'package:aonw/game/domain/turn/phases/artifact_processing_phase.dart';
import 'package:aonw/game/domain/turn/phases/city_founding_processing_phase.dart';
import 'package:aonw/game/domain/turn/phases/city_processing_phase.dart';
import 'package:aonw/game/domain/turn/phases/combat_resolution_phase.dart';
import 'package:aonw/game/domain/turn/phases/cultural_victory_progress_phase.dart';
import 'package:aonw/game/domain/turn/phases/fog_recompute_phase.dart';
import 'package:aonw/game/domain/turn/phases/research_processing_phase.dart';
import 'package:aonw/game/domain/turn/phases/selection_refresh_phase.dart';
import 'package:aonw/game/domain/turn/phases/stability_processing_phase.dart';
import 'package:aonw/game/domain/turn/phases/turn_ended_phase.dart';
import 'package:aonw/game/domain/turn/phases/worker_processing_phase.dart';
import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/game/domain/turn/turn_phase.dart';
import 'package:aonw/game/domain/turn/turn_result.dart';
import 'package:aonw_core/game/domain/fog.dart';

class TurnPipeline {
  final List<TurnPhase> phases;

  const TurnPipeline({required this.phases});

  factory TurnPipeline.playerEndTurn({
    FogOfWarService fogOfWarService = const FogOfWarService(),
  }) {
    return TurnPipeline(
      phases: [
        const CityProcessingPhase(),
        const ResearchProcessingPhase(),
        const WorkerProcessingPhase(),
        const CityFoundingProcessingPhase(),
        const ArtifactProcessingPhase(),
        const StabilityProcessingPhase(),
        FogRecomputePhase(fogOfWarService: fogOfWarService),
        const CulturalVictoryProgressPhase(),
        const SelectionRefreshPhase(),
        const TurnEndedPhase(),
        const AdvanceTurnPhase(),
      ],
    );
  }

  factory TurnPipeline.simultaneousTurn({
    FogOfWarService fogOfWarService = const FogOfWarService(),
  }) {
    return TurnPipeline(
      phases: [
        const CombatResolutionPhase(),
        const CityProcessingPhase(),
        const ResearchProcessingPhase(),
        const WorkerProcessingPhase(),
        const CityFoundingProcessingPhase(),
        const ArtifactProcessingPhase(),
        const StabilityProcessingPhase(),
        FogRecomputePhase(fogOfWarService: fogOfWarService),
        const CulturalVictoryProgressPhase(),
        const SelectionRefreshPhase(),
        const TurnEndedPhase(),
        const AdvanceTurnPhase(),
      ],
    );
  }

  TurnResult run(TurnContext initial) {
    var context = initial;
    for (final phase in phases) {
      context = phase.apply(context);
    }
    return TurnResult(
      state: context.state,
      save: context.save,
      events: List.unmodifiable(context.events),
      uiEffects: List.unmodifiable(context.uiEffects),
    );
  }
}
