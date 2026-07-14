const rendererTargetFps = 60;
const rendererFrameBudgetMicros = 16667;
const rendererFrameP99BudgetMicros = 33300;
const rendererMaxSlowFramesBasisPoints = 100;
const rendererUiBuildBudgetMicros = 8000;
const rendererRasterBudgetMicros = 8000;
const rendererFlameUpdateBudgetMicros = 2000;
const rendererRenderSubmissionBudgetMicros = 4000;

const rendererReferenceBuildMode = 'profile';
const rendererReferenceScenario = 'renderer.frame.1000';
const rendererReferenceAssetMode = 'bundled-assets';
const rendererReferenceMinimumSampleFrames = 600;

const rendererReferenceProfileBudget = <String, Object?>{
  'targetFps': rendererTargetFps,
  'totalFrame': {
    'p95Micros': rendererFrameBudgetMicros,
    'p99Micros': rendererFrameP99BudgetMicros,
  },
  'slowFrames': {
    'thresholdMicros': rendererFrameBudgetMicros,
    'maxBasisPoints': rendererMaxSlowFramesBasisPoints,
  },
  'uiBuild': {'p95Micros': rendererUiBuildBudgetMicros},
  'raster': {'p95Micros': rendererRasterBudgetMicros},
  'flameUpdate': {'p95Micros': rendererFlameUpdateBudgetMicros},
  'renderSubmission': {'p95Micros': rendererRenderSubmissionBudgetMicros},
};
