import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/allocate_loopback_port_triplet.dart';

void main() {
  test('allocates and releases three contiguous IPv4-loopback ports', () async {
    final basePort = await allocateLoopbackPortTriplet(random: Random(17));
    expect(basePort, inInclusiveRange(20000, 29997));

    final sockets = <ServerSocket>[];
    addTearDown(() async {
      await Future.wait(sockets.map((socket) => socket.close()));
    });
    for (var offset = 0; offset < 3; offset += 1) {
      sockets.add(
        await ServerSocket.bind(
          InternetAddress.loopbackIPv4,
          basePort + offset,
          shared: false,
        ),
      );
    }
    expect(sockets.map((socket) => socket.port), [
      basePort,
      basePort + 1,
      basePort + 2,
    ]);
  });

  test('rejects a triplet whose first port is already reserved', () async {
    final occupied = await ServerSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
      shared: false,
    );
    addTearDown(occupied.close);
    if (occupied.port > 65533) return;

    final reservation = await LoopbackPortTripletReservation.tryCreate(
      occupied.port,
    );
    expect(reservation, isNull);
  });

  test('rejects unsafe ranges and attempt counts', () async {
    await expectLater(
      allocateLoopbackPortTriplet(minimumBasePort: 1023),
      throwsRangeError,
    );
    await expectLater(
      allocateLoopbackPortTriplet(maximumBasePort: 65534),
      throwsRangeError,
    );
    await expectLater(
      allocateLoopbackPortTriplet(attempts: 0),
      throwsRangeError,
    );
  });

  test('locks every port against identical and overlapping triplets', () async {
    final lockDirectory = await Directory.systemTemp.createTemp(
      'aonw-critical-e2e-port-locks.',
    );
    addTearDown(() => lockDirectory.delete(recursive: true));

    final basePort = await allocateLoopbackPortTriplet(
      random: Random(23),
      lockDirectory: lockDirectory,
    );
    final lockFiles = loopbackPortTripletLockPaths(
      lockDirectory,
      basePort,
    ).map(File.new).toList();
    expect(
      lockFiles,
      everyElement(predicate<File>((file) => file.existsSync())),
    );

    await expectLater(
      allocateLoopbackPortTriplet(
        minimumBasePort: basePort,
        maximumBasePort: basePort,
        attempts: 1,
        lockDirectory: lockDirectory,
      ),
      throwsStateError,
    );
    await expectLater(
      allocateLoopbackPortTriplet(
        minimumBasePort: basePort + 1,
        maximumBasePort: basePort + 1,
        attempts: 1,
        lockDirectory: lockDirectory,
      ),
      throwsStateError,
    );

    await Future.wait(lockFiles.map((file) => file.delete()));
    expect(
      await allocateLoopbackPortTriplet(
        minimumBasePort: basePort,
        maximumBasePort: basePort,
        attempts: 1,
      ),
      basePort,
    );
  });
}
