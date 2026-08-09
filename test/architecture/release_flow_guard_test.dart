import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release/options.dart';

void main() {
  final makefile = File('Makefile').readAsStringSync();
  final docs = File('docs/build-and-deploy.md').readAsStringSync();
  final webIndex = File('web/index.html').readAsStringSync();

  test('web shell loads the Apple sign-in SDK', () {
    const appleSdk =
        'https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/'
        'en_US/appleid.auth.js';
    expect(webIndex, contains(appleSdk));
    expect(makefile, contains('rg -F "$appleSdk" build/web/index.html'));
  });

  test('public release options have one documented default registry', () {
    expect(releaseOptions, hasLength(17));
    for (final option in releaseOptions) {
      expect(
        makefile,
        contains(
          '${option.name} ?='
          '${option.defaultValue.isEmpty ? '' : ' ${option.defaultValue}'}',
        ),
        reason: 'Make default drifted for ${option.name}',
      );
      expect(makefile, contains(option.name));
      final docsRow = docs
          .split('\n')
          .singleWhere((line) => line.startsWith('| `${option.name}` |'));
      final documentedDefault = option.defaultValue.isEmpty
          ? '| empty |'
          : '| `${option.defaultValue}` |';
      expect(
        docsRow,
        contains(documentedDefault),
        reason: 'Docs default drifted for ${option.name}',
      );
      for (final value in option.allowedValues.split('|')) {
        final documented = value == 'integer>current'
            ? 'integer greater than current'
            : value;
        expect(
          docsRow,
          contains(documented),
          reason: 'Docs enum drifted for ${option.name}: $value',
        );
      }
    }
  });

  test('deploy-all-plan delegates only to the read-only Dart planner', () {
    final plan = _targetBody(
      makefile,
      target: 'deploy-all-plan',
      nextTarget: 'deploy-all-preflight',
    );

    expect(plan, contains('dart tool/release/deploy_all_plan.dart'));
    for (final option in releaseOptions) {
      expect(plan, contains(option.name), reason: option.name);
    }
    for (final forbidden in [
      'git ',
      'ssh ',
      'flutter ',
      r'$(MAKE) --no-print-directory release-check',
      r'$(MAKE) --no-print-directory bump-version',
    ]) {
      expect(plan, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test(
    'planner implementation has no filesystem, process, or network action',
    () {
      final sources = Directory('tool/release')
          .listSync()
          .whereType<File>()
          .map((file) => file.readAsStringSync())
          .join('\n');
      for (final forbidden in [
        'Process.',
        'File(',
        'Directory(',
        'HttpClient(',
        'Socket.',
      ]) {
        expect(sources, isNot(contains(forbidden)), reason: forbidden);
      }
    },
  );

  test('every external store action is strict opt-in', () {
    expect(makefile, contains('DEPLOY_ALL_STEAMWORKS ?= 0'));
    expect(makefile, contains('DEPLOY_ALL_GOOGLE_PLAY ?= 0'));
    expect(makefile, contains('DEPLOY_ALL_ITCH ?= 0'));
    final deployAll = _deployAllBody(makefile);
    expect(deployAll, contains(r'[ "$(DEPLOY_ALL_ITCH)" = "1" ]'));
    expect(deployAll, isNot(contains(r'[ -n "$(ITCH_TARGET)" ]')));
  });

  test(
    'release gates precede push and backend precedes client publication',
    () {
      final deployAll = _deployAllBody(makefile);
      final gates = RegExp(
        r'\$\(MAKE\) --no-print-directory release-check',
      ).allMatches(deployAll).toList();
      final preflight = deployAll.indexOf(
        r'$(MAKE) --no-print-directory deploy-all-preflight',
      );
      final bump = deployAll.indexOf(
        r'$(MAKE) --no-print-directory bump-version',
      );
      final push = deployAll.indexOf('git push origin main');
      final prepare = deployAll.indexOf(r'$(MAKE) --no-print-directory steam ');
      final backend = deployAll.indexOf('make deploy PROFILE=');
      final backendHealth = deployAll.indexOf(
        r'$(MAKE) --no-print-directory health',
        backend,
      );
      final steamUpload = deployAll.indexOf(
        r'$(MAKE) --no-print-directory steam-upload',
      );
      final googlePlay = deployAll.indexOf(
        r'$(MAKE) --no-print-directory android-upload',
      );
      final itch = deployAll.indexOf(
        r'$(MAKE) --no-print-directory itch-upload',
      );

      expect(gates, hasLength(2));
      expect(preflight, greaterThanOrEqualTo(0));
      expect(gates.first.start, greaterThan(preflight));
      expect(bump, greaterThan(gates.first.start));
      expect(gates.last.start, greaterThan(bump));
      expect(push, greaterThan(gates.last.start));
      expect(prepare, greaterThan(push));
      expect(backend, greaterThan(prepare));
      expect(backendHealth, greaterThan(backend));
      expect(steamUpload, greaterThan(backendHealth));
      expect(googlePlay, greaterThan(backendHealth));
      expect(itch, greaterThan(backendHealth));
      expect(deployAll, isNot(contains('android-deploy')));
    },
  );

  test('failure-sensitive branches cannot continue with stale artifacts', () {
    final deployAll = _deployAllBody(makefile);
    final steamBlock = deployAll.substring(
      deployAll.indexOf('[7/13]'),
      deployAll.indexOf('[8/13]'),
    );
    expect(steamBlock, contains('@set -e;'));
    expect(
      steamBlock.indexOf('steam-upload'),
      greaterThan(steamBlock.indexOf('steam-prepare-from-dist')),
    );

    final ios = _targetBody(
      makefile,
      target: 'archive-ios-if-possible',
      nextTarget: 'android-keystore',
    );
    expect(ios, contains('off)'));
    expect(ios, contains('best-effort)'));
    expect(ios, contains('required)'));
    expect(ios, isNot(contains('archive-ios ||')));
    expect(
      makefile,
      contains('Google Play validation finished; no release was published'),
    );
  });

  test('one Linux artifact serves three independent consumers', () {
    expect(
      makefile,
      contains(
        r'DEPLOY_ALL_INCLUDE_LINUX = $(if $(filter 1,$(STEAM_INCLUDE_LINUX) $(ITCH_INCLUDE_LINUX) $(DOWNLOAD_INCLUDE_LINUX)),1,0)',
      ),
    );
    expect(makefile, contains('DOWNLOAD_INCLUDE_LINUX ?= 0'));
    expect(makefile, isNot(contains(r'DOWNLOAD_INCLUDE_LINUX ?= $(ITCH')));
  });

  test('static publication consumes prepared bytes without rebuilding', () {
    final webWrapper = _targetBody(
      makefile,
      target: 'deploy-web',
      nextTarget: 'deploy-web-files',
    );
    final webUpload = _targetBody(
      makefile,
      target: 'deploy-web-files',
      nextTarget: 'build-homepage',
    );
    final homepageWrapper = _targetBody(
      makefile,
      target: 'deploy-homepage',
      nextTarget: 'deploy-homepage-files',
    );
    final homepageUpload = _targetBody(
      makefile,
      target: 'deploy-homepage-files',
      nextTarget: 'download-artifacts',
    );

    expect(webWrapper, contains(r'$(MAKE) --no-print-directory build-web'));
    expect(
      webWrapper,
      contains(r'$(MAKE) --no-print-directory deploy-web-files'),
    );
    expect(
      homepageWrapper,
      contains(r'$(MAKE) --no-print-directory build-homepage'),
    );
    expect(
      homepageWrapper,
      contains(r'$(MAKE) --no-print-directory deploy-homepage-files'),
    );
    for (final upload in [webUpload, homepageUpload]) {
      expect(upload, contains('rsync -avz --delete'));
      expect(upload, isNot(contains('flutter build')));
      expect(upload, isNot(contains('build-web')));
      expect(upload, isNot(contains('build-homepage')));
    }
  });

  test('macOS artifacts are verified before their final ZIP exists', () {
    final macos = _targetBody(
      makefile,
      target: 'steam-macos',
      nextTarget: 'steam-windows',
    );
    final orderedSteps = [
      'xcodebuild -quiet archive',
      'xcodebuild -exportArchive',
      'codesign --verify',
      r'ditto -c -k --keepParent --norsrc --noextattr --noqtn --noacl '
          r'"$(STEAM_MACOS_APP)" "$$submission_zip"',
      'notarytool submit',
      'stapler staple',
      'stapler validate',
      'spctl --assess',
      r'ditto -c -k --keepParent --norsrc --noextattr --noqtn --noacl '
          r'"$(STEAM_MACOS_APP)" '
          r'"$(STEAM_MACOS_ZIP)"',
    ];

    var previous = -1;
    for (final step in orderedSteps) {
      final offset = macos.indexOf(step);
      expect(offset, greaterThan(previous), reason: step);
      previous = offset;
    }
    expect(macos, contains(r'--keychain-profile "$(MACOS_NOTARY_PROFILE)"'));
    expect(macos, contains(r'-exportOptionsPlist "$(MACOS_EXPORT_OPTIONS)"'));
    expect(macos, contains(r'flags=.*runtime'));
    expect(macos, contains(r'Authority=$(MACOS_DEVELOPER_IDENTITY)'));
    expect(macos, contains(r'TeamIdentifier=$(MACOS_DEVELOPMENT_TEAM)'));
    expect(macos, contains(r"rg '^Timestamp=.+$$'"));
    expect(macos, contains(r'com\.apple\.security\.network\.client'));
    expect(macos, contains('keychain-access-groups'));
    expect(macos, contains(r'com\.apple\.security\.get-task-allow'));
    expect(macos, contains('AppleDouble or __MACOSX entries'));
    expect(
      macos,
      contains(
        r'codesign --verify --deep --strict --verbose=2 "$$verification_dir/$(STEAM_MACOS_APP_NAME)"',
      ),
    );
  });

  test('macOS release builds enable the hardened runtime', () {
    final releaseConfig = File(
      'macos/Runner/Configs/Release.xcconfig',
    ).readAsStringSync();

    expect(releaseConfig, contains('ENABLE_HARDENED_RUNTIME = YES'));
  });

  test('macOS Developer ID export keeps required runtime capabilities', () {
    final entitlements = File(
      'macos/Runner/DeveloperID.entitlements',
    ).readAsStringSync();
    final exportOptions = File(
      'macos/DeveloperIDExportOptions.plist',
    ).readAsStringSync();

    expect(
      entitlements,
      contains(
        '<key>com.apple.security.network.client</key>\n'
        '\t<true/>',
      ),
    );
    expect(
      entitlements,
      contains(
        '<key>keychain-access-groups</key>\n'
        '\t<array>\n'
        '\t\t<string>\$(AppIdentifierPrefix)com.google.GIDSignIn</string>',
      ),
    );
    expect(entitlements, isNot(contains('com.apple.security.get-task-allow')));
    expect(entitlements, isNot(contains('com.apple.developer.applesignin')));
    expect(
      exportOptions,
      contains('<key>method</key>\n\t<string>developer-id</string>'),
    );
    expect(
      exportOptions,
      contains(
        '<key>signingCertificate</key>\n'
        '\t<string>Developer ID Application</string>',
      ),
    );
    expect(
      makefile,
      contains(
        r'CODE_SIGN_ENTITLEMENTS="$(CURDIR)/$(MACOS_DEVELOPER_ID_ENTITLEMENTS)"',
      ),
    );
  });

  test('deploy preflight validates macOS distribution credentials', () {
    final preflight = _targetBody(
      makefile,
      target: 'deploy-all-preflight',
      nextTarget: 'deploy-all',
    );

    expect(makefile, contains('\nmacos-distribution-preflight:'));
    expect(
      preflight,
      contains(r'$(MAKE) --no-print-directory macos-distribution-preflight'),
    );
  });

  test('Steam dispatches are bound to a clean commit and unique run', () {
    for (final target in const [
      (
        platform: 'Linux',
        target: 'steam-linux-github',
        nextTarget: 'steam-package-linux',
        workflow: '.github/workflows/linux-steam-build.yml',
      ),
      (
        platform: 'Windows',
        target: 'steam-windows-github',
        nextTarget: 'steam-package-windows',
        workflow: '.github/workflows/windows-steam-build.yml',
      ),
    ]) {
      final dispatch = _targetBody(
        makefile,
        target: target.target,
        nextTarget: target.nextTarget,
      );
      final workflow = File(target.workflow).readAsStringSync();

      expect(
        dispatch,
        contains('git status --porcelain --untracked-files=normal'),
        reason: target.platform,
      );
      expect(
        dispatch,
        contains(r'test -z "$$worktree_status"'),
        reason: target.platform,
      );
      expect(
        dispatch.indexOf(r'test -z "$$worktree_status"'),
        lessThan(dispatch.indexOf('git fetch origin')),
        reason: target.platform,
      );
      expect(
        dispatch,
        contains(r'-f source_sha="$$local_sha"'),
        reason: target.platform,
      );
      expect(
        dispatch,
        contains(r'-f dispatch_token="$$dispatch_token"'),
        reason: target.platform,
      );
      expect(
        dispatch,
        contains('databaseId,displayTitle,headSha'),
        reason: target.platform,
      );
      expect(
        dispatch,
        contains(r'contains(\"[$$dispatch_token]\")'),
        reason: target.platform,
      );
      expect(workflow, contains('run-name: >-'), reason: target.platform);
      expect(
        workflow,
        contains(r'[${{ inputs.dispatch_token }}]'),
        reason: target.platform,
      );
      expect(
        workflow,
        contains('Verify requested source identity'),
        reason: target.platform,
      );
      expect(
        workflow.indexOf('Verify requested source identity'),
        lessThan(workflow.indexOf('Set up Flutter')),
        reason: target.platform,
      );
      expect(
        workflow,
        contains(r'test "$(git rev-parse HEAD)" = "$SOURCE_SHA"'),
        reason: target.platform,
      );
      expect(
        workflow,
        contains(r'test "$committed_version" = "$BUILD_NAME+$BUILD_NUMBER"'),
        reason: target.platform,
      );
    }
  });

  test('Linux Steam container trusts its checkout before Git inspection', () {
    final workflow = File(
      '.github/workflows/linux-steam-build.yml',
    ).readAsStringSync();
    const trustWorkspace =
        r'git config --global --add safe.directory "$GITHUB_WORKSPACE"';

    expect(workflow, contains(trustWorkspace));
    expect(
      workflow.indexOf(trustWorkspace),
      lessThan(workflow.indexOf('Verify requested source identity')),
    );
  });

  test('local Linux packaging uses the workflow API scanner', () {
    final packaging = _targetBody(
      makefile,
      target: 'steam-package-linux',
      nextTarget: 'steam-prepare-from-dist',
    );
    final workflow = File(
      '.github/workflows/linux-steam-build.yml',
    ).readAsStringSync();

    expect(packaging, contains('command -v grep'));
    expect(packaging, isNot(contains('command -v rg')));
    expect(
      packaging,
      contains(r'grep -R -a -F "$(STEAM_API_BASE_URL)" "$$tmp_dir"'),
    );
    expect(
      workflow,
      contains(r'grep -R -a -F "$AONW_RELEASE_API_BASE_URL" dist/steam-linux'),
    );
  });

  test('release preflight rejects untracked release inputs', () {
    final preflight = _targetBody(
      makefile,
      target: 'preflight-release',
      nextTarget: 'serverpod-version',
    );

    expect(preflight, contains('--untracked-files=normal'));
  });
}

String _deployAllBody(String makefile) => _targetBody(
  makefile,
  target: 'deploy-all',
  nextTarget: 'preflight-release',
);

String _targetBody(
  String makefile, {
  required String target,
  required String nextTarget,
}) {
  final start = makefile.indexOf('\n$target:');
  final end = makefile.indexOf('\n$nextTarget:', start + 1);
  expect(start, greaterThanOrEqualTo(0), reason: 'Missing target $target');
  expect(end, greaterThan(start), reason: 'Missing target $nextTarget');
  return makefile.substring(start, end);
}
