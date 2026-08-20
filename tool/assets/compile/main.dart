import 'dart:io';

import 'asset_pipeline.dart';
import 'asset_verifier.dart';
import 'source_checkout.dart';
import 'source_manifest.dart';

Future<void> main(List<String> arguments) async {
  try {
    final options = AssetPipelineOptions.parse(arguments);
    final workspace = Directory.current.absolute;
    final sources = await AssetSourceManifest.load(
      options.manifestPath ??
          '${workspace.path}/tool/assets/asset_source_manifest.json',
    );
    final outputWorkspace = Directory(
      options.outputRoot ?? workspace.path,
    ).absolute;
    if (options.command == AssetPipelineCommand.verifyRuntime) {
      await _verifyRuntime(workspace, outputWorkspace, sources);
      return;
    }
    final sourcePath =
        options.sourceRoot ??
        Platform.environment[sources.externalSource.rootEnvironmentVariable];
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      throw const AssetPipelineUsage(
        'compile/check/reproduce require --source-root PATH or '
        'AONW_ASSET_MASTERS. There is no in-repository fallback.',
      );
    }
    final checkout = await AssetSourceCheckout.open(
      path: sourcePath,
      workspace: workspace,
      contract: sources.externalSource,
    );
    final compiler = AssetCompiler(
      workspace: workspace,
      sources: sources,
      sourceRoot: checkout.root,
    );
    switch (options.command) {
      case AssetPipelineCommand.compile:
        await AtomicRuntimeInstaller(
          compiler: compiler,
          outputWorkspace: outputWorkspace,
        ).compileAndInstall();
        await _verifyRuntime(workspace, outputWorkspace, sources);
      case AssetPipelineCommand.check:
      case AssetPipelineCommand.reproduce:
        await RuntimeReproducer(
          compiler: compiler,
          expectedRuntime: Directory('${outputWorkspace.path}/assets/runtime'),
        ).verify();
        await _verifyRuntime(workspace, outputWorkspace, sources);
      case AssetPipelineCommand.verifyRuntime:
        throw StateError('unreachable command dispatch');
    }
  } on AssetPipelineUsage catch (error) {
    stderr
      ..writeln('Asset pipeline usage error: ${error.message}')
      ..writeln(AssetPipelineOptions.usage);
    exitCode = 64;
  } on FormatException catch (error) {
    stderr.writeln('Asset pipeline contract error: ${error.message}');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Asset pipeline filesystem error: ${error.message}');
    exitCode = 1;
  } on StateError catch (error) {
    stderr.writeln('Asset pipeline failed: ${error.message}');
    exitCode = 1;
  }
}

Future<void> _verifyRuntime(
  Directory workspace,
  Directory outputWorkspace,
  AssetSourceManifest sources,
) async {
  final canonical = outputWorkspace.path == workspace.path;
  await RuntimeAssetVerifier(
    workspace: workspace,
    runtimeRoot: Directory('${outputWorkspace.path}/assets/runtime'),
    sources: sources,
    enforceRepositoryLayout: canonical,
  ).verify();
}

enum AssetPipelineCommand { compile, verifyRuntime, check, reproduce }

final class AssetPipelineOptions {
  const AssetPipelineOptions({
    required this.command,
    required this.manifestPath,
    required this.sourceRoot,
    required this.outputRoot,
  });

  static const usage =
      'Usage: dart run tool/assets/compile/main.dart '
      '<compile|verify-runtime|check|reproduce> '
      '[--manifest PATH] [--source-root PATH] [--output-root PATH]';

  factory AssetPipelineOptions.parse(List<String> arguments) {
    var index = 0;
    var command = AssetPipelineCommand.verifyRuntime;
    if (arguments.isNotEmpty && !arguments.first.startsWith('--')) {
      command = switch (arguments.first) {
        'compile' => AssetPipelineCommand.compile,
        'verify-runtime' => AssetPipelineCommand.verifyRuntime,
        'check' => AssetPipelineCommand.check,
        'reproduce' => AssetPipelineCommand.reproduce,
        final value => throw AssetPipelineUsage('Unknown command: $value'),
      };
      index++;
    }
    final values = <String, String>{};
    while (index < arguments.length) {
      final argument = arguments[index];
      final equals = argument.indexOf('=');
      final name = equals == -1 ? argument : argument.substring(0, equals);
      if (!const {
        '--manifest',
        '--source-root',
        '--output-root',
      }.contains(name)) {
        throw AssetPipelineUsage('Unknown option: $argument');
      }
      final value = equals == -1
          ? _followingValue(arguments, ++index, name)
          : argument.substring(equals + 1);
      if (value.isEmpty) throw AssetPipelineUsage('Missing value for $name');
      if (values.containsKey(name)) {
        throw AssetPipelineUsage('Repeated option: $name');
      }
      values[name] = value;
      index++;
    }
    return AssetPipelineOptions(
      command: command,
      manifestPath: values['--manifest'],
      sourceRoot: values['--source-root'],
      outputRoot: values['--output-root'],
    );
  }

  final AssetPipelineCommand command;
  final String? manifestPath;
  final String? sourceRoot;
  final String? outputRoot;

  static String _followingValue(
    List<String> arguments,
    int index,
    String name,
  ) {
    if (index >= arguments.length || arguments[index].startsWith('--')) {
      throw AssetPipelineUsage('Missing value for $name');
    }
    return arguments[index];
  }
}

final class AssetPipelineUsage implements Exception {
  const AssetPipelineUsage(this.message);

  final String message;
}
