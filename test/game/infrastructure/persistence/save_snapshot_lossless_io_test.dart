import 'dart:convert';

import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'decode-canonical-encode preserves the exact raw persistence envelope',
    () {
      final expectedJson = _expectedPersistenceJson();
      final snapshot = SaveSnapshotCodec.fromJson(_jsonClone(expectedJson));

      expect(SaveSnapshotCodec.toJson(snapshot), expectedJson);
      expect(snapshot.rawPersistentState.playerColors, {
        'player_1': 0xFF112233,
      });
      expect(snapshot.rawPersistentState.playerCountries, {
        'player_2': PlayerCountry.canada,
      });
      expect(snapshot.rawPersistentState.runtimeState.turnStartedAt, isNull);

      final firstCanonical = snapshot.canonical;
      final secondCanonical = snapshot.canonical;

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
      expect(firstCanonical.session.turnStartedAt, _savedAt);

      final encodedAfterCanonicalReads = SaveSnapshotCodec.toJson(snapshot);

      expect(encodedAfterCanonicalReads, expectedJson);
      expect(encodedAfterCanonicalReads['save'], expectedJson['save']);
      expect(encodedAfterCanonicalReads['eventLogOffset'], 73);
      expect(encodedAfterCanonicalReads['playerColors'], {
        'player_1': 0xFF112233,
      });
      expect(encodedAfterCanonicalReads['playerCountries'], {
        'player_2': 'canada',
      });
      expect(
        encodedAfterCanonicalReads['runtimeState'],
        isNot(contains('turnStartedAt')),
      );

      final secondSnapshot = SaveSnapshotCodec.fromJson(
        _jsonClone(encodedAfterCanonicalReads),
      );
      final secondRoundCanonical = secondSnapshot.canonical;

      expect(secondRoundCanonical.session.turnStartedAt, _savedAt);
      expect(SaveSnapshotCodec.toJson(secondSnapshot), expectedJson);
    },
  );
}

final DateTime _savedAt = DateTime.utc(2026, 7, 21, 12, 34, 56);

Map<String, dynamic> _expectedPersistenceJson() {
  return {
    'save': _save().toJson(),
    'playerColors': {'player_1': 0xFF112233},
    'playerCountries': {'player_2': 'canada'},
    'playerGold': {'player_1': 17},
    'playerWarWeariness': <String, int>{},
    'playerStabilityNet': <String, int>{},
    'units': <dynamic>[],
    'cities': <dynamic>[],
    'artifacts': <dynamic>[],
    'fieldImprovements': <dynamic>[],
    'fogOfWar': <dynamic>[],
    'research': {'players': <String, dynamic>{}},
    'runtimeState': {
      'submittedPlayerIds': ['player_1'],
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
        colorValue: 0xFFAA0000,
        country: PlayerCountry.france,
      ),
      Player(
        id: 'player_2',
        name: 'Bob',
        colorValue: 0xFF445566,
        country: PlayerCountry.japan,
      ),
    ],
    gameMode: GameMode.multiplayer,
  );
}

Map<String, dynamic> _jsonClone(Map<String, dynamic> source) {
  return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
}
