import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release/manifest/manifest.dart';
import 'release_manifest_fixture.dart';

const _source = '1111111111111111111111111111111111111111';
const _imageDigest =
    '3333333333333333333333333333333333333333333333333333333333333333';
const _artifactHash =
    '4444444444444444444444444444444444444444444444444444444444444444';
const _configHash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _migrationHash =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _configRevision =
    '8dc4652d87f30639bc98705d41991473afe3007c6a9e14f8773fb4849c82656f';
const _migrationRevision =
    '7875bd356d5561bd6dfec1fea597bcbf98392aa5c0f23d061154ba76297ff345';

void main() {
  group('canonical manifest', () {
    test('matches the golden, digest, filename, and parser', () {
      final manifest = _manifest();
      final planJson = encodeCanonicalJson(artifactPlanFixture);
      final planSha = sha256Hex(utf8.encode(planJson));
      final golden =
          '{"artifactPlan":$planJson,"artifactPlanSha256":"$planSha",'
          '"artifacts":[{"bytes":42,"destinations":["google-play"],'
          '"id":"android-aab","mediaType":"application/zip",'
          '"path":"artifacts/aonw.aab","sha256":"$_artifactHash"},'
          '{"bytes":42,"destinations":["downloads","itch","steam"],'
          '"id":"desktop-macos","mediaType":"application/zip",'
          '"path":"artifacts/aonw.zip","sha256":"$_artifactHash"},'
          '{"bytes":42,"destinations":["homepage"],'
          '"id":"homepage-static","mediaType":"application/gzip",'
          '"path":"artifacts/homepage.tar.gz","sha256":"$_artifactHash"},'
          '{"bytes":42,"destinations":["ios"],"id":"ios-archive",'
          '"mediaType":"application/zip",'
          '"path":"artifacts/aonw-ios.zip","sha256":"$_artifactHash"},'
          '{"bytes":42,"destinations":["web"],"id":"web-static",'
          '"mediaType":"application/gzip","path":"artifacts/web.tar.gz",'
          '"sha256":"$_artifactHash"}],'
          '"build":77,"channels":["downloads","google-play","homepage",'
          '"ios","itch","server","steam","web"],"config":'
          '{"files":[{"bytes":10,"path":"compose.yml","sha256":'
          '"$_configHash"}],"revision":"$_configRevision"},"migrations":'
          '{"files":[{"bytes":20,"path":"migration.sql","sha256":'
          '"$_migrationHash"}],"revision":"$_migrationRevision"},'
          '"qualityGate":{"name":"release-check","sourceSha":"$_source",'
          '"status":"passed"},"schemaVersion":1,"serverImage":'
          '"registry.example/aonw/server@sha256:$_imageDigest",'
          '"sourceSha":"$_source","version":"1.2.3"}';

      expect(manifest.canonicalJson, golden);
      expect(manifest.digest, sha256Hex(utf8.encode(golden)));
      expect(manifest.fileName, '${manifest.digest}.json');
      final parsed = const ReleaseManifestParser().parseCanonical(golden);
      expect(parsed.canonicalJson, golden);
      final planChannels =
          parsed.artifactPlan.toJson()['channels']! as Map<String, Object?>;
      expect(planChannels['googlePlay'], containsPair('track', 'internal'));
      expect(
        planChannels['googlePlay'],
        containsPair('action', 'validate-only'),
      );
      expect(planChannels['itch'], containsPair('target', 'studio/game'));
      expect(planChannels['ios'], containsPair('mode', 'required'));
      expect(_manifest().canonicalJson, manifest.canonicalJson);
    });

    test('requires strictly sorted, unique arrays', () {
      expect(
        () => _manifest(
          channels: const [ReleaseChannel.server, ReleaseChannel.downloads],
        ),
        _failsContaining('strictly sorted'),
      );
      expect(
        () => ManifestArtifact(
          id: 'desktop-macos',
          path: 'a.zip',
          sha256: _artifactHash,
          bytes: 1,
          mediaType: 'application/zip',
          destinations: const [ReleaseChannel.steam, ReleaseChannel.steam],
        ),
        _failsContaining('duplicates'),
      );
      expect(
        () => ManifestFileTree(
          files: [_file('z', _configHash, 1), _file('a', _migrationHash, 2)],
        ),
        _failsContaining('strictly sorted'),
      );
      final duplicate = _artifact('artifacts/a.zip');
      expect(
        () => _manifest(artifacts: [duplicate, duplicate]),
        _failsContaining('duplicates'),
      );
      expect(
        () => _manifest(
          artifacts: [
            _artifact('artifacts/a.zip', id: 'desktop-macos'),
            _artifact('artifacts/a.zip', id: 'desktop-windows'),
          ],
        ),
        _failsContaining('artifact paths'),
      );
    });
  });

  group('strict schema', () {
    test('rejects missing, unknown, noncanonical, and duplicate-key JSON', () {
      final manifest = _manifest();
      final missing = Map<String, Object>.from(manifest.toJson())
        ..remove('version');
      final unknown = Map<String, Object>.from(manifest.toJson())
        ..['environment'] = 'prod';
      final canonical = manifest.canonicalJson;
      final duplicate = '{"artifactPlan":{},${canonical.substring(1)}';

      expect(
        () => const ReleaseManifestParser().parseCanonical(
          encodeCanonicalJson(missing),
        ),
        _failsContaining('missing: version'),
      );
      expect(
        () => const ReleaseManifestParser().parseCanonical(
          encodeCanonicalJson(unknown),
        ),
        _failsContaining('unknown: environment'),
      );
      for (final invalid in [' $canonical', '$canonical\n', duplicate]) {
        expect(
          () => const ReleaseManifestParser().parseCanonical(invalid),
          _failsContaining('not canonical'),
        );
      }
    });

    test('rejects invalid identities, image references, and paths', () {
      expect(
        () => _manifest(sourceSha: 'ABC'),
        _failsContaining('40 lowercase hex'),
      );
      expect(
        () => ArtifactPlanEvidence.fromJson(
          artifactPlanFixture,
          expectedSha256: 'abc',
        ),
        _failsContaining('mismatch'),
      );
      expect(
        () => _manifest(version: '1.2.4'),
        _failsContaining('release must match'),
      );
      final invalidPlan =
          jsonDecode(jsonEncode(artifactPlanFixture)) as Map<String, Object?>;
      final invalidChannels = invalidPlan['channels']! as Map<String, Object?>;
      final invalidGoogle =
          invalidChannels['googlePlay']! as Map<String, Object?>;
      invalidGoogle['action'] = 'surprise';
      expect(
        () => ArtifactPlanEvidence.fromJson(invalidPlan),
        _failsContaining('googlePlay.action is invalid'),
      );
      expect(
        () => ArtifactPlanEvidence.fromJson({
          ...artifactPlanFixture,
          'schemaVersion': 1.0,
        }),
        _failsContaining('schemaVersion must be 1'),
      );
      for (final image in [
        'registry.example/aonw/server:latest',
        'registry.example/aonw/server:tag@sha256:$_imageDigest',
        'registry.example/aonw/server@sha256:abc',
      ]) {
        expect(
          () => _manifest(serverImage: image),
          _failsContaining('serverImage'),
        );
      }
      for (final path in ['/absolute', '../escape', 'a/../b', r'a\b']) {
        expect(() => _file(path, _configHash, 1), _failsContaining('path'));
      }
      expect(
        () => ManifestArtifact(
          id: 'Desktop_Mac',
          path: 'a.zip',
          sha256: _artifactHash,
          bytes: 1,
          mediaType: 'application/zip',
          destinations: const [ReleaseChannel.downloads],
        ),
        _failsContaining('lowercase kebab-case'),
      );
      expect(
        () => ManifestArtifact(
          id: 'desktop-macos',
          path: 'a.zip',
          sha256: _artifactHash,
          bytes: 0,
          mediaType: 'application/zip',
          destinations: const [ReleaseChannel.downloads],
        ),
        _failsContaining('positive integer'),
      );
      final withoutSteamPlan =
          jsonDecode(jsonEncode(artifactPlanFixture)) as Map<String, Object?>;
      final withoutSteamChannels =
          withoutSteamPlan['channels']! as Map<String, Object?>;
      final disabledSteam =
          withoutSteamChannels['steam']! as Map<String, Object?>;
      disabledSteam['enabled'] = false;
      expect(
        () => _manifest(
          artifactPlanJson: withoutSteamPlan,
          channels: const [
            ReleaseChannel.downloads,
            ReleaseChannel.googlePlay,
            ReleaseChannel.homepage,
            ReleaseChannel.ios,
            ReleaseChannel.itch,
            ReleaseChannel.server,
            ReleaseChannel.web,
          ],
          artifacts: [
            ManifestArtifact(
              id: 'desktop-macos',
              path: 'artifacts/a.zip',
              sha256: _artifactHash,
              bytes: 1,
              mediaType: 'application/zip',
              destinations: const [ReleaseChannel.steam],
            ),
          ],
        ),
        _failsContaining('absent from channels'),
      );
      expect(
        () => _manifest(channels: const [ReleaseChannel.downloads]),
        _failsContaining('must include server'),
      );
      expect(
        () => _manifest(
          channels: const [
            ReleaseChannel.downloads,
            ReleaseChannel.googlePlay,
            ReleaseChannel.homepage,
            ReleaseChannel.ios,
            ReleaseChannel.itch,
            ReleaseChannel.server,
            ReleaseChannel.steam,
          ],
        ),
        _failsContaining('exactly match'),
      );
      expect(
        () => _manifest(artifacts: [_artifact('artifacts/a.zip')]),
        _failsContaining('google-play has no manifest artifact'),
      );
    });

    test('enforces the iOS artifact policy', () {
      final artifactsWithoutIos = _artifacts()
          .where(
            (artifact) => !artifact.destinations.contains(ReleaseChannel.ios),
          )
          .toList(growable: false);
      expect(
        () => _manifest(artifacts: artifactsWithoutIos),
        _failsContaining('ios has no manifest artifact'),
      );
      final bestEffortPlan =
          jsonDecode(jsonEncode(artifactPlanFixture)) as Map<String, Object?>;
      final channels = bestEffortPlan['channels']! as Map<String, Object?>;
      (channels['ios']! as Map<String, Object?>)['mode'] = 'best-effort';
      expect(
        () => _manifest(
          artifactPlanJson: bestEffortPlan,
          artifacts: artifactsWithoutIos,
        ),
        returnsNormally,
      );
    });
  });

  group('file hashing and verification', () {
    test('detects missing, tampered, and symbolic-link artifacts', () async {
      final root = await _temporaryDirectory('manifest-artifacts');
      addTearDown(() => root.deleteSync(recursive: true));
      await Directory('${root.path}/artifacts').create();
      final artifactFile = File('${root.path}/artifacts/aonw.zip');
      await artifactFile.writeAsString('release bytes');
      const hasher = ReleaseFileHasher();
      final artifact = await hasher.hashArtifact(
        root: root,
        id: 'desktop-macos',
        path: 'artifacts/aonw.zip',
        mediaType: 'application/zip',
        destinations: const [ReleaseChannel.downloads],
      );

      await hasher.verifyFiles(root: root, artifacts: [artifact]);
      await artifactFile.writeAsString('tampered');
      await expectLater(
        hasher.verifyFiles(root: root, artifacts: [artifact]),
        _failsContaining('mismatch'),
      );
      await artifactFile.delete();
      await expectLater(
        hasher.verifyFiles(root: root, artifacts: [artifact]),
        _failsContaining('Missing'),
      );
      final outside = File('${root.path}/outside')
        ..writeAsStringSync('outside');
      await Link(artifactFile.path).create(outside.path);
      await expectLater(
        hasher.hashFile(root: root, path: 'artifacts/aonw.zip'),
        _failsContaining('Symbolic links'),
      );
    });

    test('detects config and migration tree drift', () async {
      const hasher = ReleaseFileHasher();
      for (final name in ['config', 'migrations']) {
        final root = await _temporaryDirectory('manifest-$name');
        addTearDown(() => root.deleteSync(recursive: true));
        final file = File('${root.path}/a.txt')..writeAsStringSync('original');
        final tree = await hasher.hashTree(root);
        await hasher.verifyTree(root: root, expected: tree);
        file.writeAsStringSync('changed');
        await expectLater(
          hasher.verifyTree(root: root, expected: tree),
          _failsContaining('drift'),
        );
        file.writeAsStringSync('original');
        File('${root.path}/extra.txt').writeAsStringSync('extra');
        await expectLater(
          hasher.verifyTree(root: root, expected: tree),
          _failsContaining('drift'),
        );
      }
    });
  });

  test(
    'atomic store is idempotent and never overwrites different bytes',
    () async {
      final root = await _temporaryDirectory('manifest-store');
      addTearDown(() => root.deleteSync(recursive: true));
      final manifest = _manifest();
      final store = ReleaseManifestStore(root);

      final first = await store.put(manifest);
      final second = await store.put(manifest);
      expect(first.created, isTrue);
      expect(second.created, isFalse);
      expect(first.file.path, endsWith(manifest.fileName));
      expect(
        (await store.read(manifest.digest)).canonicalJson,
        manifest.canonicalJson,
      );

      await first.file.writeAsString('different');
      await expectLater(store.put(manifest), _failsContaining('Refusing'));
      await expectLater(
        store.read(manifest.digest),
        _failsContaining('Invalid manifest JSON'),
      );
      await first.file.delete();
      final outside = File('${root.path}/outside')
        ..writeAsStringSync('outside');
      await Link(first.file.path).create(outside.path);
      await expectLater(
        store.put(manifest),
        _failsContaining('not a regular file'),
      );
      await expectLater(
        store.read('../escape'),
        _failsContaining('64 lowercase hex'),
      );
    },
  );
}

