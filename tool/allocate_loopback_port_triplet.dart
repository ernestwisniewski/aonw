import 'dart:io';
import 'dart:math';

const _defaultMinimumBasePort = 20000;
const _defaultMaximumBasePort = 29997;
const _defaultAttempts = 128;
// POSIX EEXIST and Windows ERROR_FILE_EXISTS / ERROR_ALREADY_EXISTS.
const _fileAlreadyExistsErrorCodes = {17, 80, 183};

final class LoopbackPortTripletReservation {
  LoopbackPortTripletReservation._(this.basePort, this._sockets);

  final int basePort;
  final List<ServerSocket> _sockets;
  bool _released = false;

  static Future<LoopbackPortTripletReservation?> tryCreate(int basePort) async {
    if (basePort < 1024 || basePort > 65533) {
      throw RangeError.range(basePort, 1024, 65533, 'basePort');
    }
    final sockets = <ServerSocket>[];
    try {
      for (var offset = 0; offset < 3; offset += 1) {
        sockets.add(
          await ServerSocket.bind(
            InternetAddress.loopbackIPv4,
            basePort + offset,
            shared: false,
          ),
        );
      }
      return LoopbackPortTripletReservation._(basePort, sockets);
    } on SocketException {
      await _closeAll(sockets);
      return null;
    } catch (_) {
      await _closeAll(sockets);
      rethrow;
    }
  }

  Future<void> release() async {
    if (_released) return;
    _released = true;
    await _closeAll(_sockets);
  }

  static Future<void> _closeAll(Iterable<ServerSocket> sockets) async {
    await Future.wait(
      sockets.map((socket) => socket.close()),
      eagerError: false,
    );
  }
}

Future<int> allocateLoopbackPortTriplet({
  Random? random,
  int minimumBasePort = _defaultMinimumBasePort,
  int maximumBasePort = _defaultMaximumBasePort,
  int attempts = _defaultAttempts,
  Directory? lockDirectory,
}) async {
  if (minimumBasePort < 1024 ||
      maximumBasePort > 65533 ||
      minimumBasePort > maximumBasePort) {
    throw RangeError(
      'Port range must stay within 1024..65533 and must not be empty.',
    );
  }
  if (attempts < 1) {
    throw RangeError.value(attempts, 'attempts', 'must be positive');
  }
  await lockDirectory?.create(recursive: true);

  final candidateCount = maximumBasePort - minimumBasePort + 1;
  final source = random ?? Random.secure();
  candidateLoop:
  for (var attempt = 0; attempt < attempts; attempt += 1) {
    final basePort = minimumBasePort + source.nextInt(candidateCount);
    final reservation = await LoopbackPortTripletReservation.tryCreate(
      basePort,
    );
    if (reservation == null) continue;
    final lockFiles = <File>[];
    if (lockDirectory != null) {
      for (final path in loopbackPortTripletLockPaths(
        lockDirectory,
        basePort,
      )) {
        final lockFile = File(path);
        try {
          await lockFile.create(exclusive: true);
          lockFiles.add(lockFile);
        } on FileSystemException catch (error) {
          final overlapsAnotherTriplet = _fileAlreadyExistsErrorCodes.contains(
            error.osError?.errorCode,
          );
          try {
            await _deleteLockFiles(lockFiles);
          } finally {
            await reservation.release();
          }
          if (overlapsAnotherTriplet) continue candidateLoop;
          rethrow;
        }
      }
    }
    try {
      await reservation.release();
    } catch (_) {
      await _deleteLockFiles(lockFiles);
      rethrow;
    }
    return basePort;
  }
  throw StateError(
    'Could not allocate three contiguous IPv4-loopback ports after '
    '$attempts attempts.',
  );
}

List<String> loopbackPortTripletLockPaths(Directory directory, int basePort) =>
    List.generate(
      3,
      (offset) =>
          '${directory.path}${Platform.pathSeparator}${basePort + offset}.lock',
      growable: false,
    );

Future<void> _deleteLockFiles(Iterable<File> files) async {
  await Future.wait(files.map((file) => file.delete()), eagerError: false);
}

Future<void> main(List<String> args) async {
  Directory? lockDirectory;
  if (args.isEmpty) {
    lockDirectory = null;
  } else if (args.length == 2 &&
      args.first == '--lock-directory' &&
      args.last.isNotEmpty) {
    lockDirectory = Directory(args.last);
  } else {
    stderr.writeln(
      'Usage: dart run tool/allocate_loopback_port_triplet.dart '
      '[--lock-directory PATH]',
    );
    exitCode = 64;
    return;
  }
  stdout.writeln(
    await allocateLoopbackPortTriplet(lockDirectory: lockDirectory),
  );
}
