import 'ai_mcts_workload.dart';
import 'ai_strategy_workload.dart';
import 'combat_command_workload.dart';
import 'document.dart';
import 'map_workload.dart';
import 'movement_command_workload.dart';
import 'persistence_workload.dart';
import 'renderer_frame_workload.dart';
import 'replay_workload.dart';
import 'report_builder.dart';
import 'turn_finalization_workload.dart';

Future<PerformanceReportDocument> runPerformanceSuite() async {
  final persistence = await runPersistenceWorkload();
  final replay = await runReplayWorkload();
  return buildPerformanceReport([
    runAiMctsWorkload(),
    runAiStrategyWorkload(),
    runAutoExploreWorkload(),
    runCombatCommandWorkload(),
    runFogRevealWorkload(),
    runMapLookupWorkload(),
    runMovementCommandWorkload(),
    runMovementPathWorkload(),
    runWorldMapLookupWorkload(),
    persistence,
    ...runRendererFrameWorkloads(),
    replay,
    runTurnFinalizationWorkload(),
  ]);
}
