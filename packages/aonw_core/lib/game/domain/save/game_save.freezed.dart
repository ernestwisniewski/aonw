// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_save.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CameraState {

 double get x; double get y; double get zoom;
/// Create a copy of CameraState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CameraStateCopyWith<CameraState> get copyWith => _$CameraStateCopyWithImpl<CameraState>(this as CameraState, _$identity);

  /// Serializes this CameraState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CameraState&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.zoom, zoom) || other.zoom == zoom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y,zoom);

@override
String toString() {
  return 'CameraState(x: $x, y: $y, zoom: $zoom)';
}


}

/// @nodoc
abstract mixin class $CameraStateCopyWith<$Res>  {
  factory $CameraStateCopyWith(CameraState value, $Res Function(CameraState) _then) = _$CameraStateCopyWithImpl;
@useResult
$Res call({
 double x, double y, double zoom
});




}
/// @nodoc
class _$CameraStateCopyWithImpl<$Res>
    implements $CameraStateCopyWith<$Res> {
  _$CameraStateCopyWithImpl(this._self, this._then);

  final CameraState _self;
  final $Res Function(CameraState) _then;

/// Create a copy of CameraState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,Object? zoom = null,}) {
  return _then(_self.copyWith(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,zoom: null == zoom ? _self.zoom : zoom // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CameraState].
extension CameraStatePatterns on CameraState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CameraState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CameraState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CameraState value)  $default,){
final _that = this;
switch (_that) {
case _CameraState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CameraState value)?  $default,){
final _that = this;
switch (_that) {
case _CameraState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double x,  double y,  double zoom)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CameraState() when $default != null:
return $default(_that.x,_that.y,_that.zoom);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double x,  double y,  double zoom)  $default,) {final _that = this;
switch (_that) {
case _CameraState():
return $default(_that.x,_that.y,_that.zoom);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double x,  double y,  double zoom)?  $default,) {final _that = this;
switch (_that) {
case _CameraState() when $default != null:
return $default(_that.x,_that.y,_that.zoom);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CameraState extends CameraState {
  const _CameraState({required this.x, required this.y, required this.zoom}): super._();
  factory _CameraState.fromJson(Map<String, dynamic> json) => _$CameraStateFromJson(json);

@override final  double x;
@override final  double y;
@override final  double zoom;

/// Create a copy of CameraState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CameraStateCopyWith<_CameraState> get copyWith => __$CameraStateCopyWithImpl<_CameraState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CameraStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CameraState&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.zoom, zoom) || other.zoom == zoom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y,zoom);

@override
String toString() {
  return 'CameraState(x: $x, y: $y, zoom: $zoom)';
}


}

/// @nodoc
abstract mixin class _$CameraStateCopyWith<$Res> implements $CameraStateCopyWith<$Res> {
  factory _$CameraStateCopyWith(_CameraState value, $Res Function(_CameraState) _then) = __$CameraStateCopyWithImpl;
@override @useResult
$Res call({
 double x, double y, double zoom
});




}
/// @nodoc
class __$CameraStateCopyWithImpl<$Res>
    implements _$CameraStateCopyWith<$Res> {
  __$CameraStateCopyWithImpl(this._self, this._then);

  final _CameraState _self;
  final $Res Function(_CameraState) _then;

/// Create a copy of CameraState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? zoom = null,}) {
  return _then(_CameraState(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,zoom: null == zoom ? _self.zoom : zoom // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$GameSave {

 String get id; int get schemaVersion; String get name; String get mapName;@JsonKey(unknownEnumValue: MapSource.asset) MapSource get mapSource; int get turn; Map<String, PlayerTurnState> get playerStates;@JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) DateTime get savedAt; CameraState get camera;@JsonKey(name: 'ruleset') MatchRules get matchRules; List<Player> get players; GameMode get gameMode;
/// Create a copy of GameSave
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameSaveCopyWith<GameSave> get copyWith => _$GameSaveCopyWithImpl<GameSave>(this as GameSave, _$identity);

  /// Serializes this GameSave to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameSave&&(identical(other.id, id) || other.id == id)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.name, name) || other.name == name)&&(identical(other.mapName, mapName) || other.mapName == mapName)&&(identical(other.mapSource, mapSource) || other.mapSource == mapSource)&&(identical(other.turn, turn) || other.turn == turn)&&const DeepCollectionEquality().equals(other.playerStates, playerStates)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&(identical(other.camera, camera) || other.camera == camera)&&(identical(other.matchRules, matchRules) || other.matchRules == matchRules)&&const DeepCollectionEquality().equals(other.players, players)&&(identical(other.gameMode, gameMode) || other.gameMode == gameMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,schemaVersion,name,mapName,mapSource,turn,const DeepCollectionEquality().hash(playerStates),savedAt,camera,matchRules,const DeepCollectionEquality().hash(players),gameMode);

@override
String toString() {
  return 'GameSave(id: $id, schemaVersion: $schemaVersion, name: $name, mapName: $mapName, mapSource: $mapSource, turn: $turn, playerStates: $playerStates, savedAt: $savedAt, camera: $camera, matchRules: $matchRules, players: $players, gameMode: $gameMode)';
}


}

/// @nodoc
abstract mixin class $GameSaveCopyWith<$Res>  {
  factory $GameSaveCopyWith(GameSave value, $Res Function(GameSave) _then) = _$GameSaveCopyWithImpl;
@useResult
$Res call({
 String id, int schemaVersion, String name, String mapName,@JsonKey(unknownEnumValue: MapSource.asset) MapSource mapSource, int turn, Map<String, PlayerTurnState> playerStates,@JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) DateTime savedAt, CameraState camera,@JsonKey(name: 'ruleset') MatchRules matchRules, List<Player> players, GameMode gameMode
});


$CameraStateCopyWith<$Res> get camera;

}
/// @nodoc
class _$GameSaveCopyWithImpl<$Res>
    implements $GameSaveCopyWith<$Res> {
  _$GameSaveCopyWithImpl(this._self, this._then);

  final GameSave _self;
  final $Res Function(GameSave) _then;

/// Create a copy of GameSave
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? schemaVersion = null,Object? name = null,Object? mapName = null,Object? mapSource = null,Object? turn = null,Object? playerStates = null,Object? savedAt = null,Object? camera = null,Object? matchRules = null,Object? players = null,Object? gameMode = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mapName: null == mapName ? _self.mapName : mapName // ignore: cast_nullable_to_non_nullable
as String,mapSource: null == mapSource ? _self.mapSource : mapSource // ignore: cast_nullable_to_non_nullable
as MapSource,turn: null == turn ? _self.turn : turn // ignore: cast_nullable_to_non_nullable
as int,playerStates: null == playerStates ? _self.playerStates : playerStates // ignore: cast_nullable_to_non_nullable
as Map<String, PlayerTurnState>,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,camera: null == camera ? _self.camera : camera // ignore: cast_nullable_to_non_nullable
as CameraState,matchRules: null == matchRules ? _self.matchRules : matchRules // ignore: cast_nullable_to_non_nullable
as MatchRules,players: null == players ? _self.players : players // ignore: cast_nullable_to_non_nullable
as List<Player>,gameMode: null == gameMode ? _self.gameMode : gameMode // ignore: cast_nullable_to_non_nullable
as GameMode,
  ));
}
/// Create a copy of GameSave
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CameraStateCopyWith<$Res> get camera {
  
  return $CameraStateCopyWith<$Res>(_self.camera, (value) {
    return _then(_self.copyWith(camera: value));
  });
}
}


