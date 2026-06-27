// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GameState {

 Map<String, int> get playerColors; Map<String, PlayerCountry> get playerCountries; Map<String, int> get playerGold; List<GameUnit> get units; List<GameCity> get cities; List<WorldArtifact> get artifacts; List<FieldImprovement> get fieldImprovements; FogOfWarState get fogOfWar; ResearchState get research; DiplomacyState get diplomacy; List<IntendedAttack> get intendedAttacks; List<ResourceTradeAgreement> get resourceTradeAgreements; Map<String, int> get dominationHoldTurnsByPlayerId; Map<String, int> get culturalVictoryHoldTurnsByPlayerId; Map<String, MapObjectiveHoldState> get mapObjectiveHoldStatesByObjectiveId; String get activePlayerId; bool get activePlayerCanAct; Set<String> get submittedPlayerIds; GameInteractionState get interaction;
/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameStateCopyWith<GameState> get copyWith => _$GameStateCopyWithImpl<GameState>(this as GameState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameState&&const DeepCollectionEquality().equals(other.playerColors, playerColors)&&const DeepCollectionEquality().equals(other.playerCountries, playerCountries)&&const DeepCollectionEquality().equals(other.playerGold, playerGold)&&const DeepCollectionEquality().equals(other.units, units)&&const DeepCollectionEquality().equals(other.cities, cities)&&const DeepCollectionEquality().equals(other.artifacts, artifacts)&&const DeepCollectionEquality().equals(other.fieldImprovements, fieldImprovements)&&(identical(other.fogOfWar, fogOfWar) || other.fogOfWar == fogOfWar)&&(identical(other.research, research) || other.research == research)&&(identical(other.diplomacy, diplomacy) || other.diplomacy == diplomacy)&&const DeepCollectionEquality().equals(other.intendedAttacks, intendedAttacks)&&const DeepCollectionEquality().equals(other.resourceTradeAgreements, resourceTradeAgreements)&&const DeepCollectionEquality().equals(other.dominationHoldTurnsByPlayerId, dominationHoldTurnsByPlayerId)&&const DeepCollectionEquality().equals(other.culturalVictoryHoldTurnsByPlayerId, culturalVictoryHoldTurnsByPlayerId)&&const DeepCollectionEquality().equals(other.mapObjectiveHoldStatesByObjectiveId, mapObjectiveHoldStatesByObjectiveId)&&(identical(other.activePlayerId, activePlayerId) || other.activePlayerId == activePlayerId)&&(identical(other.activePlayerCanAct, activePlayerCanAct) || other.activePlayerCanAct == activePlayerCanAct)&&const DeepCollectionEquality().equals(other.submittedPlayerIds, submittedPlayerIds)&&(identical(other.interaction, interaction) || other.interaction == interaction));
}


@override
int get hashCode => Object.hashAll([runtimeType,const DeepCollectionEquality().hash(playerColors),const DeepCollectionEquality().hash(playerCountries),const DeepCollectionEquality().hash(playerGold),const DeepCollectionEquality().hash(units),const DeepCollectionEquality().hash(cities),const DeepCollectionEquality().hash(artifacts),const DeepCollectionEquality().hash(fieldImprovements),fogOfWar,research,diplomacy,const DeepCollectionEquality().hash(intendedAttacks),const DeepCollectionEquality().hash(resourceTradeAgreements),const DeepCollectionEquality().hash(dominationHoldTurnsByPlayerId),const DeepCollectionEquality().hash(culturalVictoryHoldTurnsByPlayerId),const DeepCollectionEquality().hash(mapObjectiveHoldStatesByObjectiveId),activePlayerId,activePlayerCanAct,const DeepCollectionEquality().hash(submittedPlayerIds),interaction]);

