import 'dart:convert';

import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'decode-canonical-encode preserves the exact raw persistence envelope',
    () {
      final expectedJson = _expectedPersistenceJson();
      final snapshot = SaveSnapshotCodec.fromJson(_jsonClone(expectedJson));

      expect(SaveSnapshotCodec.toJson(snapshot), expectedJson);
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

      final encodedAfterCanonicalReads = SaveSnapshotCodec.toJson(snapshot);

      expect(encodedAfterCanonicalReads, expectedJson);
      expect(encodedAfterCanonicalReads['save'], expectedJson['save']);
      expect(encodedAfterCanonicalReads['eventLogOffset'], 73);
      expect(encodedAfterCanonicalReads['playerColors'], {
        'player_1': 0xFF112233,
        'player_2': 0xFF445566,
      });
      expect(encodedAfterCanonicalReads['playerCountries'], {
        'player_1': 'france',
        'player_2': 'canada',
      });
      expect(
        (encodedAfterCanonicalReads['lifecycle']! as Map)['turnStartedAt'],
        _savedAt.toIso8601String(),
      );

      final secondSnapshot = SaveSnapshotCodec.fromJson(
        _jsonClone(encodedAfterCanonicalReads),
      );
      final secondRoundCanonical = secondSnapshot;

      expect(secondRoundCanonical.domain.turnStartedAt, _savedAt);
      expect(SaveSnapshotCodec.toJson(secondSnapshot), expectedJson);
    },
  );
}

final DateTime _savedAt = DateTime.utc(2026, 7, 21, 12, 34, 56);

Map<String, dynamic> _expectedPersistenceJson() {
  return {
    'save': _save().toJson(),
    'playerColors': {'player_1': 0xFF112233, 'player_2': 0xFF445566},
    'playerCountries': {'player_1': 'france', 'player_2': 'canada'},
    'playerGold': {'player_1': 17},
    'playerWarWeariness': <String, int>{},
    'playerStabilityNet': <String, int>{},
    'units': <dynamic>[],
    'cities': <dynamic>[],
    'artifacts': <dynamic>[],
    'fieldImprovements': <dynamic>[],
    'transportNetwork': <dynamic>[],
    'fogOfWar': <dynamic>[],
    'research': {'players': <String, dynamic>{}},
    'lifecycle': {
      'submittedPlayerIds': ['player_1'],
      'turnStartedAt': _savedAt.toIso8601String(),
    },
    'eventLogOffset': 73,
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
