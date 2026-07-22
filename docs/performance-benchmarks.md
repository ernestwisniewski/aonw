# Performance Benchmarks

The performance harness protects the shape of expensive work before the map
and state refactor changes its implementation. Portable CI checks deterministic
work counters and output fingerprints. Wall-clock measurements remain useful
diagnostics, but are not treated as portable evidence of a regression.

## Workload Contract

Every workload uses generated, deterministic fixtures and runs outside normal
game saves. Fixture construction and warm-up happen before measured operations
where the workload permits it.

| Area | Scales | Scenario |
| --- | --- | --- |
| Map lookup | 100, 1,000, and 10,000 tiles | resolve the first, middle, and last tile plus a missing coordinate through legacy `MapData` and the indexed `WorldMapReadView`; record actual list reads for the legacy model, the canonical index size, direct `WorldTile` hits and public lookup calls, plus matching output digests |
| Movement path | 100, 1,000, and 10,000 tiles | plan the same three-hex path through `WorldMapReadView`; record logical lookups and unique tile coordinates read, which must remain constant as the surrounding map grows |
| Movement command | 100, 1,000, and 10,000 tiles | resolve the same authoritative move through the neutral kernel and the Persistent/Domain adapters; record accepted boundaries, executed steps, fog recomputation paths, diplomatic contact, tile lookups, and a shared output digest |
| Auto-explore | 100, 1,000, and 10,000 tiles | plan a scout destination across a fully reachable `WorldMap`; record every evaluated destination and unique tile coordinate read so the intentional full-map growth remains visible |
| Persistence | 100, 1,000, and 10,000 records | run `JsonEventLog.latestOffset`, `readSince`, and `append`, then exercise snapshot codec round trips at the same scales |
| Replay | 100, 1,000, and 10,000 events | replay a deterministic four-command mix through the real reducer and record yielded commands, offsets, steps, and the resulting state digest |
| AI | 100, 1,000, and 10,000 iterations | run both the isolated MCTS search and production `MctsStrategy` planning path with an exact iteration budget; record work structure and selected-command fingerprints |
| Renderer | 100, 600, and 1,000 tiles | paint a deterministic `HexGrid` headlessly after warm-up and record the rendered work shape and scenario digest |

MCTS iteration budgets are exact: the search must complete the requested number
of iterations and must not stop because a runner happened to be slower. The
headless renderer workload measures repeatable `HexGrid.renderTree` work; it is
not a substitute for Flutter `FrameTiming` collected from a real device.
Canonical workloads perform warm-up before collecting 21 timing samples, so a
p95 summary is not merely the slowest value from a three- or nine-sample run.

## Stable Results and Observations

Each case produces two independent sections:

- `stable` contains deterministic counters, dimensions, offsets, iteration
  counts, work totals, and canonical SHA-256 digests. CI compares these values
  exactly with the reviewed baseline.
- `observations` contains wall-clock samples and summaries such as median and
  p95 duration. They help compare local runs and investigate changes, but do
  not fail the portable gate on shared runners.

This separation prevents VM warm-up, host load, CPU scheduling, and CI hardware
from turning timing noise into flaky failures. A stable-value change still
requires review: it can represent an optimization, a regression in work
complexity, or an intentional workload-contract change.

`map.world-lookup` constructs and warms the immutable coordinate index before
measurement. Its stable counters describe the indexed tile count, three direct
`WorldTile` hits, and four public `WorldMapReadView.tileAt` calls; they do not
pretend to instrument private hash-table reads. The legacy `MapData` case
remains until that model is removed, so the gate makes the linear-to-indexed
migration visible without timing-based CI.

`map.movement-path` holds the source and destination coordinates fixed while
the surrounding map grows. Its lookup and unique-coordinate counters are
therefore a bounded-work invariant: a larger unrelated map must not expand the
search. `map.movement-command` extends that invariant across the complete
command boundary: kernel, both state adapters, incremental fog recomputation,
diplomatic-contact discovery, events, and renderer-neutral execution must keep
the same work counters and output digest as the unrelated map grows.
`map.auto-explore` has a different contract. It deliberately evaluates every
reachable destination, so `candidateEvaluations` grows from `scale - 1` and
`uniqueTileHits` grows with the map. The stable
`growthModel: full-reachable-map` marker documents that proportional scan and
prevents it from being mistaken for the fixed-distance movement budget. Its
timed path executes the complete neutral auto-explore command resolver; a
separate instrumented planner pass retains the stable candidate and lookup
counters without mixing them with movement, fog, and diplomacy reads.

The report, baseline, and policy are schema-versioned canonical JSON documents:

- the report contains `schemaVersion`, `stable`, and `observations`;
- the baseline contains only `schemaVersion` and `stable`;
- the policy contains `schemaVersion` and a sorted, unique `requiredCases`
  list.

Canonical encoding makes the files byte-for-byte reproducible. The gate
requires the report and baseline case sets to match the policy exactly, then
compares the complete `stable` trees. Unknown, missing, or changed stable data
fails the check; observation changes do not.

## Commands

Generate a complete canonical report:

```sh
make performance-report
```

Generate the report and run the portable structural gate against the committed
baseline and policy:

```sh
make performance-check
```

Extract a candidate baseline from a generated report without changing the
committed baseline:

```sh
make performance-snapshot
```

The report defaults to `/tmp/aonw-performance-report.json`, and the candidate
snapshot defaults to `/tmp/aonw-performance-baseline.json`. Override either
path when retaining or comparing artifacts:

```sh
make performance-report \
  PERFORMANCE_REPORT_PATH=build/performance/report.json

make performance-snapshot \
  PERFORMANCE_REPORT_PATH=build/performance/report.json \
  PERFORMANCE_SNAPSHOT_PATH=build/performance/baseline.json
```

Do not commit generated reports. Only the reviewed baseline and policy belong
in version control.

## Reference-Profile Frame Budget

Real frame timings have a separate 60 FPS acceptance contract:

| Metric | Budget |
| --- | ---: |
| Total frame p95 | <= 16.67 ms |
| Total frame p99 | <= 33.3 ms |
| Frames slower than 16.67 ms | <= 1% |
| UI/build p95 | <= 8 ms |
| Raster p95 | <= 8 ms |
| Flame update p95 | <= 2 ms |
| Render submission p95 | <= 4 ms |

These budgets may be enforced only by a profile build on a pinned reference
device with a controlled scenario and collection protocol. They are not a
portable CI gate and must not be applied to headless runs or shared CI runners.
Portable CI continues to gate deterministic renderer counters and fingerprints
while publishing timing observations for diagnosis.

### Collection protocol

The repository provides the validator, not a synthetic source of device
timings. A release or performance operator must produce the report from a real
run with all of the following conditions:

1. Use the designated, physically pinned reference device. Keep its OS version,
   power mode, refresh rate, and thermal conditions controlled, and identify it
   with the same stable, non-empty `deviceId` on every run. Pass that expected
   ID separately to the gate; a report cannot select its own trusted device.
2. Install and run a Flutter **profile** build. Preload and render the normal
   bundled assets; debug, release, headless, and fallback-asset runs are invalid
   inputs to this gate.
3. Run the controlled `renderer.frame.1000` scenario. Complete warm-up before
   collection, then retain at least 600 consecutive measured frames.
4. Derive total-frame, UI/build, and raster samples from Flutter `FrameTiming`
   (`totalSpan`, `buildDuration`, and `rasterDuration`). Measure Flame update and
   render submission around the corresponding production loop boundaries, not
   around the headless benchmark.
5. For p95 and p99, sort the retained samples and use the nearest-rank value
   (`ceil(percentile * sampleFrames)`, one-based). Compute slow-frame basis
   points as `slowFrameCount * 10000 / sampleFrames`, using 16,667 microseconds
   as the slow-frame threshold.
6. Archive the raw samples and environmental record beside the generated JSON
   so a failed percentile can be audited. The gate consumes only the aggregate
   report and cannot prove that an external collector followed this protocol.

No passing example report is committed, because fabricated timing numbers would
look like device evidence. The collector must emit all required measurements;
the validator never fills in missing values or converts headless observations
into profile-device metrics.

### Report format

The report is a JSON object with exactly three root fields. Unknown or missing
fields, wrong types, non-finite or negative metrics, and inconsistent total-frame
percentiles are rejected before budgets are evaluated.

| JSON path | Type | Required value or meaning |
| --- | --- | --- |
| `schemaVersion` | integer | exactly `1` |
| `metadata.buildMode` | string | exactly `profile` |
| `metadata.deviceId` | string | non-empty, trimmed pinned-device identifier |
| `metadata.scenario` | string | exactly `renderer.frame.1000` |
| `metadata.assetMode` | string | exactly `bundled-assets` |
| `metadata.sampleFrames` | integer | at least `600`, excluding warm-up |
| `metrics.totalFrame.p95Micros` | number | measured total-frame p95 |
| `metrics.totalFrame.p99Micros` | number | measured total-frame p99; must be at least p95 |
| `metrics.slowFrames.thresholdMicros` | integer | exactly `16667` |
| `metrics.slowFrames.count` | integer | measured slow-frame count, from `0` through `sampleFrames`; the gate derives basis points |
| `metrics.uiBuild.p95Micros` | number | measured Flutter UI/build p95 |
| `metrics.raster.p95Micros` | number | measured Flutter raster p95 |
| `metrics.flameUpdate.p95Micros` | number | measured Flame update p95 |
| `metrics.renderSubmission.p95Micros` | number | measured production render-submission p95 |

`metadata` must contain exactly the five fields listed above. `metrics` must
contain exactly `totalFrame`, `slowFrames`, `uiBuild`, `raster`, `flameUpdate`,
and `renderSubmission`, with only the nested fields shown in the table.

### Running the device gate

Point the explicit manual target at the report collected from the pinned device:

```sh
make performance-frame-check \
  PERFORMANCE_FRAME_REPORT_PATH=/absolute/path/to/reference-frame-report.json \
  PERFORMANCE_FRAME_DEVICE_ID=pixel-8-pro-reference-01
```

The equivalent direct command is:

```sh
dart run tool/check_frame_budget.dart \
  --report /absolute/path/to/reference-frame-report.json \
  --device-id pixel-8-pro-reference-01
```

The command validates provenance metadata and requires the report `deviceId` to
match the separately supplied pinned-device ID. It then evaluates all seven
metric budgets and reports every exceeded metric in one failure. It is
intentionally not a dependency of `performance-check`, `ci`, or portable
GitHub Actions.

## Updating the Baseline

Update the committed baseline only after review confirms either a real
improvement or an intentional change to the workload contract:

1. Generate a fresh report and reproduce the stable diff.
2. Explain every changed counter, fingerprint, case, or scale in the review.
3. Generate a candidate with `make performance-snapshot`; do not overwrite the
   committed baseline as part of the benchmark run.
4. Review workload code, policy changes, and the candidate baseline together.
5. Replace the committed baseline only after approval, then rerun
   `make performance-check` from a clean checkout.

Never accept a baseline update solely because the gate failed. Timing-only
movement belongs in observations and does not justify a baseline change.