@override
String toString() {
  return 'GameState(playerColors: $playerColors, playerCountries: $playerCountries, playerGold: $playerGold, units: $units, cities: $cities, artifacts: $artifacts, fieldImprovements: $fieldImprovements, fogOfWar: $fogOfWar, research: $research, diplomacy: $diplomacy, intendedAttacks: $intendedAttacks, resourceTradeAgreements: $resourceTradeAgreements, dominationHoldTurnsByPlayerId: $dominationHoldTurnsByPlayerId, culturalVictoryHoldTurnsByPlayerId: $culturalVictoryHoldTurnsByPlayerId, mapObjectiveHoldStatesByObjectiveId: $mapObjectiveHoldStatesByObjectiveId, activePlayerId: $activePlayerId, activePlayerCanAct: $activePlayerCanAct, submittedPlayerIds: $submittedPlayerIds, interaction: $interaction)';
}


}

/// @nodoc
abstract mixin class $GameStateCopyWith<$Res>  {
  factory $GameStateCopyWith(GameState value, $Res Function(GameState) _then) = _$GameStateCopyWithImpl;
@useResult
$Res call({
 Map<String, int> playerColors, Map<String, PlayerCountry> playerCountries, Map<String, int> playerGold, List<GameUnit> units, List<GameCity> cities, List<WorldArtifact> artifacts, List<FieldImprovement> fieldImprovements, FogOfWarState fogOfWar, ResearchState research, DiplomacyState diplomacy, List<IntendedAttack> intendedAttacks, List<ResourceTradeAgreement> resourceTradeAgreements, Map<String, int> dominationHoldTurnsByPlayerId, Map<String, int> culturalVictoryHoldTurnsByPlayerId, Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId, String activePlayerId, bool activePlayerCanAct, Set<String> submittedPlayerIds, GameInteractionState interaction
});




}
/// @nodoc
class _$GameStateCopyWithImpl<$Res>
    implements $GameStateCopyWith<$Res> {
  _$GameStateCopyWithImpl(this._self, this._then);

  final GameState _self;
  final $Res Function(GameState) _then;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerColors = null,Object? playerCountries = null,Object? playerGold = null,Object? units = null,Object? cities = null,Object? artifacts = null,Object? fieldImprovements = null,Object? fogOfWar = null,Object? research = null,Object? diplomacy = null,Object? intendedAttacks = null,Object? resourceTradeAgreements = null,Object? dominationHoldTurnsByPlayerId = null,Object? culturalVictoryHoldTurnsByPlayerId = null,Object? mapObjectiveHoldStatesByObjectiveId = null,Object? activePlayerId = null,Object? activePlayerCanAct = null,Object? submittedPlayerIds = null,Object? interaction = null,}) {
  return _then(_self.copyWith(
playerColors: null == playerColors ? _self.playerColors : playerColors // ignore: cast_nullable_to_non_nullable
as Map<String, int>,playerCountries: null == playerCountries ? _self.playerCountries : playerCountries // ignore: cast_nullable_to_non_nullable
as Map<String, PlayerCountry>,playerGold: null == playerGold ? _self.playerGold : playerGold // ignore: cast_nullable_to_non_nullable
as Map<String, int>,units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as List<GameUnit>,cities: null == cities ? _self.cities : cities // ignore: cast_nullable_to_non_nullable
as List<GameCity>,artifacts: null == artifacts ? _self.artifacts : artifacts // ignore: cast_nullable_to_non_nullable
as List<WorldArtifact>,fieldImprovements: null == fieldImprovements ? _self.fieldImprovements : fieldImprovements // ignore: cast_nullable_to_non_nullable
as List<FieldImprovement>,fogOfWar: null == fogOfWar ? _self.fogOfWar : fogOfWar // ignore: cast_nullable_to_non_nullable
as FogOfWarState,research: null == research ? _self.research : research // ignore: cast_nullable_to_non_nullable
as ResearchState,diplomacy: null == diplomacy ? _self.diplomacy : diplomacy // ignore: cast_nullable_to_non_nullable
as DiplomacyState,intendedAttacks: null == intendedAttacks ? _self.intendedAttacks : intendedAttacks // ignore: cast_nullable_to_non_nullable
as List<IntendedAttack>,resourceTradeAgreements: null == resourceTradeAgreements ? _self.resourceTradeAgreements : resourceTradeAgreements // ignore: cast_nullable_to_non_nullable
as List<ResourceTradeAgreement>,dominationHoldTurnsByPlayerId: null == dominationHoldTurnsByPlayerId ? _self.dominationHoldTurnsByPlayerId : dominationHoldTurnsByPlayerId // ignore: cast_nullable_to_non_nullable
as Map<String, int>,culturalVictoryHoldTurnsByPlayerId: null == culturalVictoryHoldTurnsByPlayerId ? _self.culturalVictoryHoldTurnsByPlayerId : culturalVictoryHoldTurnsByPlayerId // ignore: cast_nullable_to_non_nullable
as Map<String, int>,mapObjectiveHoldStatesByObjectiveId: null == mapObjectiveHoldStatesByObjectiveId ? _self.mapObjectiveHoldStatesByObjectiveId : mapObjectiveHoldStatesByObjectiveId // ignore: cast_nullable_to_non_nullable
as Map<String, MapObjectiveHoldState>,activePlayerId: null == activePlayerId ? _self.activePlayerId : activePlayerId // ignore: cast_nullable_to_non_nullable
as String,activePlayerCanAct: null == activePlayerCanAct ? _self.activePlayerCanAct : activePlayerCanAct // ignore: cast_nullable_to_non_nullable
as bool,submittedPlayerIds: null == submittedPlayerIds ? _self.submittedPlayerIds : submittedPlayerIds // ignore: cast_nullable_to_non_nullable
as Set<String>,interaction: null == interaction ? _self.interaction : interaction // ignore: cast_nullable_to_non_nullable
as GameInteractionState,
  ));
}

}