/// Adds pattern-matching-related methods to [GameSave].
extension GameSavePatterns on GameSave {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameSave value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameSave() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameSave value)  $default,){
final _that = this;
switch (_that) {
case _GameSave():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameSave value)?  $default,){
final _that = this;
switch (_that) {
case _GameSave() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int schemaVersion,  String name,  String mapName, @JsonKey(unknownEnumValue: MapSource.asset)  MapSource mapSource,  int turn,  Map<String, PlayerTurnState> playerStates, @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)  DateTime savedAt,  CameraState camera, @JsonKey(name: 'ruleset')  MatchRules matchRules,  List<Player> players,  GameMode gameMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameSave() when $default != null:
return $default(_that.id,_that.schemaVersion,_that.name,_that.mapName,_that.mapSource,_that.turn,_that.playerStates,_that.savedAt,_that.camera,_that.matchRules,_that.players,_that.gameMode);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int schemaVersion,  String name,  String mapName, @JsonKey(unknownEnumValue: MapSource.asset)  MapSource mapSource,  int turn,  Map<String, PlayerTurnState> playerStates, @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)  DateTime savedAt,  CameraState camera, @JsonKey(name: 'ruleset')  MatchRules matchRules,  List<Player> players,  GameMode gameMode)  $default,) {final _that = this;
switch (_that) {
case _GameSave():
return $default(_that.id,_that.schemaVersion,_that.name,_that.mapName,_that.mapSource,_that.turn,_that.playerStates,_that.savedAt,_that.camera,_that.matchRules,_that.players,_that.gameMode);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int schemaVersion,  String name,  String mapName, @JsonKey(unknownEnumValue: MapSource.asset)  MapSource mapSource,  int turn,  Map<String, PlayerTurnState> playerStates, @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)  DateTime savedAt,  CameraState camera, @JsonKey(name: 'ruleset')  MatchRules matchRules,  List<Player> players,  GameMode gameMode)?  $default,) {final _that = this;
switch (_that) {
case _GameSave() when $default != null:
return $default(_that.id,_that.schemaVersion,_that.name,_that.mapName,_that.mapSource,_that.turn,_that.playerStates,_that.savedAt,_that.camera,_that.matchRules,_that.players,_that.gameMode);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _GameSave extends GameSave {
  const _GameSave({required this.id, this.schemaVersion = gameSaveCurrentSchemaVersion, required this.name, required this.mapName, @JsonKey(unknownEnumValue: MapSource.asset) this.mapSource = MapSource.asset, required this.turn, required final  Map<String, PlayerTurnState> playerStates, @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) required this.savedAt, required this.camera, @JsonKey(name: 'ruleset') this.matchRules = MatchRules.standard, final  List<Player> players = const [], this.gameMode = GameMode.hotSeat}): _playerStates = playerStates,_players = players,super._();
  factory _GameSave.fromJson(Map<String, dynamic> json) => _$GameSaveFromJson(json);

@override final  String id;
@override@JsonKey() final  int schemaVersion;
@override final  String name;
@override final  String mapName;
@override@JsonKey(unknownEnumValue: MapSource.asset) final  MapSource mapSource;
@override final  int turn;
 final  Map<String, PlayerTurnState> _playerStates;
@override Map<String, PlayerTurnState> get playerStates {
  if (_playerStates is EqualUnmodifiableMapView) return _playerStates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_playerStates);
}

@override@JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) final  DateTime savedAt;
@override final  CameraState camera;
@override@JsonKey(name: 'ruleset') final  MatchRules matchRules;
 final  List<Player> _players;
