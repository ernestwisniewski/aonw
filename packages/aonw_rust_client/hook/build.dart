import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

const _assetName = 'aonw_rust_client_bindings.dart';
const _rustCrateName = 'aonw_flutter';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    if (_rustBuildEnabled(input)) {
      await _buildRust(input, output);
      return;
    }
    await CBuilder.library(
      name: _rustCrateName,
      assetName: _assetName,
      sources: const ['src/aonw_rust_client_stub.c'],
    ).run(input: input, output: output, logger: _logger());
  });
}

bool _rustBuildEnabled(BuildInput input) {
  final enabled = input.userDefines['rust_backend'];
  if (enabled is! bool?) {
    throw const FormatException(
      'hooks.user_defines.aonw_rust_client.rust_backend must be a boolean.',
    );
  }
  if (enabled != true) return false;

  final targetOS = input.config.code.targetOS;
  final targetArchitecture = input.config.code.targetArchitecture;
  if (targetOS != OS.current || targetArchitecture != Architecture.current) {
    throw UnsupportedError(
      'aonw_rust_client rust_backend:true requires a qualified native Rust '
      'build for $targetOS/$targetArchitecture, but this hook currently '
      'builds only the host $OS.current/$Architecture.current. Refusing to '
      'substitute the unavailable C stub.',
    );
  }
  return true;
}

Future<void> _buildRust(BuildInput input, BuildOutputBuilder output) async {
  final engineRoot = input.packageRoot.resolve('../../engine/');
  final result = await Process.run('cargo', const [
    'build',
    '--release',
    '--locked',
    '-p',
    _rustCrateName,
  ], workingDirectory: engineRoot.toFilePath());
  if (result.exitCode != 0) {
    throw BuildError(
      message: 'Rust Flutter adapter build failed:\n${result.stderr}',
    );
  }
  final libraryName = input.config.code.targetOS.dylibFileName(_rustCrateName);
  final source = engineRoot.resolve('target/release/$libraryName');
  final destination = input.outputDirectory.resolve(libraryName);
  await File.fromUri(source).copy(destination.toFilePath());
  await _addEngineDependencies(engineRoot, output);
  output.assets.code.add(
    CodeAsset(
      package: input.packageName,
      name: _assetName,
      linkMode: DynamicLoadingBundled(),
      file: destination,
    ),
  );
}

Future<void> _addEngineDependencies(
  Uri engineRoot,
  BuildOutputBuilder output,
) async {
  for (final relative in ['Cargo.toml', 'Cargo.lock', 'rust-toolchain.toml']) {
    output.dependencies.add(engineRoot.resolve(relative));
  }
  await for (final entry in Directory.fromUri(
    engineRoot.resolve('crates/'),
  ).list(recursive: true)) {
    if (entry is File &&
        (entry.path.endsWith('.rs') || entry.path.endsWith('Cargo.toml'))) {
      output.dependencies.add(entry.uri);
    }
  }
}

Logger _logger() => Logger.root..level = Level.ALL;
