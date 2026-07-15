import 'ai_mcts_workload.dart';
import 'ai_strategy_workload.dart';
import 'document.dart';
import 'map_workload.dart';
import 'persistence_workload.dart';
import 'renderer_frame_workload.dart';
import 'replay_workload.dart';
import 'report_builder.dart';

Future<PerformanceReportDocument> runPerformanceSuite() async {
  final persistence = await runPersistenceWorkload();
  final replay = await runReplayWorkload();
  return buildPerformanceReport([
    runAiMctsWorkload(),
    runAiStrategyWorkload(),
    runMapLookupWorkload(),
    runWorldMapLookupWorkload(),
    persistence,
    ...runRendererFrameWorkloads(),
    replay,
  ]);
}