@override@JsonKey() List<Player> get players {
  if (_players is EqualUnmodifiableListView) return _players;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_players);
}

@override@JsonKey() final  GameMode gameMode;

/// Create a copy of GameSave
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameSaveCopyWith<_GameSave> get copyWith => __$GameSaveCopyWithImpl<_GameSave>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameSaveToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameSave&&(identical(other.id, id) || other.id == id)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.name, name) || other.name == name)&&(identical(other.mapName, mapName) || other.mapName == mapName)&&(identical(other.mapSource, mapSource) || other.mapSource == mapSource)&&(identical(other.turn, turn) || other.turn == turn)&&const DeepCollectionEquality().equals(other._playerStates, _playerStates)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&(identical(other.camera, camera) || other.camera == camera)&&(identical(other.matchRules, matchRules) || other.matchRules == matchRules)&&const DeepCollectionEquality().equals(other._players, _players)&&(identical(other.gameMode, gameMode) || other.gameMode == gameMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,schemaVersion,name,mapName,mapSource,turn,const DeepCollectionEquality().hash(_playerStates),savedAt,camera,matchRules,const DeepCollectionEquality().hash(_players),gameMode);

@override
String toString() {
  return 'GameSave(id: $id, schemaVersion: $schemaVersion, name: $name, mapName: $mapName, mapSource: $mapSource, turn: $turn, playerStates: $playerStates, savedAt: $savedAt, camera: $camera, matchRules: $matchRules, players: $players, gameMode: $gameMode)';
}


}

