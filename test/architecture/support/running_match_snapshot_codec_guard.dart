part of '../running_match_snapshot_codec_boundary_test.dart';

List<String> _codecBoundaryViolations(
  CompilationUnit codecUnit,
  CompilationUnit decoderUnit,
) => [
  ..._codecShapeViolations(codecUnit, decoderUnit),
  ..._runningDecodeFlowViolations(codecUnit),
  ..._losslessDecodeFlowViolations(decoderUnit),
  ..._encodeFlowViolations(codecUnit),
  ..._canonicalEncodeFlowViolations(codecUnit),
  ..._losslessConversionFlowViolations(decoderUnit),
  ..._rawCanonicalPatchFlowViolations(codecUnit),
];
