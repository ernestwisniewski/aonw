import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/assets/compile/main.dart'
    show AssetPipelineCommand, AssetPipelineOptions;
import '../../tool/assets/compile/runtime_file_manifest.dart';
import '../../tool/assets/compile/source_checkout.dart';
import '../../tool/assets/compile/source_manifest.dart';

void main() {
  late AssetSourceManifest sources;

  setUpAll(() async {
    sources = await AssetSourceManifest.load(
      '${Directory.current.path}/tool/assets/asset_source_manifest.json',
    );
  });

  test('pins the external master repository to an immutable revision', () {
    expect(
      sources.externalSource.repository,
      'https://github.com/ernestwisniewski/aonw-assets.git',
    );
    expect(
      sources.externalSource.revision,
      '00b572f5137feb38d68b50684001ee24383a8369',
    );
    expect(
      sources.externalSource.rootEnvironmentVariable,
      'AONW_ASSET_MASTERS',
    );
  });

  test('rejects placeholder external source contracts', () async {
    final temporary = await Directory.systemTemp.createTemp('asset-contract-');
    addTearDown(() => temporary.delete(recursive: true));
    final manifest = File('${temporary.path}/manifest.json');
    await manifest.writeAsString(
      jsonEncode({
        'version': 1,
        'externalSource': {
          'repository': 'configure-in-private-asset-masters',
          'revision': 'working-tree',
          'rootEnvironmentVariable': 'AONW_ASSET_MASTERS',
        },
      }),
    );
    await expectLater(
      AssetSourceManifest.load(manifest.path),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'runtime manifest enforces hashes and an exact file allowlist',
    () async {
      final temporary = await Directory.systemTemp.createTemp('asset-runtime-');
      addTearDown(() => temporary.delete(recursive: true));
      final runtime = Directory('${temporary.path}/assets/runtime');
      await Directory('${runtime.path}/ui').create(recursive: true);
      final logo = File('${runtime.path}/ui/logo.webp');
      await logo.writeAsBytes([1, 2, 3]);
      await RuntimeFileManifest.write(runtimeRoot: runtime, sources: sources);

      final manifest = await RuntimeFileManifest.load(runtime);
      expect(await manifest.verify(runtime, sources), isEmpty);

      await logo.writeAsBytes([3, 2, 1]);
      expect(
        await manifest.verify(runtime, sources),
        contains('ui/logo.webp SHA-256 changed'),
      );
      await File('${runtime.path}/unexpected.bin').writeAsBytes([4]);
      expect(
        await manifest.verify(runtime, sources),
        contains('unexpected runtime file: unexpected.bin'),
      );
    },
  );

  test(
    'source checkout cannot point back into the application repository',
    () async {
      await expectLater(
        AssetSourceCheckout.open(
          path: '${Directory.current.path}/assets',
          workspace: Directory.current,
          contract: sources.externalSource,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('must be an external checkout'),
          ),
        ),
      );
    },
  );

  test('command line defaults to source-free verification', () {
    expect(
      AssetPipelineOptions.parse(const []).command,
      AssetPipelineCommand.verifyRuntime,
    );
    final compile = AssetPipelineOptions.parse(const [
      'compile',
      '--source-root',
      '/tmp/masters',
      '--output-root=/tmp/output',
    ]);
    expect(compile.command, AssetPipelineCommand.compile);
    expect(compile.sourceRoot, '/tmp/masters');
    expect(compile.outputRoot, '/tmp/output');
  });
}