/// @nodoc
abstract mixin class _$GameSaveCopyWith<$Res> implements $GameSaveCopyWith<$Res> {
  factory _$GameSaveCopyWith(_GameSave value, $Res Function(_GameSave) _then) = __$GameSaveCopyWithImpl;
@override @useResult
$Res call({
 String id, int schemaVersion, String name, String mapName,@JsonKey(unknownEnumValue: MapSource.asset) MapSource mapSource, int turn, Map<String, PlayerTurnState> playerStates,@JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) DateTime savedAt, CameraState camera,@JsonKey(name: 'ruleset') MatchRules matchRules, List<Player> players, GameMode gameMode
});


@override $CameraStateCopyWith<$Res> get camera;

}
/// @nodoc
class __$GameSaveCopyWithImpl<$Res>
    implements _$GameSaveCopyWith<$Res> {
  __$GameSaveCopyWithImpl(this._self, this._then);

  final _GameSave _self;
  final $Res Function(_GameSave) _then;

/// Create a copy of GameSave
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? schemaVersion = null,Object? name = null,Object? mapName = null,Object? mapSource = null,Object? turn = null,Object? playerStates = null,Object? savedAt = null,Object? camera = null,Object? matchRules = null,Object? players = null,Object? gameMode = null,}) {
  return _then(_GameSave(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mapName: null == mapName ? _self.mapName : mapName // ignore: cast_nullable_to_non_nullable
as String,mapSource: null == mapSource ? _self.mapSource : mapSource // ignore: cast_nullable_to_non_nullable
as MapSource,turn: null == turn ? _self.turn : turn // ignore: cast_nullable_to_non_nullable
as int,playerStates: null == playerStates ? _self._playerStates : playerStates // ignore: cast_nullable_to_non_nullable
as Map<String, PlayerTurnState>,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,camera: null == camera ? _self.camera : camera // ignore: cast_nullable_to_non_nullable
as CameraState,matchRules: null == matchRules ? _self.matchRules : matchRules // ignore: cast_nullable_to_non_nullable
as MatchRules,players: null == players ? _self._players : players // ignore: cast_nullable_to_non_nullable
as List<Player>,gameMode: null == gameMode ? _self.gameMode : gameMode // ignore: cast_nullable_to_non_nullable
as GameMode,
  ));
}

/// Create a copy of GameSave
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CameraStateCopyWith<$Res> get camera {
  
  return $CameraStateCopyWith<$Res>(_self.camera, (value) {
    return _then(_self.copyWith(camera: value));
  });
}
}


/// @nodoc
mixin _$GameSaveIndex {

 String get id; String get name; String get mapName;@JsonKey(unknownEnumValue: MapSource.asset) MapSource get mapSource; int get turn;@JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) DateTime get savedAt; GameMode get gameMode; bool get replayAvailable; bool get corrupted; String? get corruptionMessage;
/// Create a copy of GameSaveIndex
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameSaveIndexCopyWith<GameSaveIndex> get copyWith => _$GameSaveIndexCopyWithImpl<GameSaveIndex>(this as GameSaveIndex, _$identity);

  /// Serializes this GameSaveIndex to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameSaveIndex&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.mapName, mapName) || other.mapName == mapName)&&(identical(other.mapSource, mapSource) || other.mapSource == mapSource)&&(identical(other.turn, turn) || other.turn == turn)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&(identical(other.gameMode, gameMode) || other.gameMode == gameMode)&&(identical(other.replayAvailable, replayAvailable) || other.replayAvailable == replayAvailable)&&(identical(other.corrupted, corrupted) || other.corrupted == corrupted)&&(identical(other.corruptionMessage, corruptionMessage) || other.corruptionMessage == corruptionMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,mapName,mapSource,turn,savedAt,gameMode,replayAvailable,corrupted,corruptionMessage);

