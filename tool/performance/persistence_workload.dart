import 'dart:convert';
import 'dart:io';

import 'package:aonw/game/application/ports/recorded_domain_command.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/infrastructure/persistence/json_event_log.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

import 'measurement.dart';

const persistenceWorkloadScales = [100, 1000, 10000];

Future<PerformanceCaseResult> runPersistenceWorkload({
  Iterable<int> scales = persistenceWorkloadScales,
  Directory? workingDirectory,
  int timingSamples = 21,
}) async {
  if (timingSamples < 1) {
    throw ArgumentError.value(timingSamples, 'timingSamples', 'Must be >= 1.');
  }
  final ownedDirectory = workingDirectory == null;
  final root =
      workingDirectory ??
      await Directory.systemTemp.createTemp('aonw_persistence_performance_');
  await root.create(recursive: true);
  final stable = <String, Object?>{};
  final observations = <String, Object?>{};
  try {
    for (final scale in scales) {
      if (scale < 1) {
        throw ArgumentError.value(scale, 'scales', 'Must contain only >= 1.');
      }
      final result = await _runScale(root, scale, timingSamples);
      stable['$scale'] = result.stable;
      observations['$scale'] = result.observations;
    }
  } finally {
    if (ownedDirectory && await root.exists()) {
      await root.delete(recursive: true);
    }
  }
  return PerformanceCaseResult(
    'persistence',
    {'sizes': stable},
    {'sizes': observations},
  );
}

Future<_ScaleResult> _runScale(
  Directory root,
  int records,
  int timingSamples,
) async {
  final saveId = 'performance_$records';
  final fixture = await _prepareEventLog(root, saveId, records);
  final eventLog = JsonEventLog(savesDir: root);
  final eventResult = await _measureEventLog(
    eventLog,
    saveId,
    records,
    fixture.bytes,
    timingSamples,
  );
  final appendResult = await _measureAppend(
    eventLog,
    root,
    records,
    fixture.contents,
    timingSamples,
  );
  final snapshotResult = _measureSnapshot(records, timingSamples);
  return _ScaleResult(
    stable: {
      'eventLog': {...eventResult.stable, 'append': appendResult.stable},
      'snapshot': snapshotResult.stable,
    },
    observations: {
      'eventLog': {
        ...eventResult.observations,
        'append': appendResult.observations,
      },
      'snapshot': snapshotResult.observations,
    },
  );
}

Future<_EventFixture> _prepareEventLog(
  Directory root,
  String saveId,
  int records,
) async {
  final buffer = StringBuffer();
  for (var offset = 1; offset <= records; offset++) {
    buffer
      ..write(jsonEncode(_loggedCommand(offset).toJson()))
      ..write('\n');
  }
  final contents = buffer.toString();
  final file = File('${root.path}/$saveId/events.log');
  await file.parent.create(recursive: true);
  await file.writeAsString(contents, flush: true);
  return _EventFixture(contents, utf8.encode(contents).length);
}

RecordedDomainCommand _loggedCommand(int offset) => RecordedDomainCommand(
  offset: offset,
  timestamp: DateTime.utc(2026, 1, 1).add(Duration(seconds: offset)),
  turn: 1,
  actorPlayerId: 'player_1',
  command: SelectTechnologyCommand(
    'player_1',
    offset.isOdd ? TechnologyId.agriculture : TechnologyId.mining,
  ),
);

Future<_ScaleResult> _measureEventLog(
  JsonEventLog eventLog,
  String saveId,
  int records,
  int bytes,
  int timingSamples,
) async {
  final latestTimings = <Duration>[];
  final readTimings = <Duration>[];
  var latestOffset = 0;
  var tail = <RecordedDomainCommand>[];
  final readSinceOffset = records > 10 ? records - 9 : 1;
  await eventLog.latestOffset(saveId);
  await eventLog.readSince(saveId, offset: readSinceOffset).toList();
  for (var sample = 0; sample < timingSamples; sample++) {
    final latest = await measureAsync(() => eventLog.latestOffset(saveId));
    latestTimings.add(latest.elapsed);
    latestOffset = latest.value;
    final read = await measureAsync(
      () => eventLog.readSince(saveId, offset: readSinceOffset).toList(),
    );
    readTimings.add(read.elapsed);
    tail = read.value;
  }
  if (latestOffset != records || tail.lastOrNull?.offset != records) {
    throw StateError(
      'Prepared event log did not round-trip at scale $records.',
    );
  }
  return _ScaleResult(
    stable: {
      'records': records,
      'bytes': bytes,
      'latestOffset': latestOffset,
      'readSinceOffset': readSinceOffset,
      'readSinceRecords': tail.length,
      'digest': stableDigest(tail.map((entry) => entry.toJson()).toList()),
    },
    observations: {
      'latestOffset': timingObservation(latestTimings),
      'readSince': timingObservation(readTimings),
    },
  );
}