/// Adds pattern-matching-related methods to [GameState].
extension GameStatePatterns on GameState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameState value)  $default,){
final _that = this;
switch (_that) {
case _GameState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameState value)?  $default,){
final _that = this;
switch (_that) {
case _GameState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, int> playerColors,  Map<String, PlayerCountry> playerCountries,  Map<String, int> playerGold,  List<GameUnit> units,  List<GameCity> cities,  List<WorldArtifact> artifacts,  List<FieldImprovement> fieldImprovements,  FogOfWarState fogOfWar,  ResearchState research,  DiplomacyState diplomacy,  List<IntendedAttack> intendedAttacks,  List<ResourceTradeAgreement> resourceTradeAgreements,  Map<String, int> dominationHoldTurnsByPlayerId,  Map<String, int> culturalVictoryHoldTurnsByPlayerId,  Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId,  String activePlayerId,  bool activePlayerCanAct,  Set<String> submittedPlayerIds,  GameInteractionState interaction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameState() when $default != null:
return $default(_that.playerColors,_that.playerCountries,_that.playerGold,_that.units,_that.cities,_that.artifacts,_that.fieldImprovements,_that.fogOfWar,_that.research,_that.diplomacy,_that.intendedAttacks,_that.resourceTradeAgreements,_that.dominationHoldTurnsByPlayerId,_that.culturalVictoryHoldTurnsByPlayerId,_that.mapObjectiveHoldStatesByObjectiveId,_that.activePlayerId,_that.activePlayerCanAct,_that.submittedPlayerIds,_that.interaction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, int> playerColors,  Map<String, PlayerCountry> playerCountries,  Map<String, int> playerGold,  List<GameUnit> units,  List<GameCity> cities,  List<WorldArtifact> artifacts,  List<FieldImprovement> fieldImprovements,  FogOfWarState fogOfWar,  ResearchState research,  DiplomacyState diplomacy,  List<IntendedAttack> intendedAttacks,  List<ResourceTradeAgreement> resourceTradeAgreements,  Map<String, int> dominationHoldTurnsByPlayerId,  Map<String, int> culturalVictoryHoldTurnsByPlayerId,  Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId,  String activePlayerId,  bool activePlayerCanAct,  Set<String> submittedPlayerIds,  GameInteractionState interaction)  $default,) {final _that = this;
switch (_that) {
case _GameState():
return $default(_that.playerColors,_that.playerCountries,_that.playerGold,_that.units,_that.cities,_that.artifacts,_that.fieldImprovements,_that.fogOfWar,_that.research,_that.diplomacy,_that.intendedAttacks,_that.resourceTradeAgreements,_that.dominationHoldTurnsByPlayerId,_that.culturalVictoryHoldTurnsByPlayerId,_that.mapObjectiveHoldStatesByObjectiveId,_that.activePlayerId,_that.activePlayerCanAct,_that.submittedPlayerIds,_that.interaction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, int> playerColors,  Map<String, PlayerCountry> playerCountries,  Map<String, int> playerGold,  List<GameUnit> units,  List<GameCity> cities,  List<WorldArtifact> artifacts,  List<FieldImprovement> fieldImprovements,  FogOfWarState fogOfWar,  ResearchState research,  DiplomacyState diplomacy,  List<IntendedAttack> intendedAttacks,  List<ResourceTradeAgreement> resourceTradeAgreements,  Map<String, int> dominationHoldTurnsByPlayerId,  Map<String, int> culturalVictoryHoldTurnsByPlayerId,  Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId,  String activePlayerId,  bool activePlayerCanAct,  Set<String> submittedPlayerIds,  GameInteractionState interaction)?  $default,) {final _that = this;
switch (_that) {
case _GameState() when $default != null:
return $default(_that.playerColors,_that.playerCountries,_that.playerGold,_that.units,_that.cities,_that.artifacts,_that.fieldImprovements,_that.fogOfWar,_that.research,_that.diplomacy,_that.intendedAttacks,_that.resourceTradeAgreements,_that.dominationHoldTurnsByPlayerId,_that.culturalVictoryHoldTurnsByPlayerId,_that.mapObjectiveHoldStatesByObjectiveId,_that.activePlayerId,_that.activePlayerCanAct,_that.submittedPlayerIds,_that.interaction);case _:
  return null;

}
}

}

/// @nodoc


class _GameState extends GameState {
  const _GameState({final  Map<String, int> playerColors = const {}, final  Map<String, PlayerCountry> playerCountries = const {}, final  Map<String, int> playerGold = const {}, final  List<GameUnit> units = const [], final  List<GameCity> cities = const [], final  List<WorldArtifact> artifacts = const [], final  List<FieldImprovement> fieldImprovements = const [], this.fogOfWar = FogOfWarState.empty, this.research = ResearchState.empty, this.diplomacy = DiplomacyState.empty, final  List<IntendedAttack> intendedAttacks = const [], final  List<ResourceTradeAgreement> resourceTradeAgreements = const [], final  Map<String, int> dominationHoldTurnsByPlayerId = const {}, final  Map<String, int> culturalVictoryHoldTurnsByPlayerId = const {}, final  Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId = const {}, this.activePlayerId = '', this.activePlayerCanAct = true, final  Set<String> submittedPlayerIds = const {}, this.interaction = GameInteractionState.empty}): _playerColors = playerColors,_playerCountries = playerCountries,_playerGold = playerGold,_units = units,_cities = cities,_artifacts = artifacts,_fieldImprovements = fieldImprovements,_intendedAttacks = intendedAttacks,_resourceTradeAgreements = resourceTradeAgreements,_dominationHoldTurnsByPlayerId = dominationHoldTurnsByPlayerId,_culturalVictoryHoldTurnsByPlayerId = culturalVictoryHoldTurnsByPlayerId,_mapObjectiveHoldStatesByObjectiveId = mapObjectiveHoldStatesByObjectiveId,_submittedPlayerIds = submittedPlayerIds,super._();
  

 final  Map<String, int> _playerColors;
@override@JsonKey() Map<String, int> get playerColors {
  if (_playerColors is EqualUnmodifiableMapView) return _playerColors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_playerColors);
}

 final  Map<String, PlayerCountry> _playerCountries;
@override@JsonKey() Map<String, PlayerCountry> get playerCountries {
  if (_playerCountries is EqualUnmodifiableMapView) return _playerCountries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_playerCountries);
}

 final  Map<String, int> _playerGold;