@override
String toString() {
  return 'GameSaveIndex(id: $id, name: $name, mapName: $mapName, mapSource: $mapSource, turn: $turn, savedAt: $savedAt, gameMode: $gameMode, replayAvailable: $replayAvailable, corrupted: $corrupted, corruptionMessage: $corruptionMessage)';
}


}

/// @nodoc
abstract mixin class $GameSaveIndexCopyWith<$Res>  {
  factory $GameSaveIndexCopyWith(GameSaveIndex value, $Res Function(GameSaveIndex) _then) = _$GameSaveIndexCopyWithImpl;
@useResult
$Res call({
 String id, String name, String mapName,@JsonKey(unknownEnumValue: MapSource.asset) MapSource mapSource, int turn,@JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) DateTime savedAt, GameMode gameMode, bool replayAvailable, bool corrupted, String? corruptionMessage
});




}
/// @nodoc
class _$GameSaveIndexCopyWithImpl<$Res>
    implements $GameSaveIndexCopyWith<$Res> {
  _$GameSaveIndexCopyWithImpl(this._self, this._then);

  final GameSaveIndex _self;
  final $Res Function(GameSaveIndex) _then;

/// Create a copy of GameSaveIndex
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? mapName = null,Object? mapSource = null,Object? turn = null,Object? savedAt = null,Object? gameMode = null,Object? replayAvailable = null,Object? corrupted = null,Object? corruptionMessage = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mapName: null == mapName ? _self.mapName : mapName // ignore: cast_nullable_to_non_nullable
as String,mapSource: null == mapSource ? _self.mapSource : mapSource // ignore: cast_nullable_to_non_nullable
as MapSource,turn: null == turn ? _self.turn : turn // ignore: cast_nullable_to_non_nullable
as int,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,gameMode: null == gameMode ? _self.gameMode : gameMode // ignore: cast_nullable_to_non_nullable
as GameMode,replayAvailable: null == replayAvailable ? _self.replayAvailable : replayAvailable // ignore: cast_nullable_to_non_nullable
as bool,corrupted: null == corrupted ? _self.corrupted : corrupted // ignore: cast_nullable_to_non_nullable
as bool,corruptionMessage: freezed == corruptionMessage ? _self.corruptionMessage : corruptionMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GameSaveIndex].
extension GameSaveIndexPatterns on GameSaveIndex {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameSaveIndex value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameSaveIndex() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameSaveIndex value)  $default,){
final _that = this;
switch (_that) {
case _GameSaveIndex():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameSaveIndex value)?  $default,){
final _that = this;
switch (_that) {
case _GameSaveIndex() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String mapName, @JsonKey(unknownEnumValue: MapSource.asset)  MapSource mapSource,  int turn, @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)  DateTime savedAt,  GameMode gameMode,  bool replayAvailable,  bool corrupted,  String? corruptionMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameSaveIndex() when $default != null:
return $default(_that.id,_that.name,_that.mapName,_that.mapSource,_that.turn,_that.savedAt,_that.gameMode,_that.replayAvailable,_that.corrupted,_that.corruptionMessage);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String mapName, @JsonKey(unknownEnumValue: MapSource.asset)  MapSource mapSource,  int turn, @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)  DateTime savedAt,  GameMode gameMode,  bool replayAvailable,  bool corrupted,  String? corruptionMessage)  $default,) {final _that = this;
switch (_that) {
case _GameSaveIndex():
return $default(_that.id,_that.name,_that.mapName,_that.mapSource,_that.turn,_that.savedAt,_that.gameMode,_that.replayAvailable,_that.corrupted,_that.corruptionMessage);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String mapName, @JsonKey(unknownEnumValue: MapSource.asset)  MapSource mapSource,  int turn, @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)  DateTime savedAt,  GameMode gameMode,  bool replayAvailable,  bool corrupted,  String? corruptionMessage)?  $default,) {final _that = this;
switch (_that) {
case _GameSaveIndex() when $default != null:
return $default(_that.id,_that.name,_that.mapName,_that.mapSource,_that.turn,_that.savedAt,_that.gameMode,_that.replayAvailable,_that.corrupted,_that.corruptionMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GameSaveIndex extends GameSaveIndex {
  const _GameSaveIndex({required this.id, required this.name, required this.mapName, @JsonKey(unknownEnumValue: MapSource.asset) this.mapSource = MapSource.asset, required this.turn, @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) required this.savedAt, this.gameMode = GameMode.hotSeat, this.replayAvailable = false, this.corrupted = false, this.corruptionMessage}): super._();
  factory _GameSaveIndex.fromJson(Map<String, dynamic> json) => _$GameSaveIndexFromJson(json);

@override final  String id;
@override final  String name;
@override final  String mapName;
@override@JsonKey(unknownEnumValue: MapSource.asset) final  MapSource mapSource;
@override final  int turn;
@override@JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) final  DateTime savedAt;
@override@JsonKey() final  GameMode gameMode;
@override@JsonKey() final  bool replayAvailable;
@override@JsonKey() final  bool corrupted;
@override final  String? corruptionMessage;

/// Create a copy of GameSaveIndex
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameSaveIndexCopyWith<_GameSaveIndex> get copyWith => __$GameSaveIndexCopyWithImpl<_GameSaveIndex>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameSaveIndexToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameSaveIndex&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.mapName, mapName) || other.mapName == mapName)&&(identical(other.mapSource, mapSource) || other.mapSource == mapSource)&&(identical(other.turn, turn) || other.turn == turn)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&(identical(other.gameMode, gameMode) || other.gameMode == gameMode)&&(identical(other.replayAvailable, replayAvailable) || other.replayAvailable == replayAvailable)&&(identical(other.corrupted, corrupted) || other.corrupted == corrupted)&&(identical(other.corruptionMessage, corruptionMessage) || other.corruptionMessage == corruptionMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,mapName,mapSource,turn,savedAt,gameMode,replayAvailable,corrupted,corruptionMessage);

