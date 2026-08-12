import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save/game_save_origin.dart';
import 'package:aonw_core/game/domain/state/game_mode.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

export 'package:aonw_core/game/domain/state/game_mode.dart';

part 'game_save.freezed.dart';
part 'game_save.g.dart';

const gameSaveCurrentSchemaVersion = 5;

@freezed
abstract class CameraState with _$CameraState {
  const CameraState._();

  const factory CameraState({
    required double x,
    required double y,
    required double zoom,
  }) = _CameraState;

  factory CameraState.fromJson(Map<String, dynamic> json) =>
      _$CameraStateFromJson(json);

  static const zero = CameraState(x: 0.0, y: 0.0, zoom: 1.0);
}

@freezed
abstract class GameSave with _$GameSave {
  const GameSave._();

  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true)
  const factory GameSave({
    required String id,
    @Default(gameSaveCurrentSchemaVersion) int schemaVersion,
    required String name,
    required String mapName,
    @Default(MapSource.asset)
    @JsonKey(unknownEnumValue: MapSource.asset)
    MapSource mapSource,
    required int turn,
    required Map<String, PlayerTurnState> playerStates,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    required DateTime savedAt,
    required CameraState camera,
    @JsonKey(name: 'ruleset')
    @Default(MatchRules.standard)
    MatchRules matchRules,
    @Default([]) List<Player> players,
    @Default(GameMode.hotSeat) GameMode gameMode,
    @JsonKey(fromJson: gameSaveOriginFromJson, toJson: gameSaveOriginToJson)
    @Default(GameSaveOrigin.local)
    GameSaveOrigin origin,
  }) = _GameSave;

  factory GameSave.fromJson(Map<String, dynamic> json) =>
      _$GameSaveFromJson(_withLegacySaveDefaults(json));

  GameSave withPlayerFinished(String playerId) {
    if (!playerStates.containsKey(playerId)) return this;
    final updated = Map<String, PlayerTurnState>.from(playerStates)
      ..[playerId] = PlayerTurnState.finished;
    final allDone = updated.values.every((s) => s == PlayerTurnState.finished);
    if (allDone) {
      return copyWith(playerStates: updated).withNewTurn();
    }
    return copyWith(playerStates: updated);
  }

  GameSave withNewTurn() {
    final reset = playerStates.map(
      (k, _) => MapEntry(k, PlayerTurnState.active),
    );
    return copyWith(turn: turn + 1, playerStates: reset);
  }
}

@freezed
abstract class GameSaveIndex with _$GameSaveIndex {
  const GameSaveIndex._();

  const factory GameSaveIndex({
    required String id,
    required String name,
    required String mapName,
    @Default(MapSource.asset)
    @JsonKey(unknownEnumValue: MapSource.asset)
    MapSource mapSource,
    required int turn,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    required DateTime savedAt,
    @Default(GameMode.hotSeat) GameMode gameMode,
    @JsonKey(fromJson: gameSaveOriginFromJson, toJson: gameSaveOriginToJson)
    @Default(GameSaveOrigin.local)
    GameSaveOrigin origin,
    @Default(false) bool replayAvailable,
    @Default(false) bool corrupted,
    String? corruptionMessage,
  }) = _GameSaveIndex;

  factory GameSaveIndex.fromJson(Map<String, dynamic> json) =>
      _$GameSaveIndexFromJson(_withLegacyOrigin(json));
}

Map<String, dynamic> _withLegacyOrigin(Map<String, dynamic> json) {
  if (json['origin'] != null) return json;
  return {...json, 'origin': GameSaveOrigin.legacy.name};
}

Map<String, dynamic> _withLegacySaveDefaults(Map<String, dynamic> json) {
  final withOrigin = _withLegacyOrigin(json);
  if (withOrigin['ruleset'] != null) return withOrigin;
  final legacyRules = MatchRules.standard.copyWith(
    strategicResourceEconomy: StrategicResourceEconomyProfile.legacyPresenceV0,
  );
  return {...withOrigin, 'ruleset': legacyRules.toJson()};
}

DateTime _dateTimeFromJson(String value) => DateTime.parse(value);

String _dateTimeToJson(DateTime value) => value.toUtc().toIso8601String();