@override@JsonKey() Map<String, int> get playerGold {
  if (_playerGold is EqualUnmodifiableMapView) return _playerGold;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_playerGold);
}

 final  List<GameUnit> _units;
@override@JsonKey() List<GameUnit> get units {
  if (_units is EqualUnmodifiableListView) return _units;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_units);
}

 final  List<GameCity> _cities;
@override@JsonKey() List<GameCity> get cities {
  if (_cities is EqualUnmodifiableListView) return _cities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cities);
}

 final  List<WorldArtifact> _artifacts;
@override@JsonKey() List<WorldArtifact> get artifacts {
  if (_artifacts is EqualUnmodifiableListView) return _artifacts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artifacts);
}

 final  List<FieldImprovement> _fieldImprovements;
@override@JsonKey() List<FieldImprovement> get fieldImprovements {
  if (_fieldImprovements is EqualUnmodifiableListView) return _fieldImprovements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fieldImprovements);
}

@override@JsonKey() final  FogOfWarState fogOfWar;
@override@JsonKey() final  ResearchState research;
@override@JsonKey() final  DiplomacyState diplomacy;
 final  List<IntendedAttack> _intendedAttacks;
@override@JsonKey() List<IntendedAttack> get intendedAttacks {
  if (_intendedAttacks is EqualUnmodifiableListView) return _intendedAttacks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_intendedAttacks);
}

 final  List<ResourceTradeAgreement> _resourceTradeAgreements;