@override
String toString() {
  return 'GameSaveIndex(id: $id, name: $name, mapName: $mapName, mapSource: $mapSource, turn: $turn, savedAt: $savedAt, gameMode: $gameMode, replayAvailable: $replayAvailable, corrupted: $corrupted, corruptionMessage: $corruptionMessage)';
}


}

/// @nodoc
abstract mixin class _$GameSaveIndexCopyWith<$Res> implements $GameSaveIndexCopyWith<$Res> {
  factory _$GameSaveIndexCopyWith(_GameSaveIndex value, $Res Function(_GameSaveIndex) _then) = __$GameSaveIndexCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String mapName,@JsonKey(unknownEnumValue: MapSource.asset) MapSource mapSource, int turn,@JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) DateTime savedAt, GameMode gameMode, bool replayAvailable, bool corrupted, String? corruptionMessage
});




}
/// @nodoc
class __$GameSaveIndexCopyWithImpl<$Res>
    implements _$GameSaveIndexCopyWith<$Res> {
  __$GameSaveIndexCopyWithImpl(this._self, this._then);

  final _GameSaveIndex _self;
  final $Res Function(_GameSaveIndex) _then;

/// Create a copy of GameSaveIndex
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? mapName = null,Object? mapSource = null,Object? turn = null,Object? savedAt = null,Object? gameMode = null,Object? replayAvailable = null,Object? corrupted = null,Object? corruptionMessage = freezed,}) {
  return _then(_GameSaveIndex(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mapName: null == mapName ? _self.mapName : mapName // ignore: cast_nullable_to_non_nullable
as String,mapSource: null == mapSource ? _self.mapSource : mapSource // ignore: cast_nullable_to_non_nullable
as MapSource,turn: null == turn ? _self.turn : turn // ignore: cast_nullable_to_non_nullable
as int,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,gameMode: null == gameMode ? _self.gameMode : gameMode // ignore: cast_nullable_to_non_nullable
as GameMode,replayAvailable: null == replayAvailable ? _self.replayAvailable : replayAvailable // ignore: cast_nullable_to_non_nullable
as bool,corrupted: null == corrupted ? _self.corrupted : corrupted // ignore: cast_nullable_to_non_nullable
as bool,corruptionMessage: freezed == corruptionMessage ? _self.corruptionMessage : corruptionMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
