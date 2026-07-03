import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/protocol.dart';

class CommandCodec {
  const CommandCodec();

  WireCommand toWire({
    required String matchId,
    required int tick,
    int? turn,
    required String actorPlayerId,
    required GameCommand command,
  }) {
    return WireCommand(
      matchId: matchId,
      tick: tick,
      turn: turn,
      actorPlayerId: actorPlayerId,
      command: GameCommandSerializer.toJson(command),
    );
  }

  GameCommand fromWire(WireCommand wire) {
    return GameCommandSerializer.fromJson(wire.command);
  }

  GameCommandContext contextFromWire(WireCommand wire) {
    return GameCommandContext(actorPlayerId: wire.actorPlayerId);
  }
}

class EventCodec {
  const EventCodec();

  WireEvent toWire({
    required String matchId,
    required int offset,
    required DateTime timestamp,
    required List<GameEvent> events,
    String? actorPlayerId,
    int? tick,
    GameCommand? command,
  }) {
    return WireEvent(
      matchId: matchId,
      offset: offset,
      timestamp: timestamp,
      actorPlayerId: actorPlayerId,
      tick: tick,
      command: command == null ? null : GameCommandSerializer.toJson(command),
      events: events.map(GameEventSerializer.toJson).toList(),
    );
  }

  List<GameEvent> eventsFromWire(WireEvent wire) {
    return wire.events.map(GameEventSerializer.fromJson).toList();
  }

  List<Map<String, dynamic>> eventsToJsonList(Iterable<GameEvent> events) {
    return events.map(GameEventSerializer.toJson).toList();
  }

  List<GameEvent> eventsFromJsonList(Iterable<Map<String, dynamic>> events) {
    return events.map(GameEventSerializer.fromJson).toList();
  }

  GameCommand? commandFromWire(WireEvent wire) {
    final command = wire.command;
    if (command == null) return null;
    return GameCommandSerializer.fromJson(command);
  }
}

class SnapshotCodec {
  const SnapshotCodec();

  WireSnapshot toWire({
    required String matchId,
    required SaveSnapshot snapshot,
  }) {
    return WireSnapshot(
      matchId: matchId,
      offset: snapshot.eventLogOffset,
      save: snapshot.save.toJson(),
      state: _stateToJson(snapshot),
    );
  }

  SaveSnapshot fromWire(WireSnapshot wire) {
    final state = wire.state;
    return SaveSnapshot(
      save: GameSave.fromJson(wire.save),
      playerColors: _stringIntMap(state, 'playerColors'),
      playerCountries: _stringCountryMap(state, 'playerCountries'),
      playerGold: _stringIntMap(state, 'playerGold'),
      units: _jsonList(
        state,
        'units',
      ).map((unit) => GameUnit.fromJson(_jsonMap(unit, 'units[]'))).toList(),
      cities: _jsonList(
        state,
        'cities',
      ).map((city) => GameCity.fromJson(_jsonMap(city, 'cities[]'))).toList(),
      artifacts: _jsonList(state, 'artifacts')
          .map(
            (artifact) =>
                WorldArtifact.fromJson(_jsonMap(artifact, 'artifacts[]')),
          )
          .toList(),
      fieldImprovements: _jsonList(state, 'fieldImprovements')
          .map(
            (improvement) =>
                FieldImprovement.fromJson(_jsonMap(improvement, 'fields[]')),
          )
          .toList(),
      fogOfWar: _fogOfWarFromJson(state['fogOfWar']),
      research: switch (state['research']) {
        final Map<Object?, Object?> value => ResearchState.fromJson(
          Map<String, dynamic>.from(value),
        ),
        null => ResearchState.empty,
        final value => throw ArgumentError.value(
          value,
          'WireSnapshot.state.research',
          'Expected a JSON object or null',
        ),
      },
      runtimeState: switch (state['runtimeState']) {
        final Map<Object?, Object?> value => GameRuntimeState.fromJson(
          Map<String, dynamic>.from(value),
        ),
        null => GameRuntimeState.empty,
        final value => throw ArgumentError.value(
          value,
          'WireSnapshot.state.runtimeState',
          'Expected a JSON object or null',
        ),
      },
      eventLogOffset: wire.offset,
    );
  }

