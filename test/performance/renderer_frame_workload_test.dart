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
    expect(
      results.map((result) => result.stable['paintedTilesPerFrame']),
      rendererFrameWorkloadScales,
    );
    expect(
      results.map((result) => result.stable['totalPaintedTiles']),
      rendererFrameWorkloadScales,
    );
    expect(
      results.map((result) => result.stable['scenarioDigest']).toList(),
      const [
        'ee2b24c466d24535381175b727468bf4d6381365ba6e365a82759d7f856f08b4',
        '10d078faabf1b20b0c7f715401cc0cc103626eb7f6cc79512786c83ac2243fc2',
        '89717b263d78b572612b2ed5fef1d6a75b7b1ba6076b4fc304d49c2b4a8e0544',
      ],
    );
    for (final result in results) {
      expect(result.stable['assetMode'], rendererAssetMode);
      expect(
        result.stable['referenceProfileBudget'],
        rendererReferenceProfileBudget,
      );
      expect(result.stable['warmupFrames'], 0);
      expect(result.stable['sampleFrames'], 1);
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
