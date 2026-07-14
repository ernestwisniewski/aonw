/// One public `make deploy-all` option and its stable contract.
final class ReleaseOption {
  const ReleaseOption({
    required this.name,
    required this.defaultValue,
    required this.allowedValues,
    required this.description,
  });

  final String name;
  final String defaultValue;
  final String allowedValues;
  final String description;
}

/// Canonical public option registry used by contract tests and documentation.
const releaseOptions = <ReleaseOption>[
  ReleaseOption(
    name: 'DEPLOY_ENV',
    defaultValue: 'staging',
    allowedValues: 'staging|prod',
    description: 'Backend deployment environment.',
  ),
  ReleaseOption(
    name: 'DEPLOY_ALL_IOS_MODE',
    defaultValue: 'best-effort',
    allowedValues: 'off|best-effort|required',
    description: 'iOS archive policy.',
  ),
  ReleaseOption(
    name: 'DEPLOY_ALL_STEAMWORKS',
    defaultValue: '0',
    allowedValues: '0|1',
    description: 'Enable the Steamworks upload.',
  ),
  ReleaseOption(
    name: 'DEPLOY_ALL_GOOGLE_PLAY',
    defaultValue: '0',
    allowedValues: '0|1',
    description: 'Enable the Google Play action.',
  ),
  ReleaseOption(
    name: 'DEPLOY_ALL_GOOGLE_PLAY_MODE',
    defaultValue: 'closed',
    allowedValues: 'closed|internal|alpha|beta|production',
    description: 'Google Play destination track.',
  ),
  ReleaseOption(
    name: 'DEPLOY_ALL_GOOGLE_PLAY_VALIDATE_ONLY',
    defaultValue: '0',
    allowedValues: '0|1',
    description: 'Validate the Play upload without publishing.',
  ),
  ReleaseOption(
    name: 'DEPLOY_ALL_ITCH',
    defaultValue: '0',
    allowedValues: '0|1',
    description: 'Enable itch.io uploads.',
  ),
  ReleaseOption(
    name: 'ITCH_TARGET',
    defaultValue: '',
    allowedValues: 'user/game|empty',
    description: 'Required destination when itch.io is enabled.',
  ),
  ReleaseOption(
    name: 'STEAM_INCLUDE_LINUX',
    defaultValue: '0',
    allowedValues: '0|1',
    description: 'Include Linux in the Steam depot.',
  ),
  ReleaseOption(
    name: 'ITCH_INCLUDE_LINUX',
    defaultValue: '0',
    allowedValues: '0|1',
    description: 'Include Linux in itch.io uploads.',
  ),
  ReleaseOption(
    name: 'DOWNLOAD_INCLUDE_LINUX',
    defaultValue: '0',
    allowedValues: '0|1',
    description: 'Include Linux in public downloads.',
  ),
  ReleaseOption(
    name: 'STEAM_WINDOWS_SOURCE',
    defaultValue: 'auto',
    allowedValues: 'auto|local|github|existing',
    description: 'Windows artifact source.',
  ),
  ReleaseOption(
    name: 'STEAM_LINUX_SOURCE',
    defaultValue: 'auto',
    allowedValues: 'auto|local|github|existing',
    description: 'Linux artifact source.',
  ),
  ReleaseOption(
    name: 'VERSION_BUMP',
    defaultValue: 'patch',
    allowedValues: 'patch|none',
    description: 'Marketing-version policy.',
  ),
  ReleaseOption(
    name: 'NEW_VERSION',
    defaultValue: '',
    allowedValues: 'x.y.z|empty',
    description: 'Optional marketing-version override.',
  ),
  ReleaseOption(
    name: 'NEW_BUILD',
    defaultValue: '',
    allowedValues: 'integer>current|empty',
    description: 'Optional monotonically increasing build override.',
  ),
  ReleaseOption(
    name: 'DEPLOY_ALL_PLAN_FORMAT',
    defaultValue: 'human',
    allowedValues: 'human|json|artifact-json',
    description: 'Planner output format.',
  ),
];