@override@JsonKey() List<ResourceTradeAgreement> get resourceTradeAgreements {
  if (_resourceTradeAgreements is EqualUnmodifiableListView) return _resourceTradeAgreements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_resourceTradeAgreements);
}

 final  Map<String, int> _dominationHoldTurnsByPlayerId;
@override@JsonKey() Map<String, int> get dominationHoldTurnsByPlayerId {
  if (_dominationHoldTurnsByPlayerId is EqualUnmodifiableMapView) return _dominationHoldTurnsByPlayerId;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_dominationHoldTurnsByPlayerId);
}

 final  Map<String, int> _culturalVictoryHoldTurnsByPlayerId;
@override@JsonKey() Map<String, int> get culturalVictoryHoldTurnsByPlayerId {
  if (_culturalVictoryHoldTurnsByPlayerId is EqualUnmodifiableMapView) return _culturalVictoryHoldTurnsByPlayerId;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_culturalVictoryHoldTurnsByPlayerId);
}

 final  Map<String, MapObjectiveHoldState> _mapObjectiveHoldStatesByObjectiveId;
@override@JsonKey() Map<String, MapObjectiveHoldState> get mapObjectiveHoldStatesByObjectiveId {
  if (_mapObjectiveHoldStatesByObjectiveId is EqualUnmodifiableMapView) return _mapObjectiveHoldStatesByObjectiveId;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_mapObjectiveHoldStatesByObjectiveId);
}

@override@JsonKey() final  String activePlayerId;
@override@JsonKey() final  bool activePlayerCanAct;
 final  Set<String> _submittedPlayerIds;
@override@JsonKey() Set<String> get submittedPlayerIds {
  if (_submittedPlayerIds is EqualUnmodifiableSetView) return _submittedPlayerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_submittedPlayerIds);
}

