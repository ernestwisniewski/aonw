part of 'test_process.dart';

const _maxMutationOutputBytes = 8 * 1024 * 1024;
const _processTerminationGrace = Duration(milliseconds: 250);
const _residualProcessTerminationGrace = Duration(milliseconds: 50);

typedef _KillNative = Int32 Function(Int32 pid, Int32 signal);
typedef _KillDart = int Function(int pid, int signal);

final class SystemMutationCommandExecutor implements MutationCommandExecutor {
  const SystemMutationCommandExecutor({this.processGroupLauncherPath});

  final String? processGroupLauncherPath;

  @override
  Future<MutationProcessOutput> run({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    required Duration timeout,
    required String description,
  }) async {
    if (Platform.isWindows) {
      throw const MutationFailure(
        'Mutation test isolation is unavailable on Windows until the runner '
        'uses Windows Job Objects.',
      );
    }

    final launcher = _resolveProcessGroupLauncher(processGroupLauncherPath);
    late final Process process;
    try {
      process = await Process.start(
        _dartExecutable,
        [launcher, executable, ...arguments],
        workingDirectory: workingDirectory,
        environment: {...Platform.environment, 'LC_ALL': 'C', 'TZ': 'UTC'},
        includeParentEnvironment: false,
        runInShell: false,
        mode: ProcessStartMode.normal,
      );
    } on ProcessException catch (error) {
      throw MutationFailure('$description could not start: $error');
    } on FileSystemException catch (error) {
      throw MutationFailure('$description could not start: $error');
    }
    // setsid(2) in the launcher makes its PID the process-group ID inherited
    // by the real command and all ordinary descendants. Group signalling is
    // therefore race-free even after an intermediate parent exits.
    final processGroupId = process.pid;
    final stdoutCollector = _ByteCollector('stdout', process.stdout);
    final stderrCollector = _ByteCollector('stderr', process.stderr);
    final exitCodeFuture = process.exitCode;
    final outputFuture = exitCodeFuture.then((exitCode) async {
      // A surviving descendant may still own the inherited output pipes. Kill
      // the now-residual group before waiting for EOF, otherwise a successful
      // direct command could be misclassified as a timeout.
      await _terminateResidualProcessGroup(processGroupId);
      return _decodeOutput(
        exitCode: exitCode,
        stdoutFuture: stdoutCollector.done,
        stderrFuture: stderrCollector.done,
        description: description,
      );
    });
    final timeoutSignal = Completer<_ProcessCompletion>();
    final timeoutTimer = Timer(
      timeout,
      () => timeoutSignal.complete(const _ProcessTimedOut()),
    );
    final outputLimitFuture = Future.any([
      stdoutCollector.limitExceeded,
      stderrCollector.limitExceeded,
    ]).then<_ProcessCompletion>(_ProcessOutputLimitExceeded.new);
    // The command is non-interactive. Start closing stdin only after output
    // draining and the watchdog exist, so even a platform-level close stall
    // remains inside the same bounded process lifecycle.
    unawaited(
      process.stdin.close().onError((_, _) {
        // An early launcher exit already gives its command EOF. The process
        // group and watchdog below still own all remaining cleanup.
      }),
    );

    late final _ProcessCompletion completion;
    try {
      completion = await Future.any<_ProcessCompletion>([
        outputFuture.then(_ProcessCompleted.new),
        timeoutSignal.future,
        outputLimitFuture,
      ]);
    } on Object {
      await _terminateProcess(
        process: process,
        processGroupId: processGroupId,
        exitCodeFuture: exitCodeFuture,
        stdoutCollector: stdoutCollector,
        stderrCollector: stderrCollector,
      );
      rethrow;
    } finally {
      timeoutTimer.cancel();
    }

    if (completion case final _ProcessCompleted completed) {
      return completed.output;
    }

    final output = await _terminateProcess(
      process: process,
      processGroupId: processGroupId,
      exitCodeFuture: exitCodeFuture,
      stdoutCollector: stdoutCollector,
      stderrCollector: stderrCollector,
      outputFuture: outputFuture,
    );
    if (completion is _ProcessOutputLimitExceeded) {
      throw MutationFailure(
        '$description exceeded the $_maxMutationOutputBytes-byte '
        '${completion.streamName} limit.'
        '${output == null ? '' : _outputContext(output)}',
      );
    }
    throw MutationFailure(
      '$description timed out after ${timeout.inMilliseconds}ms.'
      '${output == null ? '' : _outputContext(output)}',
    );
  }
}

final class _ByteCollector {
  _ByteCollector(this.streamName, Stream<List<int>> stream) {
    _subscription = stream.listen(
      _add,
      onError: (Object error, StackTrace stackTrace) {
        if (!_done.isCompleted) _done.completeError(error, stackTrace);
      },
      onDone: () {
        if (!_done.isCompleted) _done.complete(List.unmodifiable(_bytes));
      },
      cancelOnError: true,
    );
  }

  final String streamName;
  final List<int> _bytes = [];
  final Completer<List<int>> _done = Completer<List<int>>();
  final Completer<String> _limitExceeded = Completer<String>();
  late final StreamSubscription<List<int>> _subscription;

