// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_save.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CameraState _$CameraStateFromJson(Map<String, dynamic> json) => _CameraState(
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
  zoom: (json['zoom'] as num).toDouble(),
);

Map<String, dynamic> _$CameraStateToJson(_CameraState instance) =>
    <String, dynamic>{'x': instance.x, 'y': instance.y, 'zoom': instance.zoom};

_GameSave _$GameSaveFromJson(Map<String, dynamic> json) => _GameSave(
  id: json['id'] as String,
  schemaVersion:
      (json['schemaVersion'] as num?)?.toInt() ?? gameSaveCurrentSchemaVersion,
  name: json['name'] as String,
  mapName: json['mapName'] as String,
  mapSource:
      $enumDecodeNullable(
        _$MapSourceEnumMap,
        json['mapSource'],
        unknownValue: MapSource.asset,
      ) ??
      MapSource.asset,
  turn: (json['turn'] as num).toInt(),
  playerStates: (json['playerStates'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, $enumDecode(_$PlayerTurnStateEnumMap, e)),
  ),
  savedAt: _dateTimeFromJson(json['savedAt'] as String),
  camera: CameraState.fromJson(json['camera'] as Map<String, dynamic>),
  matchRules: json['ruleset'] == null
      ? MatchRules.standard
      : MatchRules.fromJson(json['ruleset'] as Map<String, dynamic>),
  players:
      (json['players'] as List<dynamic>?)
          ?.map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  gameMode:
      $enumDecodeNullable(_$GameModeEnumMap, json['gameMode']) ??
      GameMode.hotSeat,
);

Map<String, dynamic> _$GameSaveToJson(_GameSave instance) => <String, dynamic>{
  'id': instance.id,
  'schemaVersion': instance.schemaVersion,
  'name': instance.name,
  'mapName': instance.mapName,
  'mapSource': _$MapSourceEnumMap[instance.mapSource]!,
  'turn': instance.turn,
  'playerStates': instance.playerStates.map(
    (k, e) => MapEntry(k, _$PlayerTurnStateEnumMap[e]!),
  ),
  'savedAt': _dateTimeToJson(instance.savedAt),
  'camera': instance.camera.toJson(),
  'ruleset': instance.matchRules.toJson(),
  'players': instance.players.map((e) => e.toJson()).toList(),
  'gameMode': _$GameModeEnumMap[instance.gameMode]!,
};

const _$MapSourceEnumMap = {MapSource.asset: 'asset', MapSource.saved: 'saved'};

const _$PlayerTurnStateEnumMap = {
  PlayerTurnState.active: 'active',
  PlayerTurnState.finished: 'finished',
};

const _$GameModeEnumMap = {
  GameMode.hotSeat: 'hotSeat',
  GameMode.multiplayer: 'multiplayer',
};

_GameSaveIndex _$GameSaveIndexFromJson(Map<String, dynamic> json) =>
    _GameSaveIndex(
      id: json['id'] as String,
      name: json['name'] as String,
      mapName: json['mapName'] as String,
      mapSource:
          $enumDecodeNullable(
            _$MapSourceEnumMap,
            json['mapSource'],
            unknownValue: MapSource.asset,
          ) ??
          MapSource.asset,
      turn: (json['turn'] as num).toInt(),
      savedAt: _dateTimeFromJson(json['savedAt'] as String),
      gameMode:
          $enumDecodeNullable(_$GameModeEnumMap, json['gameMode']) ??
          GameMode.hotSeat,
      replayAvailable: json['replayAvailable'] as bool? ?? false,
      corrupted: json['corrupted'] as bool? ?? false,
      corruptionMessage: json['corruptionMessage'] as String?,
    );

Map<String, dynamic> _$GameSaveIndexToJson(_GameSaveIndex instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'mapName': instance.mapName,
      'mapSource': _$MapSourceEnumMap[instance.mapSource]!,
      'turn': instance.turn,
      'savedAt': _dateTimeToJson(instance.savedAt),
      'gameMode': _$GameModeEnumMap[instance.gameMode]!,
      'replayAvailable': instance.replayAvailable,
      'corrupted': instance.corrupted,
      'corruptionMessage': instance.corruptionMessage,
    };