@override@JsonKey() final  GameInteractionState interaction;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameStateCopyWith<_GameState> get copyWith => __$GameStateCopyWithImpl<_GameState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameState&&const DeepCollectionEquality().equals(other._playerColors, _playerColors)&&const DeepCollectionEquality().equals(other._playerCountries, _playerCountries)&&const DeepCollectionEquality().equals(other._playerGold, _playerGold)&&const DeepCollectionEquality().equals(other._units, _units)&&const DeepCollectionEquality().equals(other._cities, _cities)&&const DeepCollectionEquality().equals(other._artifacts, _artifacts)&&const DeepCollectionEquality().equals(other._fieldImprovements, _fieldImprovements)&&(identical(other.fogOfWar, fogOfWar) || other.fogOfWar == fogOfWar)&&(identical(other.research, research) || other.research == research)&&(identical(other.diplomacy, diplomacy) || other.diplomacy == diplomacy)&&const DeepCollectionEquality().equals(other._intendedAttacks, _intendedAttacks)&&const DeepCollectionEquality().equals(other._resourceTradeAgreements, _resourceTradeAgreements)&&const DeepCollectionEquality().equals(other._dominationHoldTurnsByPlayerId, _dominationHoldTurnsByPlayerId)&&const DeepCollectionEquality().equals(other._culturalVictoryHoldTurnsByPlayerId, _culturalVictoryHoldTurnsByPlayerId)&&const DeepCollectionEquality().equals(other._mapObjectiveHoldStatesByObjectiveId, _mapObjectiveHoldStatesByObjectiveId)&&(identical(other.activePlayerId, activePlayerId) || other.activePlayerId == activePlayerId)&&(identical(other.activePlayerCanAct, activePlayerCanAct) || other.activePlayerCanAct == activePlayerCanAct)&&const DeepCollectionEquality().equals(other._submittedPlayerIds, _submittedPlayerIds)&&(identical(other.interaction, interaction) || other.interaction == interaction));
}


@override
int get hashCode => Object.hashAll([runtimeType,const DeepCollectionEquality().hash(_playerColors),const DeepCollectionEquality().hash(_playerCountries),const DeepCollectionEquality().hash(_playerGold),const DeepCollectionEquality().hash(_units),const DeepCollectionEquality().hash(_cities),const DeepCollectionEquality().hash(_artifacts),const DeepCollectionEquality().hash(_fieldImprovements),fogOfWar,research,diplomacy,const DeepCollectionEquality().hash(_intendedAttacks),const DeepCollectionEquality().hash(_resourceTradeAgreements),const DeepCollectionEquality().hash(_dominationHoldTurnsByPlayerId),const DeepCollectionEquality().hash(_culturalVictoryHoldTurnsByPlayerId),const DeepCollectionEquality().hash(_mapObjectiveHoldStatesByObjectiveId),activePlayerId,activePlayerCanAct,const DeepCollectionEquality().hash(_submittedPlayerIds),interaction]);

@override
String toString() {
  return 'GameState(playerColors: $playerColors, playerCountries: $playerCountries, playerGold: $playerGold, units: $units, cities: $cities, artifacts: $artifacts, fieldImprovements: $fieldImprovements, fogOfWar: $fogOfWar, research: $research, diplomacy: $diplomacy, intendedAttacks: $intendedAttacks, resourceTradeAgreements: $resourceTradeAgreements, dominationHoldTurnsByPlayerId: $dominationHoldTurnsByPlayerId, culturalVictoryHoldTurnsByPlayerId: $culturalVictoryHoldTurnsByPlayerId, mapObjectiveHoldStatesByObjectiveId: $mapObjectiveHoldStatesByObjectiveId, activePlayerId: $activePlayerId, activePlayerCanAct: $activePlayerCanAct, submittedPlayerIds: $submittedPlayerIds, interaction: $interaction)';
}


}