  Map<String, dynamic> _stateToJson(SaveSnapshot snapshot) {
    return {
      'playerColors': snapshot.playerColors,
      'playerCountries': snapshot.effectivePlayerCountries.map(
        (playerId, country) => MapEntry(playerId, country.name),
      ),
      'playerGold': snapshot.playerGold,
      'units': snapshot.units.map((unit) => unit.toJson()).toList(),
      'cities': snapshot.cities.map((city) => city.toJson()).toList(),
      'artifacts': snapshot.artifacts
          .map((artifact) => artifact.toJson())
          .toList(),
      'fieldImprovements': snapshot.fieldImprovements
          .map((improvement) => improvement.toJson())
          .toList(),
      'fogOfWar': _fogOfWarToJson(snapshot.fogOfWar),
      'research': snapshot.research.toJson(),
      'runtimeState': snapshot.runtimeState.toJson(),
    };
  }

  Map<String, int> _stringIntMap(Map<String, dynamic> json, String field) {
    final raw = switch (json[field]) {
      final Map<Object?, Object?> value => Map<String, dynamic>.from(value),
      null => const <String, dynamic>{},
      final value => throw ArgumentError.value(
        value,
        'WireSnapshot.state.$field',
        'Expected a JSON object or null',
      ),
    };
    return raw.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  Map<String, PlayerCountry> _stringCountryMap(
    Map<String, dynamic> json,
    String field,
  ) {
    final raw = json[field];
    if (raw == null) return const {};
    if (raw is! Map<Object?, Object?>) {
      throw ArgumentError.value(
        raw,
        'WireSnapshot.state.$field',
        'Expected a JSON object',
      );
    }
    return {
      for (final entry in raw.entries)
        if (entry.key case final String playerId when playerId.isNotEmpty)
          playerId: _countryFromJson(entry.value, field),
    };
  }

  PlayerCountry _countryFromJson(Object? value, String field) {
    if (value is! String || value.isEmpty) {
      throw ArgumentError.value(
        value,
        'WireSnapshot.state.$field',
        'Expected a non-empty String',
      );
    }
    for (final country in PlayerCountry.values) {
      if (country.name == value) return country;
    }
    throw ArgumentError.value(
      value,
      'WireSnapshot.state.$field',
      'Unknown country',
    );
  }

  List<dynamic> _jsonList(Map<String, dynamic> json, String field) {
    return switch (json[field]) {
      final List<dynamic> value => value,
      null => const <dynamic>[],
      final value => throw ArgumentError.value(
        value,
        'WireSnapshot.state.$field',
        'Expected a JSON array or null',
      ),
    };
  }

  Map<String, dynamic> _jsonMap(Object? value, String field) {
    return WireJson.requiredMap(value, 'WireSnapshot.state.$field');
  }

  List<Map<String, dynamic>> _fogOfWarToJson(FogOfWarState fogOfWar) {
    final values = fogOfWar.players.values.toList()
      ..sort((a, b) => a.playerId.compareTo(b.playerId));
    return [
      for (final fog in values)
        {
          'playerId': fog.playerId,
          'discoveredHexes': _hexesToJson(fog.discoveredHexes),
          'visibleHexes': _hexesToJson(fog.visibleHexes),
        },
    ];
  }

  FogOfWarState _fogOfWarFromJson(Object? value) {
    final entries = switch (value) {
      final List<dynamic> list => list,
      null => const <dynamic>[],
      final other => throw ArgumentError.value(
        other,
        'WireSnapshot.state.fogOfWar',
        'Expected a JSON array or null',
      ),
    };
    final players = <String, PlayerFogOfWar>{};
    for (final entry in entries) {
      final fog = _fogFromJson(_jsonMap(entry, 'fogOfWar[]'));
      players[fog.playerId] = fog;
    }
    return FogOfWarState(players: players);
  }

  PlayerFogOfWar _fogFromJson(Map<String, dynamic> json) {
    return PlayerFogOfWar(
      playerId: WireJson.requiredString(
        json,
        'WireSnapshot.state.fogOfWar[]',
        'playerId',
      ),
      discoveredHexes: _hexesFromJson(json['discoveredHexes']),
      visibleHexes: _hexesFromJson(json['visibleHexes']),
    );
  }

  List<Map<String, dynamic>> _hexesToJson(Iterable<HexCoordinate> hexes) {
    final sorted = hexes.toList()
      ..sort((a, b) {
        final col = a.col.compareTo(b.col);
        if (col != 0) return col;
        return a.row.compareTo(b.row);
      });
    return sorted.map((hex) => hex.toJson()).toList();
  }

  Set<HexCoordinate> _hexesFromJson(Object? value) {
    final entries = switch (value) {
      final List<dynamic> list => list,
      null => const <dynamic>[],
      final other => throw ArgumentError.value(
        other,
        'WireSnapshot.state.fogOfWar[].hexes',
        'Expected a JSON array or null',
      ),
    };
    return {
      for (final entry in entries)
        HexCoordinate.fromJson(_jsonMap(entry, 'fogOfWar[].hex')),
    };
  }
}