Future<_ScaleResult> _measureAppend(
  JsonEventLog eventLog,
  Directory root,
  int records,
  String baseContents,
  int timingSamples,
) async {
  final saveIds = [
    'performance_${records}_append_warmup',
    for (var sample = 0; sample < timingSamples; sample++)
      'performance_${records}_append_$sample',
  ];
  for (final saveId in saveIds) {
    final file = File('${root.path}/$saveId/events.log');
    await file.parent.create(recursive: true);
    await file.writeAsString(baseContents, flush: true);
  }

  final timings = <Duration>[];
  int? finalBytes;
  String? digest;
  final appendedOffset = records + 1;
  await eventLog.append(saveIds.first, _loggedCommand(appendedOffset));
  final warmup = await eventLog
      .readSince(saveIds.first, offset: appendedOffset)
      .toList();
  if (warmup.length != 1 || warmup.single.offset != appendedOffset) {
    throw StateError('Event append warm-up did not persist its command.');
  }
  for (final saveId in saveIds.skip(1)) {
    final measured = await measureAsync(
      () => eventLog.append(saveId, _loggedCommand(appendedOffset)),
    );
    timings.add(measured.elapsed);
    final file = File('${root.path}/$saveId/events.log');
    final sampleContents = await file.readAsString();
    final sampleBytes = utf8.encode(sampleContents).length;
    final sampleDigest = stableDigest(sampleContents);
    if ((finalBytes != null && finalBytes != sampleBytes) ||
        (digest != null && digest != sampleDigest)) {
      throw StateError('Event append was not stable at scale $records.');
    }
    finalBytes = sampleBytes;
    digest = sampleDigest;
    final appended = await eventLog
        .readSince(saveId, offset: appendedOffset)
        .toList();
    if (appended.length != 1 || appended.single.offset != appendedOffset) {
      throw StateError('Event append did not persist offset $appendedOffset.');
    }
  }
  return _ScaleResult(
    stable: {
      'appendedOffset': appendedOffset,
      'finalBytes': finalBytes!,
      'digest': digest!,
    },
    observations: timingObservation(timings),
  );
}

_ScaleResult _measureSnapshot(int records, int timingSamples) {
  final snapshot = _snapshot(records);
  final encodeTimings = <Duration>[];
  final decodeTimings = <Duration>[];
  late List<int> encoded;
  late CanonicalGameSnapshot restored;
  final warmupEncoded = utf8.encode(
    jsonEncode(SaveSnapshotCodec.toJson(snapshot)),
  );
  SaveSnapshotCodec.fromJson(
    jsonDecode(utf8.decode(warmupEncoded)) as Map<String, dynamic>,
  );
  for (var sample = 0; sample < timingSamples; sample++) {
    final encode = measureSync(
      () => utf8.encode(jsonEncode(SaveSnapshotCodec.toJson(snapshot))),
    );
    encodeTimings.add(encode.elapsed);
    encoded = encode.value;
    final decode = measureSync(
      () => SaveSnapshotCodec.fromJson(
        jsonDecode(utf8.decode(encoded)) as Map<String, dynamic>,
      ),
    );
    decodeTimings.add(decode.elapsed);
    restored = decode.value;
  }
  final sourceDigest = stableDigest(SaveSnapshotCodec.toJson(snapshot));
  final restoredDigest = stableDigest(SaveSnapshotCodec.toJson(restored));
  if (restored.units.length != records || sourceDigest != restoredDigest) {
    throw StateError('Snapshot codec did not round-trip at scale $records.');
  }
  return _ScaleResult(
    stable: {
      'records': restored.units.length,
      'bytes': encoded.length,
      'digest': restoredDigest,
    },
    observations: {
      'encode': timingObservation(encodeTimings),
      'decode': timingObservation(decodeTimings),
    },
  );
}

CanonicalGameSnapshot _snapshot(int records) => GameSnapshotFactory.create(
  save: GameSave(
    id: 'performance_snapshot_$records',
    name: 'Performance snapshot $records',
    mapName: 'synthetic',
    mapSource: MapSource.saved,
    turn: 1,
    playerStates: const {'player_1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Player 1', colorValue: 0xFF3D5FA8),
    ],
  ),
  playerColors: const {'player_1': 0xFF3D5FA8},
  playerGold: const {'player_1': 100},
  units: [
    for (var index = 0; index < records; index++)
      GameUnit.produced(
        id: 'unit_$index',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: index % 100,
        row: index ~/ 100,
      ),
  ],
  eventLogOffset: records,
);

class _ScaleResult {
  const _ScaleResult({required this.stable, required this.observations});

  final Map<String, Object?> stable;
  final Map<String, Object?> observations;
}

class _EventFixture {
  const _EventFixture(this.contents, this.bytes);

  final String contents;
  final int bytes;
}