ReleaseManifestV1 _manifest({
  String sourceSha = _source,
  String version = '1.2.3',
  Map<String, Object?> artifactPlanJson = artifactPlanFixture,
  String serverImage = 'registry.example/aonw/server@sha256:$_imageDigest',
  List<ReleaseChannel> channels = const [
    ReleaseChannel.downloads,
    ReleaseChannel.googlePlay,
    ReleaseChannel.homepage,
    ReleaseChannel.ios,
    ReleaseChannel.itch,
    ReleaseChannel.server,
    ReleaseChannel.steam,
    ReleaseChannel.web,
  ],
  List<ManifestArtifact>? artifacts,
}) => ReleaseManifestV1(
  sourceSha: sourceSha,
  version: version,
  build: 77,
  artifactPlan: ArtifactPlanEvidence.fromJson(artifactPlanJson),
  qualityGate: QualityGateEvidence.passed(
    name: 'release-check',
    sourceSha: sourceSha,
  ),
  serverImage: serverImage,
  channels: channels,
  artifacts: artifacts ?? _artifacts(),
  config: ManifestFileTree(
    files: [_file('compose.yml', _configHash, 10)],
    expectedRevision: _configRevision,
  ),
  migrations: ManifestFileTree(
    files: [_file('migration.sql', _migrationHash, 20)],
    expectedRevision: _migrationRevision,
  ),
);