  Future<List<int>> get done => _done.future;
  Future<String> get limitExceeded => _limitExceeded.future;

  void _add(List<int> chunk) {
    final remaining = _maxMutationOutputBytes - _bytes.length;
    if (remaining > 0) {
      _bytes.addAll(
        chunk.length <= remaining ? chunk : chunk.sublist(0, remaining),
      );
    }
    if (chunk.length > remaining && !_limitExceeded.isCompleted) {
      _limitExceeded.complete(streamName);
    }
  }

  Future<void> cancel() async {
    await _subscription.cancel();
    if (!_done.isCompleted) _done.complete(List.unmodifiable(_bytes));
  }
}

Future<MutationProcessOutput?> _terminateProcess({
  required Process process,
  required int processGroupId,
  required Future<int> exitCodeFuture,
  required _ByteCollector stdoutCollector,
  required _ByteCollector stderrCollector,
  Future<MutationProcessOutput>? outputFuture,
}) async {
  _signalIsolatedRun(process, processGroupId, ProcessSignal.sigterm);
  await Future<void>.delayed(_processTerminationGrace);
  _signalIsolatedRun(process, processGroupId, ProcessSignal.sigkill);

  try {
    await exitCodeFuture.timeout(const Duration(seconds: 2));
  } on TimeoutException {
    await stdoutCollector.cancel();
    await stderrCollector.cancel();
    return null;
  }

  if (outputFuture == null) {
    await stdoutCollector.cancel();
    await stderrCollector.cancel();
    return null;
  }
  try {
    return await outputFuture.timeout(const Duration(seconds: 1));
  } on Object {
    await stdoutCollector.cancel();
    await stderrCollector.cancel();
    return null;
  }
}

Future<void> _terminateResidualProcessGroup(int processGroupId) async {
  _signalProcessGroup(processGroupId, ProcessSignal.sigterm);
  await Future<void>.delayed(_residualProcessTerminationGrace);
  _signalProcessGroup(processGroupId, ProcessSignal.sigkill);
}

void _signalIsolatedRun(
  Process process,
  int processGroupId,
  ProcessSignal signal,
) {
  _signalProcessGroup(processGroupId, signal);
  // If the launcher failed before setsid(2), no process group named after its
  // PID exists. Direct signalling still guarantees that the launcher itself
  // cannot leak from a failed start or an exceptionally early timeout.
  process.kill(signal);
}

void _signalProcessGroup(int processGroupId, ProcessSignal signal) {
  _posixKill(-processGroupId, signal.signalNumber);
}

String _resolveProcessGroupLauncher(String? configuredPath) {
  final candidates = <String>[
    if (configuredPath != null) File(configuredPath).absolute.path,
    if (Platform.script.scheme == 'file') ...[
      '${File.fromUri(Platform.script).absolute.parent.path}'
          '${Platform.pathSeparator}mutation${Platform.pathSeparator}'
          'process_group_launcher.dart',
      '${File.fromUri(Platform.script).absolute.parent.path}'
          '${Platform.pathSeparator}process_group_launcher.dart',
    ],
    '${Directory.current.absolute.path}${Platform.pathSeparator}tool'
        '${Platform.pathSeparator}mutation${Platform.pathSeparator}'
        'process_group_launcher.dart',
  ];
  for (final path in candidates.toSet()) {
    if (FileSystemEntity.typeSync(path, followLinks: false) ==
        FileSystemEntityType.file) {
      return path;
    }
  }
  throw MutationFailure(
    'Cannot locate the regular POSIX process-group launcher. Checked: '
    '${candidates.toSet().toList()..sort()}',
  );
}

final _KillDart _posixKill = DynamicLibrary.process()
    .lookupFunction<_KillNative, _KillDart>('kill');

String get _dartExecutable {
  final resolvedName = File(
    Platform.resolvedExecutable,
  ).uri.pathSegments.last.toLowerCase();
  if (resolvedName == 'dart' || resolvedName == 'dart.exe') {
    return Platform.resolvedExecutable;
  }
  // flutter test runs inside flutter_tester rather than the Dart CLI. PATH is
  // the same controlled environment used to resolve the configured runners.
  return 'dart';
}

Future<MutationProcessOutput> _decodeOutput({
  required int exitCode,
  required Future<List<int>> stdoutFuture,
  required Future<List<int>> stderrFuture,
  required String description,
}) async {
  final bytes = await Future.wait([stdoutFuture, stderrFuture]);
  try {
    return MutationProcessOutput(
      exitCode: exitCode,
      stdout: utf8.decode(bytes[0], allowMalformed: false),
      stderr: utf8.decode(bytes[1], allowMalformed: false),
    );
  } on FormatException catch (error) {
    throw MutationFailure('$description emitted invalid UTF-8: $error');
  }
}

final class _ProcessOutputLimitExceeded extends _ProcessCompletion {
  const _ProcessOutputLimitExceeded(this.streamName);

  final String streamName;
}
