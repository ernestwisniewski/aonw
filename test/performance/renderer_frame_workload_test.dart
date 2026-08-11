import 'package:flutter_test/flutter_test.dart';

import '../../tool/performance/frame_budget_policy.dart';
import '../../tool/performance/renderer_frame_workload.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('paints deterministic renderer workloads without timing gates', () {
    final results = runRendererFrameWorkloads(warmupFrames: 0, sampleFrames: 1);

    expect(results.map((result) => result.name), [
      'renderer.frame.100',
      'renderer.frame.600',
      'renderer.frame.1000',
    ]);
    final paintedCounts = results
        .map((result) => result.stable['paintedTilesPerFrame']! as int)
        .toList();
    expect(
      paintedCounts.first,
      lessThanOrEqualTo(rendererFrameWorkloadScales.first),
    );
    expect(paintedCounts[1], lessThan(rendererFrameWorkloadScales[1]));
    expect(paintedCounts[2], lessThan(rendererFrameWorkloadScales[2]));
    expect(paintedCounts[2], lessThanOrEqualTo(paintedCounts[1]));
    expect(
      results.map((result) => result.stable['totalPaintedTiles']),
      paintedCounts,
    );
    for (final result in results) {
      expect(result.stable['assetMode'], rendererAssetMode);
      expect(
        result.stable['referenceProfileBudget'],
        rendererReferenceProfileBudget,
      );
      expect(result.stable['warmupFrames'], 0);
      expect(result.stable['sampleFrames'], 1);
      expect(result.stable['viewport'], {
        'width': rendererReferenceViewport.width,
        'height': rendererReferenceViewport.height,
      });
      expect(result.stable['scenarioDigest'], hasLength(64));
      expect(result.observations['portableTimingGateEnabled'], isFalse);
      expect(result.observations['timingPolicy'], 'diagnostic_only');
      expect(
        result.observations['headlessRenderTreeTiming'],
        allOf(
          containsPair('samples', 1),
          contains('medianMicros'),
          contains('p95Micros'),
          contains('maxMicros'),
          containsPair(
            'diagnosticReferenceBudgetMicros',
            rendererRenderSubmissionBudgetMicros,
          ),
          contains('samplesOverDiagnosticReferenceBudget'),
        ),
      );
      expect(result.observations, isNot(contains('frameTiming')));
    }
  });

  test('exposes the complete machine-readable reference profile budget', () {
    expect(rendererReferenceProfileBudget, {
      'targetFps': 60,
      'totalFrame': {'p95Micros': 16667, 'p99Micros': 33300},
      'slowFrames': {'thresholdMicros': 16667, 'maxBasisPoints': 100},
      'uiBuild': {'p95Micros': 8000},
      'raster': {'p95Micros': 8000},
      'flameUpdate': {'p95Micros': 2000},
      'renderSubmission': {'p95Micros': 4000},
    });
  });

  test('rejects unsupported scale and invalid sample counts', () {
    expect(() => runRendererFrameWorkload(scale: 101), throwsArgumentError);
    expect(
      () => runRendererFrameWorkload(scale: 100, warmupFrames: -1),
      throwsArgumentError,
    );
    expect(
      () => runRendererFrameWorkload(scale: 100, sampleFrames: 0),
      throwsArgumentError,
    );
  });
}