/// @nodoc
abstract mixin class _$GameStateCopyWith<$Res> implements $GameStateCopyWith<$Res> {
  factory _$GameStateCopyWith(_GameState value, $Res Function(_GameState) _then) = __$GameStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, int> playerColors, Map<String, PlayerCountry> playerCountries, Map<String, int> playerGold, List<GameUnit> units, List<GameCity> cities, List<WorldArtifact> artifacts, List<FieldImprovement> fieldImprovements, FogOfWarState fogOfWar, ResearchState research, DiplomacyState diplomacy, List<IntendedAttack> intendedAttacks, List<ResourceTradeAgreement> resourceTradeAgreements, Map<String, int> dominationHoldTurnsByPlayerId, Map<String, int> culturalVictoryHoldTurnsByPlayerId, Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId, String activePlayerId, bool activePlayerCanAct, Set<String> submittedPlayerIds, GameInteractionState interaction
});




}
/// @nodoc
class __$GameStateCopyWithImpl<$Res>
    implements _$GameStateCopyWith<$Res> {
  __$GameStateCopyWithImpl(this._self, this._then);

  final _GameState _self;
  final $Res Function(_GameState) _then;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerColors = null,Object? playerCountries = null,Object? playerGold = null,Object? units = null,Object? cities = null,Object? artifacts = null,Object? fieldImprovements = null,Object? fogOfWar = null,Object? research = null,Object? diplomacy = null,Object? intendedAttacks = null,Object? resourceTradeAgreements = null,Object? dominationHoldTurnsByPlayerId = null,Object? culturalVictoryHoldTurnsByPlayerId = null,Object? mapObjectiveHoldStatesByObjectiveId = null,Object? activePlayerId = null,Object? activePlayerCanAct = null,Object? submittedPlayerIds = null,Object? interaction = null,}) {
  return _then(_GameState(
playerColors: null == playerColors ? _self._playerColors : playerColors // ignore: cast_nullable_to_non_nullable
as Map<String, int>,playerCountries: null == playerCountries ? _self._playerCountries : playerCountries // ignore: cast_nullable_to_non_nullable
as Map<String, PlayerCountry>,playerGold: null == playerGold ? _self._playerGold : playerGold // ignore: cast_nullable_to_non_nullable
as Map<String, int>,units: null == units ? _self._units : units // ignore: cast_nullable_to_non_nullable
as List<GameUnit>,cities: null == cities ? _self._cities : cities // ignore: cast_nullable_to_non_nullable
as List<GameCity>,artifacts: null == artifacts ? _self._artifacts : artifacts // ignore: cast_nullable_to_non_nullable
as List<WorldArtifact>,fieldImprovements: null == fieldImprovements ? _self._fieldImprovements : fieldImprovements // ignore: cast_nullable_to_non_nullable
as List<FieldImprovement>,fogOfWar: null == fogOfWar ? _self.fogOfWar : fogOfWar // ignore: cast_nullable_to_non_nullable
as FogOfWarState,research: null == research ? _self.research : research // ignore: cast_nullable_to_non_nullable
as ResearchState,diplomacy: null == diplomacy ? _self.diplomacy : diplomacy // ignore: cast_nullable_to_non_nullable
as DiplomacyState,intendedAttacks: null == intendedAttacks ? _self._intendedAttacks : intendedAttacks // ignore: cast_nullable_to_non_nullable
as List<IntendedAttack>,resourceTradeAgreements: null == resourceTradeAgreements ? _self._resourceTradeAgreements : resourceTradeAgreements // ignore: cast_nullable_to_non_nullable
as List<ResourceTradeAgreement>,dominationHoldTurnsByPlayerId: null == dominationHoldTurnsByPlayerId ? _self._dominationHoldTurnsByPlayerId : dominationHoldTurnsByPlayerId // ignore: cast_nullable_to_non_nullable
as Map<String, int>,culturalVictoryHoldTurnsByPlayerId: null == culturalVictoryHoldTurnsByPlayerId ? _self._culturalVictoryHoldTurnsByPlayerId : culturalVictoryHoldTurnsByPlayerId // ignore: cast_nullable_to_non_nullable
as Map<String, int>,mapObjectiveHoldStatesByObjectiveId: null == mapObjectiveHoldStatesByObjectiveId ? _self._mapObjectiveHoldStatesByObjectiveId : mapObjectiveHoldStatesByObjectiveId // ignore: cast_nullable_to_non_nullable
as Map<String, MapObjectiveHoldState>,activePlayerId: null == activePlayerId ? _self.activePlayerId : activePlayerId // ignore: cast_nullable_to_non_nullable
as String,activePlayerCanAct: null == activePlayerCanAct ? _self.activePlayerCanAct : activePlayerCanAct // ignore: cast_nullable_to_non_nullable
as bool,submittedPlayerIds: null == submittedPlayerIds ? _self._submittedPlayerIds : submittedPlayerIds // ignore: cast_nullable_to_non_nullable
as Set<String>,interaction: null == interaction ? _self.interaction : interaction // ignore: cast_nullable_to_non_nullable
as GameInteractionState,
  ));
}


}

// dart format on
