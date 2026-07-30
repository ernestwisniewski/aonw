import 'coverage_failure.dart';

const _commonPolicyKeys = {
  'schema',
  'enforcedSince',
  'diffLineMinimumBasisPoints',
  'excludeSuffixes',
  'scopes',
};

Set<String> coveragePolicyKeysForSchema(int schema, String description) =>
    switch (schema) {
      1 => _commonPolicyKeys,
      2 => {..._commonPolicyKeys, 'ratchetEpoch'},
      _ => throw CoverageFailure('$description: unsupported schema $schema.'),
    };

int readCoverageRatchetEpoch(Object? value, int schema, String description) {
  final epoch = schema == 1 ? 0 : value;
  if (epoch is int && epoch >= 0) return epoch;
  throw CoverageFailure('$description.ratchetEpoch must be non-negative.');
}

bool validateCoverageRatchetEpoch(int oldEpoch, int currentEpoch) {
  if (currentEpoch < oldEpoch) {
    throw CoverageFailure(
      'Coverage ratchet epoch cannot decrease: $oldEpoch -> $currentEpoch.',
    );
  }
  if (currentEpoch > oldEpoch + 1) {
    throw CoverageFailure(
      'Coverage ratchet epoch may only advance by one: '
      '$oldEpoch -> $currentEpoch.',
    );
  }
  return currentEpoch > oldEpoch;
}

bool validateHistoricalCoveragePolicy({
  required String oldAnchor,
  required String currentAnchor,
  required int oldEpoch,
  required int currentEpoch,
  required String oldStructure,
  required String currentStructure,
  required int oldDiffMinimum,
  required int currentDiffMinimum,
  required String oldDiffMinimumPercent,
  required String currentDiffMinimumPercent,
}) {
  if (oldAnchor != currentAnchor) {
    throw const CoverageFailure(
      'coverage_policy.json enforcedSince is immutable.',
    );
  }
  final epochAdvanced = validateCoverageRatchetEpoch(oldEpoch, currentEpoch);
  if (oldStructure != currentStructure) {
    throw const CoverageFailure(
      'Coverage scope, layer, and exclusion policy is immutable after the '
      'rollout anchor.',
    );
  }
  if (currentDiffMinimum < oldDiffMinimum) {
    throw CoverageFailure(
      'Diff coverage minimum cannot decrease: '
      '$oldDiffMinimumPercent -> $currentDiffMinimumPercent.',
    );
  }
  return epochAdvanced;
}