ManifestArtifact _artifact(String path, {String id = 'desktop-macos'}) =>
    ManifestArtifact(
      id: id,
      path: path,
      sha256: _artifactHash,
      bytes: 42,
      mediaType: 'application/zip',
      destinations: const [ReleaseChannel.downloads],
    );

List<ManifestArtifact> _artifacts() => [
  ManifestArtifact(
    id: 'android-aab',
    path: 'artifacts/aonw.aab',
    sha256: _artifactHash,
    bytes: 42,
    mediaType: 'application/zip',
    destinations: const [ReleaseChannel.googlePlay],
  ),
  ManifestArtifact(
    id: 'desktop-macos',
    path: 'artifacts/aonw.zip',
    sha256: _artifactHash,
    bytes: 42,
    mediaType: 'application/zip',
    destinations: const [
      ReleaseChannel.downloads,
      ReleaseChannel.itch,
      ReleaseChannel.steam,
    ],
  ),
  ManifestArtifact(
    id: 'homepage-static',
    path: 'artifacts/homepage.tar.gz',
    sha256: _artifactHash,
    bytes: 42,
    mediaType: 'application/gzip',
    destinations: const [ReleaseChannel.homepage],
  ),
  ManifestArtifact(
    id: 'ios-archive',
    path: 'artifacts/aonw-ios.zip',
    sha256: _artifactHash,
    bytes: 42,
    mediaType: 'application/zip',
    destinations: const [ReleaseChannel.ios],
  ),
  ManifestArtifact(
    id: 'web-static',
    path: 'artifacts/web.tar.gz',
    sha256: _artifactHash,
    bytes: 42,
    mediaType: 'application/gzip',
    destinations: const [ReleaseChannel.web],
  ),
];

ManifestFileEntry _file(String path, String sha, int bytes) =>
    ManifestFileEntry(path: path, sha256: sha, bytes: bytes);

Matcher _failsContaining(String text) => throwsA(
  isA<ReleaseManifestException>().having(
    (error) => error.message,
    'message',
    contains(text),
  ),
);

Future<Directory> _temporaryDirectory(String prefix) =>
    Directory.systemTemp.createTemp(prefix);
