import 'dart:ffi';
import 'dart:io';

typedef _SetsidNative = Int32 Function();
typedef _SetsidDart = int Function();

Future<void> main(List<String> arguments) async {
  if (Platform.isWindows) {
    stderr.writeln('POSIX process-group launcher cannot run on Windows.');
    exitCode = 64;
    return;
  }
  if (arguments.isEmpty) {
    stderr.writeln('Process-group launcher requires an executable.');
    exitCode = 64;
    return;
  }

  late final int sessionId;
  try {
    final setsid = DynamicLibrary.process()
        .lookupFunction<_SetsidNative, _SetsidDart>('setsid');
    sessionId = setsid();
  } on Object catch (error) {
    stderr.writeln('Could not load POSIX setsid(2): $error');
    exitCode = 70;
    return;
  }
  if (sessionId < 0) {
    stderr.writeln('Could not create an isolated POSIX process group.');
    exitCode = 70;
    return;
  }

  late final Process child;
  try {
    child = await Process.start(
      arguments.first,
      arguments.skip(1).toList(growable: false),
      includeParentEnvironment: true,
      runInShell: false,
      mode: ProcessStartMode.inheritStdio,
    );
  } on Object catch (error) {
    stderr.writeln('Could not start isolated command: $error');
    exitCode = 70;
    return;
  }

  final childExitCode = await child.exitCode;
  exitCode = childExitCode < 0 ? 128 - childExitCode : childExitCode;
}
