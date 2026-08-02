import 'dart:convert';

import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wire decode-canonical-encode preserves the exact raw boundary', () {
    const codec = SnapshotCodec();
    final expectedWireJson = _expectedWireJson();
    final wire = WireSnapshot.fromJson(_jsonClone(expectedWireJson));
    final snapshot = codec.fromWire(wire);

    expect(
      codec.toWire(matchId: wire.matchId, snapshot: snapshot).toJson(),
      expectedWireJson,
    );
    expect(snapshot.domain.playerColors, {
      'player_1': 0xFF112233,
      'player_2': 0xFF445566,
    });
    expect(snapshot.domain.playerCountries, {
      'player_1': PlayerCountry.france,
      'player_2': PlayerCountry.canada,
    });
    expect(snapshot.domain.turnStartedAt, _savedAt);

    final firstCanonical = snapshot;
    final secondCanonical = snapshot;

    expect(identical(firstCanonical, secondCanonical), isTrue);
    expect(firstCanonical.metadata.id, 'save_lossless');
    expect(firstCanonical.eventLogOffset, 73);
    expect(firstCanonical.domain.participants.map((player) => player.id), [
      'player_1',
      'player_2',
    ]);
    expect(firstCanonical.domain.participants.first.colorValue, 0xFF112233);
    expect(
      firstCanonical.domain.participants.first.country,
      PlayerCountry.france,
    );
    expect(firstCanonical.domain.participants.last.colorValue, 0xFF445566);
    expect(
      firstCanonical.domain.participants.last.country,
      PlayerCountry.canada,
    );
    expect(firstCanonical.domain.turnStartedAt, _savedAt);

    final encodedAfterCanonicalReads = codec.toWire(
      matchId: wire.matchId,
      snapshot: snapshot,
    );

    expect(encodedAfterCanonicalReads.toJson(), expectedWireJson);
    expect(encodedAfterCanonicalReads.matchId, 'match_lossless');
    expect(encodedAfterCanonicalReads.offset, 73);
    expect(encodedAfterCanonicalReads.save, expectedWireJson['save']);
    expect(encodedAfterCanonicalReads.state['playerColors'], {
      'player_1': 0xFF112233,
      'player_2': 0xFF445566,
    });
    expect(encodedAfterCanonicalReads.state['playerCountries'], {
      'player_1': 'france',
      'player_2': 'canada',
    });
    expect(encodedAfterCanonicalReads.state['wonderRegistry'], {
      'greatLibrary': 'player_1',
    });
    expect(
      (encodedAfterCanonicalReads.state['lifecycle']! as Map)['turnStartedAt'],
      _savedAt.toIso8601String(),
    );

    final secondSnapshot = codec.fromWire(
      WireSnapshot.fromJson(_jsonClone(encodedAfterCanonicalReads.toJson())),
    );
    final secondRoundCanonical = secondSnapshot;
    final secondWire = codec.toWire(
      matchId: encodedAfterCanonicalReads.matchId,
      snapshot: secondSnapshot,
    );

    expect(secondRoundCanonical.domain.turnStartedAt, _savedAt);
    expect(secondWire.toJson(), expectedWireJson);
  });
}

final DateTime _savedAt = DateTime.utc(2026, 7, 21, 12, 34, 56);

Map<String, dynamic> _expectedWireJson() {
  return {
    'v': kProtocolVersion,
    'matchId': 'match_lossless',
    'offset': 73,
    'save': _save().toJson(),
    'state': {
      'playerColors': {'player_1': 0xFF112233, 'player_2': 0xFF445566},
      'playerCountries': {'player_1': 'france', 'player_2': 'canada'},
      'playerGold': {'player_1': 17},
      'playerWarWeariness': <String, int>{},
      'playerStabilityNet': <String, int>{},
      'units': <dynamic>[],
      'cities': <dynamic>[],
      'artifacts': <dynamic>[],
      'fieldImprovements': <dynamic>[],
      'fogOfWar': <dynamic>[],
      'research': {'players': <String, dynamic>{}},
      'wonderRegistry': {'greatLibrary': 'player_1'},
      'lifecycle': {
        'submittedPlayerIds': ['player_1'],
        'turnStartedAt': _savedAt.toIso8601String(),
      },
    },
  };
}

GameSave _save() {
  return GameSave(
    id: 'save_lossless',
    name: 'Lossless boundary',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 9,
    playerStates: const {
      'player_1': PlayerTurnState.finished,
      'player_2': PlayerTurnState.active,
    },
    savedAt: _savedAt,
    camera: const CameraState(x: 4.5, y: -2.25, zoom: 1.75),
    players: const [
      Player(
        id: 'player_1',
        name: 'Alice',
        colorValue: 0xFF112233,
        country: PlayerCountry.france,
      ),
      Player(
        id: 'player_2',
        name: 'Bob',
        colorValue: 0xFF445566,
        country: PlayerCountry.canada,
      ),
    ],
    gameMode: GameMode.multiplayer,
  );
}

Map<String, dynamic> _jsonClone(Map<String, dynamic> source) {
  return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
}
