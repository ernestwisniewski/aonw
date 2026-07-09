// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_runtime_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GameRuntimeState {

 CityFoundingDraft? get cityFoundingDraft; PendingPlayerAction? get pendingAction; Set<String> get submittedPlayerIds; Map<String, int> get timeoutStreaksByPlayerId; Set<String> get afkPlayerIds; Set<String> get kickedPlayerIds; List<IntendedAttack> get intendedAttacks; DiplomacyState get diplomacy; Map<String, int> get dominationHoldTurnsByPlayerId; Map<String, int> get culturalVictoryHoldTurnsByPlayerId; Map<String, MapObjectiveHoldState> get mapObjectiveHoldStatesByObjectiveId; List<ResourceTradeAgreement> get resourceTradeAgreements; DateTime? get turnStartedAt;
/// Create a copy of GameRuntimeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameRuntimeStateCopyWith<GameRuntimeState> get copyWith => _$GameRuntimeStateCopyWithImpl<GameRuntimeState>(this as GameRuntimeState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameRuntimeState&&(identical(other.cityFoundingDraft, cityFoundingDraft) || other.cityFoundingDraft == cityFoundingDraft)&&(identical(other.pendingAction, pendingAction) || other.pendingAction == pendingAction)&&const DeepCollectionEquality().equals(other.submittedPlayerIds, submittedPlayerIds)&&const DeepCollectionEquality().equals(other.timeoutStreaksByPlayerId, timeoutStreaksByPlayerId)&&const DeepCollectionEquality().equals(other.afkPlayerIds, afkPlayerIds)&&const DeepCollectionEquality().equals(other.kickedPlayerIds, kickedPlayerIds)&&const DeepCollectionEquality().equals(other.intendedAttacks, intendedAttacks)&&(identical(other.diplomacy, diplomacy) || other.diplomacy == diplomacy)&&const DeepCollectionEquality().equals(other.dominationHoldTurnsByPlayerId, dominationHoldTurnsByPlayerId)&&const DeepCollectionEquality().equals(other.culturalVictoryHoldTurnsByPlayerId, culturalVictoryHoldTurnsByPlayerId)&&const DeepCollectionEquality().equals(other.mapObjectiveHoldStatesByObjectiveId, mapObjectiveHoldStatesByObjectiveId)&&const DeepCollectionEquality().equals(other.resourceTradeAgreements, resourceTradeAgreements)&&(identical(other.turnStartedAt, turnStartedAt) || other.turnStartedAt == turnStartedAt));
}


@override
int get hashCode => Object.hash(runtimeType,cityFoundingDraft,pendingAction,const DeepCollectionEquality().hash(submittedPlayerIds),const DeepCollectionEquality().hash(timeoutStreaksByPlayerId),const DeepCollectionEquality().hash(afkPlayerIds),const DeepCollectionEquality().hash(kickedPlayerIds),const DeepCollectionEquality().hash(intendedAttacks),diplomacy,const DeepCollectionEquality().hash(dominationHoldTurnsByPlayerId),const DeepCollectionEquality().hash(culturalVictoryHoldTurnsByPlayerId),const DeepCollectionEquality().hash(mapObjectiveHoldStatesByObjectiveId),const DeepCollectionEquality().hash(resourceTradeAgreements),turnStartedAt);

@override
String toString() {
  return 'GameRuntimeState(cityFoundingDraft: $cityFoundingDraft, pendingAction: $pendingAction, submittedPlayerIds: $submittedPlayerIds, timeoutStreaksByPlayerId: $timeoutStreaksByPlayerId, afkPlayerIds: $afkPlayerIds, kickedPlayerIds: $kickedPlayerIds, intendedAttacks: $intendedAttacks, diplomacy: $diplomacy, dominationHoldTurnsByPlayerId: $dominationHoldTurnsByPlayerId, culturalVictoryHoldTurnsByPlayerId: $culturalVictoryHoldTurnsByPlayerId, mapObjectiveHoldStatesByObjectiveId: $mapObjectiveHoldStatesByObjectiveId, resourceTradeAgreements: $resourceTradeAgreements, turnStartedAt: $turnStartedAt)';
}


}

/// @nodoc
abstract mixin class $GameRuntimeStateCopyWith<$Res>  {
  factory $GameRuntimeStateCopyWith(GameRuntimeState value, $Res Function(GameRuntimeState) _then) = _$GameRuntimeStateCopyWithImpl;
@useResult
$Res call({
 CityFoundingDraft? cityFoundingDraft, PendingPlayerAction? pendingAction, Set<String> submittedPlayerIds, Map<String, int> timeoutStreaksByPlayerId, Set<String> afkPlayerIds, Set<String> kickedPlayerIds, List<IntendedAttack> intendedAttacks, DiplomacyState diplomacy, Map<String, int> dominationHoldTurnsByPlayerId, Map<String, int> culturalVictoryHoldTurnsByPlayerId, Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId, List<ResourceTradeAgreement> resourceTradeAgreements, DateTime? turnStartedAt
});




}
/// @nodoc
class _$GameRuntimeStateCopyWithImpl<$Res>
    implements $GameRuntimeStateCopyWith<$Res> {
  _$GameRuntimeStateCopyWithImpl(this._self, this._then);

  final GameRuntimeState _self;
  final $Res Function(GameRuntimeState) _then;

/// Create a copy of GameRuntimeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cityFoundingDraft = freezed,Object? pendingAction = freezed,Object? submittedPlayerIds = null,Object? timeoutStreaksByPlayerId = null,Object? afkPlayerIds = null,Object? kickedPlayerIds = null,Object? intendedAttacks = null,Object? diplomacy = null,Object? dominationHoldTurnsByPlayerId = null,Object? culturalVictoryHoldTurnsByPlayerId = null,Object? mapObjectiveHoldStatesByObjectiveId = null,Object? resourceTradeAgreements = null,Object? turnStartedAt = freezed,}) {
  return _then(_self.copyWith(
cityFoundingDraft: freezed == cityFoundingDraft ? _self.cityFoundingDraft : cityFoundingDraft // ignore: cast_nullable_to_non_nullable
as CityFoundingDraft?,pendingAction: freezed == pendingAction ? _self.pendingAction : pendingAction // ignore: cast_nullable_to_non_nullable
as PendingPlayerAction?,submittedPlayerIds: null == submittedPlayerIds ? _self.submittedPlayerIds : submittedPlayerIds // ignore: cast_nullable_to_non_nullable
as Set<String>,timeoutStreaksByPlayerId: null == timeoutStreaksByPlayerId ? _self.timeoutStreaksByPlayerId : timeoutStreaksByPlayerId // ignore: cast_nullable_to_non_nullable
as Map<String, int>,afkPlayerIds: null == afkPlayerIds ? _self.afkPlayerIds : afkPlayerIds // ignore: cast_nullable_to_non_nullable
as Set<String>,kickedPlayerIds: null == kickedPlayerIds ? _self.kickedPlayerIds : kickedPlayerIds // ignore: cast_nullable_to_non_nullable
as Set<String>,intendedAttacks: null == intendedAttacks ? _self.intendedAttacks : intendedAttacks // ignore: cast_nullable_to_non_nullable
as List<IntendedAttack>,diplomacy: null == diplomacy ? _self.diplomacy : diplomacy // ignore: cast_nullable_to_non_nullable
as DiplomacyState,dominationHoldTurnsByPlayerId: null == dominationHoldTurnsByPlayerId ? _self.dominationHoldTurnsByPlayerId : dominationHoldTurnsByPlayerId // ignore: cast_nullable_to_non_nullable
as Map<String, int>,culturalVictoryHoldTurnsByPlayerId: null == culturalVictoryHoldTurnsByPlayerId ? _self.culturalVictoryHoldTurnsByPlayerId : culturalVictoryHoldTurnsByPlayerId // ignore: cast_nullable_to_non_nullable
as Map<String, int>,mapObjectiveHoldStatesByObjectiveId: null == mapObjectiveHoldStatesByObjectiveId ? _self.mapObjectiveHoldStatesByObjectiveId : mapObjectiveHoldStatesByObjectiveId // ignore: cast_nullable_to_non_nullable
as Map<String, MapObjectiveHoldState>,resourceTradeAgreements: null == resourceTradeAgreements ? _self.resourceTradeAgreements : resourceTradeAgreements // ignore: cast_nullable_to_non_nullable
as List<ResourceTradeAgreement>,turnStartedAt: freezed == turnStartedAt ? _self.turnStartedAt : turnStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GameRuntimeState].
extension GameRuntimeStatePatterns on GameRuntimeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameRuntimeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameRuntimeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameRuntimeState value)  $default,){
final _that = this;
switch (_that) {
case _GameRuntimeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameRuntimeState value)?  $default,){
final _that = this;
switch (_that) {
case _GameRuntimeState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CityFoundingDraft? cityFoundingDraft,  PendingPlayerAction? pendingAction,  Set<String> submittedPlayerIds,  Map<String, int> timeoutStreaksByPlayerId,  Set<String> afkPlayerIds,  Set<String> kickedPlayerIds,  List<IntendedAttack> intendedAttacks,  DiplomacyState diplomacy,  Map<String, int> dominationHoldTurnsByPlayerId,  Map<String, int> culturalVictoryHoldTurnsByPlayerId,  Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId,  List<ResourceTradeAgreement> resourceTradeAgreements,  DateTime? turnStartedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameRuntimeState() when $default != null:
return $default(_that.cityFoundingDraft,_that.pendingAction,_that.submittedPlayerIds,_that.timeoutStreaksByPlayerId,_that.afkPlayerIds,_that.kickedPlayerIds,_that.intendedAttacks,_that.diplomacy,_that.dominationHoldTurnsByPlayerId,_that.culturalVictoryHoldTurnsByPlayerId,_that.mapObjectiveHoldStatesByObjectiveId,_that.resourceTradeAgreements,_that.turnStartedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CityFoundingDraft? cityFoundingDraft,  PendingPlayerAction? pendingAction,  Set<String> submittedPlayerIds,  Map<String, int> timeoutStreaksByPlayerId,  Set<String> afkPlayerIds,  Set<String> kickedPlayerIds,  List<IntendedAttack> intendedAttacks,  DiplomacyState diplomacy,  Map<String, int> dominationHoldTurnsByPlayerId,  Map<String, int> culturalVictoryHoldTurnsByPlayerId,  Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId,  List<ResourceTradeAgreement> resourceTradeAgreements,  DateTime? turnStartedAt)  $default,) {final _that = this;
switch (_that) {
case _GameRuntimeState():
return $default(_that.cityFoundingDraft,_that.pendingAction,_that.submittedPlayerIds,_that.timeoutStreaksByPlayerId,_that.afkPlayerIds,_that.kickedPlayerIds,_that.intendedAttacks,_that.diplomacy,_that.dominationHoldTurnsByPlayerId,_that.culturalVictoryHoldTurnsByPlayerId,_that.mapObjectiveHoldStatesByObjectiveId,_that.resourceTradeAgreements,_that.turnStartedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CityFoundingDraft? cityFoundingDraft,  PendingPlayerAction? pendingAction,  Set<String> submittedPlayerIds,  Map<String, int> timeoutStreaksByPlayerId,  Set<String> afkPlayerIds,  Set<String> kickedPlayerIds,  List<IntendedAttack> intendedAttacks,  DiplomacyState diplomacy,  Map<String, int> dominationHoldTurnsByPlayerId,  Map<String, int> culturalVictoryHoldTurnsByPlayerId,  Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId,  List<ResourceTradeAgreement> resourceTradeAgreements,  DateTime? turnStartedAt)?  $default,) {final _that = this;
switch (_that) {
case _GameRuntimeState() when $default != null:
return $default(_that.cityFoundingDraft,_that.pendingAction,_that.submittedPlayerIds,_that.timeoutStreaksByPlayerId,_that.afkPlayerIds,_that.kickedPlayerIds,_that.intendedAttacks,_that.diplomacy,_that.dominationHoldTurnsByPlayerId,_that.culturalVictoryHoldTurnsByPlayerId,_that.mapObjectiveHoldStatesByObjectiveId,_that.resourceTradeAgreements,_that.turnStartedAt);case _:
  return null;

}
}

}

/// @nodoc


class _GameRuntimeState extends GameRuntimeState {
  const _GameRuntimeState({this.cityFoundingDraft, this.pendingAction, final  Set<String> submittedPlayerIds = const <String>{}, final  Map<String, int> timeoutStreaksByPlayerId = const <String, int>{}, final  Set<String> afkPlayerIds = const <String>{}, final  Set<String> kickedPlayerIds = const <String>{}, final  List<IntendedAttack> intendedAttacks = const <IntendedAttack>[], this.diplomacy = DiplomacyState.empty, final  Map<String, int> dominationHoldTurnsByPlayerId = const <String, int>{}, final  Map<String, int> culturalVictoryHoldTurnsByPlayerId = const <String, int>{}, final  Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId = const <String, MapObjectiveHoldState>{}, final  List<ResourceTradeAgreement> resourceTradeAgreements = const <ResourceTradeAgreement>[], this.turnStartedAt}): _submittedPlayerIds = submittedPlayerIds,_timeoutStreaksByPlayerId = timeoutStreaksByPlayerId,_afkPlayerIds = afkPlayerIds,_kickedPlayerIds = kickedPlayerIds,_intendedAttacks = intendedAttacks,_dominationHoldTurnsByPlayerId = dominationHoldTurnsByPlayerId,_culturalVictoryHoldTurnsByPlayerId = culturalVictoryHoldTurnsByPlayerId,_mapObjectiveHoldStatesByObjectiveId = mapObjectiveHoldStatesByObjectiveId,_resourceTradeAgreements = resourceTradeAgreements,super._();
  

@override final  CityFoundingDraft? cityFoundingDraft;
@override final  PendingPlayerAction? pendingAction;
 final  Set<String> _submittedPlayerIds;
@override@JsonKey() Set<String> get submittedPlayerIds {
  if (_submittedPlayerIds is EqualUnmodifiableSetView) return _submittedPlayerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_submittedPlayerIds);
}

 final  Map<String, int> _timeoutStreaksByPlayerId;
@override@JsonKey() Map<String, int> get timeoutStreaksByPlayerId {
  if (_timeoutStreaksByPlayerId is EqualUnmodifiableMapView) return _timeoutStreaksByPlayerId;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_timeoutStreaksByPlayerId);
}

 final  Set<String> _afkPlayerIds;
@override@JsonKey() Set<String> get afkPlayerIds {
  if (_afkPlayerIds is EqualUnmodifiableSetView) return _afkPlayerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_afkPlayerIds);
}

 final  Set<String> _kickedPlayerIds;
@override@JsonKey() Set<String> get kickedPlayerIds {
  if (_kickedPlayerIds is EqualUnmodifiableSetView) return _kickedPlayerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_kickedPlayerIds);
}

 final  List<IntendedAttack> _intendedAttacks;
@override@JsonKey() List<IntendedAttack> get intendedAttacks {
  if (_intendedAttacks is EqualUnmodifiableListView) return _intendedAttacks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_intendedAttacks);
}

@override@JsonKey() final  DiplomacyState diplomacy;
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

 final  List<ResourceTradeAgreement> _resourceTradeAgreements;
@override@JsonKey() List<ResourceTradeAgreement> get resourceTradeAgreements {
  if (_resourceTradeAgreements is EqualUnmodifiableListView) return _resourceTradeAgreements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_resourceTradeAgreements);
}

@override final  DateTime? turnStartedAt;

/// Create a copy of GameRuntimeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameRuntimeStateCopyWith<_GameRuntimeState> get copyWith => __$GameRuntimeStateCopyWithImpl<_GameRuntimeState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameRuntimeState&&(identical(other.cityFoundingDraft, cityFoundingDraft) || other.cityFoundingDraft == cityFoundingDraft)&&(identical(other.pendingAction, pendingAction) || other.pendingAction == pendingAction)&&const DeepCollectionEquality().equals(other._submittedPlayerIds, _submittedPlayerIds)&&const DeepCollectionEquality().equals(other._timeoutStreaksByPlayerId, _timeoutStreaksByPlayerId)&&const DeepCollectionEquality().equals(other._afkPlayerIds, _afkPlayerIds)&&const DeepCollectionEquality().equals(other._kickedPlayerIds, _kickedPlayerIds)&&const DeepCollectionEquality().equals(other._intendedAttacks, _intendedAttacks)&&(identical(other.diplomacy, diplomacy) || other.diplomacy == diplomacy)&&const DeepCollectionEquality().equals(other._dominationHoldTurnsByPlayerId, _dominationHoldTurnsByPlayerId)&&const DeepCollectionEquality().equals(other._culturalVictoryHoldTurnsByPlayerId, _culturalVictoryHoldTurnsByPlayerId)&&const DeepCollectionEquality().equals(other._mapObjectiveHoldStatesByObjectiveId, _mapObjectiveHoldStatesByObjectiveId)&&const DeepCollectionEquality().equals(other._resourceTradeAgreements, _resourceTradeAgreements)&&(identical(other.turnStartedAt, turnStartedAt) || other.turnStartedAt == turnStartedAt));
}


@override
int get hashCode => Object.hash(runtimeType,cityFoundingDraft,pendingAction,const DeepCollectionEquality().hash(_submittedPlayerIds),const DeepCollectionEquality().hash(_timeoutStreaksByPlayerId),const DeepCollectionEquality().hash(_afkPlayerIds),const DeepCollectionEquality().hash(_kickedPlayerIds),const DeepCollectionEquality().hash(_intendedAttacks),diplomacy,const DeepCollectionEquality().hash(_dominationHoldTurnsByPlayerId),const DeepCollectionEquality().hash(_culturalVictoryHoldTurnsByPlayerId),const DeepCollectionEquality().hash(_mapObjectiveHoldStatesByObjectiveId),const DeepCollectionEquality().hash(_resourceTradeAgreements),turnStartedAt);

@override
String toString() {
  return 'GameRuntimeState(cityFoundingDraft: $cityFoundingDraft, pendingAction: $pendingAction, submittedPlayerIds: $submittedPlayerIds, timeoutStreaksByPlayerId: $timeoutStreaksByPlayerId, afkPlayerIds: $afkPlayerIds, kickedPlayerIds: $kickedPlayerIds, intendedAttacks: $intendedAttacks, diplomacy: $diplomacy, dominationHoldTurnsByPlayerId: $dominationHoldTurnsByPlayerId, culturalVictoryHoldTurnsByPlayerId: $culturalVictoryHoldTurnsByPlayerId, mapObjectiveHoldStatesByObjectiveId: $mapObjectiveHoldStatesByObjectiveId, resourceTradeAgreements: $resourceTradeAgreements, turnStartedAt: $turnStartedAt)';
}


}

/// @nodoc
abstract mixin class _$GameRuntimeStateCopyWith<$Res> implements $GameRuntimeStateCopyWith<$Res> {
  factory _$GameRuntimeStateCopyWith(_GameRuntimeState value, $Res Function(_GameRuntimeState) _then) = __$GameRuntimeStateCopyWithImpl;
@override @useResult
$Res call({
 CityFoundingDraft? cityFoundingDraft, PendingPlayerAction? pendingAction, Set<String> submittedPlayerIds, Map<String, int> timeoutStreaksByPlayerId, Set<String> afkPlayerIds, Set<String> kickedPlayerIds, List<IntendedAttack> intendedAttacks, DiplomacyState diplomacy, Map<String, int> dominationHoldTurnsByPlayerId, Map<String, int> culturalVictoryHoldTurnsByPlayerId, Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId, List<ResourceTradeAgreement> resourceTradeAgreements, DateTime? turnStartedAt
});




}
/// @nodoc
class __$GameRuntimeStateCopyWithImpl<$Res>
    implements _$GameRuntimeStateCopyWith<$Res> {
  __$GameRuntimeStateCopyWithImpl(this._self, this._then);

  final _GameRuntimeState _self;
  final $Res Function(_GameRuntimeState) _then;

/// Create a copy of GameRuntimeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cityFoundingDraft = freezed,Object? pendingAction = freezed,Object? submittedPlayerIds = null,Object? timeoutStreaksByPlayerId = null,Object? afkPlayerIds = null,Object? kickedPlayerIds = null,Object? intendedAttacks = null,Object? diplomacy = null,Object? dominationHoldTurnsByPlayerId = null,Object? culturalVictoryHoldTurnsByPlayerId = null,Object? mapObjectiveHoldStatesByObjectiveId = null,Object? resourceTradeAgreements = null,Object? turnStartedAt = freezed,}) {
  return _then(_GameRuntimeState(
cityFoundingDraft: freezed == cityFoundingDraft ? _self.cityFoundingDraft : cityFoundingDraft // ignore: cast_nullable_to_non_nullable
as CityFoundingDraft?,pendingAction: freezed == pendingAction ? _self.pendingAction : pendingAction // ignore: cast_nullable_to_non_nullable
as PendingPlayerAction?,submittedPlayerIds: null == submittedPlayerIds ? _self._submittedPlayerIds : submittedPlayerIds // ignore: cast_nullable_to_non_nullable
as Set<String>,timeoutStreaksByPlayerId: null == timeoutStreaksByPlayerId ? _self._timeoutStreaksByPlayerId : timeoutStreaksByPlayerId // ignore: cast_nullable_to_non_nullable
as Map<String, int>,afkPlayerIds: null == afkPlayerIds ? _self._afkPlayerIds : afkPlayerIds // ignore: cast_nullable_to_non_nullable
as Set<String>,kickedPlayerIds: null == kickedPlayerIds ? _self._kickedPlayerIds : kickedPlayerIds // ignore: cast_nullable_to_non_nullable
as Set<String>,intendedAttacks: null == intendedAttacks ? _self._intendedAttacks : intendedAttacks // ignore: cast_nullable_to_non_nullable
as List<IntendedAttack>,diplomacy: null == diplomacy ? _self.diplomacy : diplomacy // ignore: cast_nullable_to_non_nullable
as DiplomacyState,dominationHoldTurnsByPlayerId: null == dominationHoldTurnsByPlayerId ? _self._dominationHoldTurnsByPlayerId : dominationHoldTurnsByPlayerId // ignore: cast_nullable_to_non_nullable
as Map<String, int>,culturalVictoryHoldTurnsByPlayerId: null == culturalVictoryHoldTurnsByPlayerId ? _self._culturalVictoryHoldTurnsByPlayerId : culturalVictoryHoldTurnsByPlayerId // ignore: cast_nullable_to_non_nullable
as Map<String, int>,mapObjectiveHoldStatesByObjectiveId: null == mapObjectiveHoldStatesByObjectiveId ? _self._mapObjectiveHoldStatesByObjectiveId : mapObjectiveHoldStatesByObjectiveId // ignore: cast_nullable_to_non_nullable
as Map<String, MapObjectiveHoldState>,resourceTradeAgreements: null == resourceTradeAgreements ? _self._resourceTradeAgreements : resourceTradeAgreements // ignore: cast_nullable_to_non_nullable
as List<ResourceTradeAgreement>,turnStartedAt: freezed == turnStartedAt ? _self.turnStartedAt : turnStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$PendingWorkerActionSelection {

 String get ownerPlayerId; String get unitId; FieldImprovementType? get improvementType;
/// Create a copy of PendingWorkerActionSelection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingWorkerActionSelectionCopyWith<PendingWorkerActionSelection> get copyWith => _$PendingWorkerActionSelectionCopyWithImpl<PendingWorkerActionSelection>(this as PendingWorkerActionSelection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingWorkerActionSelection&&super == other&&(identical(other.ownerPlayerId, ownerPlayerId) || other.ownerPlayerId == ownerPlayerId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.improvementType, improvementType) || other.improvementType == improvementType));
}


@override
int get hashCode => Object.hash(runtimeType,super.hashCode,ownerPlayerId,unitId,improvementType);

@override
String toString() {
  return 'PendingWorkerActionSelection(ownerPlayerId: $ownerPlayerId, unitId: $unitId, improvementType: $improvementType)';
}


}

/// @nodoc
abstract mixin class $PendingWorkerActionSelectionCopyWith<$Res>  {
  factory $PendingWorkerActionSelectionCopyWith(PendingWorkerActionSelection value, $Res Function(PendingWorkerActionSelection) _then) = _$PendingWorkerActionSelectionCopyWithImpl;
@useResult
$Res call({
 String ownerPlayerId, String unitId, FieldImprovementType? improvementType
});




}
/// @nodoc
class _$PendingWorkerActionSelectionCopyWithImpl<$Res>
    implements $PendingWorkerActionSelectionCopyWith<$Res> {
  _$PendingWorkerActionSelectionCopyWithImpl(this._self, this._then);

  final PendingWorkerActionSelection _self;
  final $Res Function(PendingWorkerActionSelection) _then;

/// Create a copy of PendingWorkerActionSelection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ownerPlayerId = null,Object? unitId = null,Object? improvementType = freezed,}) {
  return _then(_self.copyWith(
ownerPlayerId: null == ownerPlayerId ? _self.ownerPlayerId : ownerPlayerId // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,improvementType: freezed == improvementType ? _self.improvementType : improvementType // ignore: cast_nullable_to_non_nullable
as FieldImprovementType?,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingWorkerActionSelection].
extension PendingWorkerActionSelectionPatterns on PendingWorkerActionSelection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingWorkerActionSelection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingWorkerActionSelection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingWorkerActionSelection value)  $default,){
final _that = this;
switch (_that) {
case _PendingWorkerActionSelection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingWorkerActionSelection value)?  $default,){
final _that = this;
switch (_that) {
case _PendingWorkerActionSelection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String ownerPlayerId,  String unitId,  FieldImprovementType? improvementType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingWorkerActionSelection() when $default != null:
return $default(_that.ownerPlayerId,_that.unitId,_that.improvementType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String ownerPlayerId,  String unitId,  FieldImprovementType? improvementType)  $default,) {final _that = this;
switch (_that) {
case _PendingWorkerActionSelection():
return $default(_that.ownerPlayerId,_that.unitId,_that.improvementType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String ownerPlayerId,  String unitId,  FieldImprovementType? improvementType)?  $default,) {final _that = this;
switch (_that) {
case _PendingWorkerActionSelection() when $default != null:
return $default(_that.ownerPlayerId,_that.unitId,_that.improvementType);case _:
  return null;

}
}

}

/// @nodoc


class _PendingWorkerActionSelection extends PendingWorkerActionSelection {
  const _PendingWorkerActionSelection({required this.ownerPlayerId, required this.unitId, this.improvementType}): super._();
  

@override final  String ownerPlayerId;
@override final  String unitId;
@override final  FieldImprovementType? improvementType;

/// Create a copy of PendingWorkerActionSelection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingWorkerActionSelectionCopyWith<_PendingWorkerActionSelection> get copyWith => __$PendingWorkerActionSelectionCopyWithImpl<_PendingWorkerActionSelection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingWorkerActionSelection&&super == other&&(identical(other.ownerPlayerId, ownerPlayerId) || other.ownerPlayerId == ownerPlayerId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.improvementType, improvementType) || other.improvementType == improvementType));
}


@override
int get hashCode => Object.hash(runtimeType,super.hashCode,ownerPlayerId,unitId,improvementType);

@override
String toString() {
  return 'PendingWorkerActionSelection(ownerPlayerId: $ownerPlayerId, unitId: $unitId, improvementType: $improvementType)';
}


}

/// @nodoc
abstract mixin class _$PendingWorkerActionSelectionCopyWith<$Res> implements $PendingWorkerActionSelectionCopyWith<$Res> {
  factory _$PendingWorkerActionSelectionCopyWith(_PendingWorkerActionSelection value, $Res Function(_PendingWorkerActionSelection) _then) = __$PendingWorkerActionSelectionCopyWithImpl;
@override @useResult
$Res call({
 String ownerPlayerId, String unitId, FieldImprovementType? improvementType
});




}
/// @nodoc
class __$PendingWorkerActionSelectionCopyWithImpl<$Res>
    implements _$PendingWorkerActionSelectionCopyWith<$Res> {
  __$PendingWorkerActionSelectionCopyWithImpl(this._self, this._then);

  final _PendingWorkerActionSelection _self;
  final $Res Function(_PendingWorkerActionSelection) _then;

/// Create a copy of PendingWorkerActionSelection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ownerPlayerId = null,Object? unitId = null,Object? improvementType = freezed,}) {
  return _then(_PendingWorkerActionSelection(
ownerPlayerId: null == ownerPlayerId ? _self.ownerPlayerId : ownerPlayerId // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,improvementType: freezed == improvementType ? _self.improvementType : improvementType // ignore: cast_nullable_to_non_nullable
as FieldImprovementType?,
  ));
}


}

/// @nodoc
mixin _$PendingAttackTargeting {

 String get ownerPlayerId; String get attackerUnitId; int? get defenderCol; int? get defenderRow;
/// Create a copy of PendingAttackTargeting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingAttackTargetingCopyWith<PendingAttackTargeting> get copyWith => _$PendingAttackTargetingCopyWithImpl<PendingAttackTargeting>(this as PendingAttackTargeting, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingAttackTargeting&&super == other&&(identical(other.ownerPlayerId, ownerPlayerId) || other.ownerPlayerId == ownerPlayerId)&&(identical(other.attackerUnitId, attackerUnitId) || other.attackerUnitId == attackerUnitId)&&(identical(other.defenderCol, defenderCol) || other.defenderCol == defenderCol)&&(identical(other.defenderRow, defenderRow) || other.defenderRow == defenderRow));
}


@override
int get hashCode => Object.hash(runtimeType,super.hashCode,ownerPlayerId,attackerUnitId,defenderCol,defenderRow);

@override
String toString() {
  return 'PendingAttackTargeting(ownerPlayerId: $ownerPlayerId, attackerUnitId: $attackerUnitId, defenderCol: $defenderCol, defenderRow: $defenderRow)';
}


}

/// @nodoc
abstract mixin class $PendingAttackTargetingCopyWith<$Res>  {
  factory $PendingAttackTargetingCopyWith(PendingAttackTargeting value, $Res Function(PendingAttackTargeting) _then) = _$PendingAttackTargetingCopyWithImpl;
@useResult
$Res call({
 String ownerPlayerId, String attackerUnitId, int? defenderCol, int? defenderRow
});




}
/// @nodoc
class _$PendingAttackTargetingCopyWithImpl<$Res>
    implements $PendingAttackTargetingCopyWith<$Res> {
  _$PendingAttackTargetingCopyWithImpl(this._self, this._then);

  final PendingAttackTargeting _self;
  final $Res Function(PendingAttackTargeting) _then;

/// Create a copy of PendingAttackTargeting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ownerPlayerId = null,Object? attackerUnitId = null,Object? defenderCol = freezed,Object? defenderRow = freezed,}) {
  return _then(_self.copyWith(
ownerPlayerId: null == ownerPlayerId ? _self.ownerPlayerId : ownerPlayerId // ignore: cast_nullable_to_non_nullable
as String,attackerUnitId: null == attackerUnitId ? _self.attackerUnitId : attackerUnitId // ignore: cast_nullable_to_non_nullable
as String,defenderCol: freezed == defenderCol ? _self.defenderCol : defenderCol // ignore: cast_nullable_to_non_nullable
as int?,defenderRow: freezed == defenderRow ? _self.defenderRow : defenderRow // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingAttackTargeting].
extension PendingAttackTargetingPatterns on PendingAttackTargeting {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingAttackTargeting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingAttackTargeting() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingAttackTargeting value)  $default,){
final _that = this;
switch (_that) {
case _PendingAttackTargeting():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingAttackTargeting value)?  $default,){
final _that = this;
switch (_that) {
case _PendingAttackTargeting() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String ownerPlayerId,  String attackerUnitId,  int? defenderCol,  int? defenderRow)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingAttackTargeting() when $default != null:
return $default(_that.ownerPlayerId,_that.attackerUnitId,_that.defenderCol,_that.defenderRow);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String ownerPlayerId,  String attackerUnitId,  int? defenderCol,  int? defenderRow)  $default,) {final _that = this;
switch (_that) {
case _PendingAttackTargeting():
return $default(_that.ownerPlayerId,_that.attackerUnitId,_that.defenderCol,_that.defenderRow);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String ownerPlayerId,  String attackerUnitId,  int? defenderCol,  int? defenderRow)?  $default,) {final _that = this;
switch (_that) {
case _PendingAttackTargeting() when $default != null:
return $default(_that.ownerPlayerId,_that.attackerUnitId,_that.defenderCol,_that.defenderRow);case _:
  return null;

}
}

}

/// @nodoc


class _PendingAttackTargeting extends PendingAttackTargeting {
  const _PendingAttackTargeting({required this.ownerPlayerId, required this.attackerUnitId, this.defenderCol, this.defenderRow}): super._();
  

@override final  String ownerPlayerId;
@override final  String attackerUnitId;
@override final  int? defenderCol;
@override final  int? defenderRow;

/// Create a copy of PendingAttackTargeting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingAttackTargetingCopyWith<_PendingAttackTargeting> get copyWith => __$PendingAttackTargetingCopyWithImpl<_PendingAttackTargeting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingAttackTargeting&&super == other&&(identical(other.ownerPlayerId, ownerPlayerId) || other.ownerPlayerId == ownerPlayerId)&&(identical(other.attackerUnitId, attackerUnitId) || other.attackerUnitId == attackerUnitId)&&(identical(other.defenderCol, defenderCol) || other.defenderCol == defenderCol)&&(identical(other.defenderRow, defenderRow) || other.defenderRow == defenderRow));
}


@override
int get hashCode => Object.hash(runtimeType,super.hashCode,ownerPlayerId,attackerUnitId,defenderCol,defenderRow);

@override
String toString() {
  return 'PendingAttackTargeting(ownerPlayerId: $ownerPlayerId, attackerUnitId: $attackerUnitId, defenderCol: $defenderCol, defenderRow: $defenderRow)';
}


}

/// @nodoc
abstract mixin class _$PendingAttackTargetingCopyWith<$Res> implements $PendingAttackTargetingCopyWith<$Res> {
  factory _$PendingAttackTargetingCopyWith(_PendingAttackTargeting value, $Res Function(_PendingAttackTargeting) _then) = __$PendingAttackTargetingCopyWithImpl;
@override @useResult
$Res call({
 String ownerPlayerId, String attackerUnitId, int? defenderCol, int? defenderRow
});




}
/// @nodoc
class __$PendingAttackTargetingCopyWithImpl<$Res>
    implements _$PendingAttackTargetingCopyWith<$Res> {
  __$PendingAttackTargetingCopyWithImpl(this._self, this._then);

  final _PendingAttackTargeting _self;
  final $Res Function(_PendingAttackTargeting) _then;

/// Create a copy of PendingAttackTargeting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ownerPlayerId = null,Object? attackerUnitId = null,Object? defenderCol = freezed,Object? defenderRow = freezed,}) {
  return _then(_PendingAttackTargeting(
ownerPlayerId: null == ownerPlayerId ? _self.ownerPlayerId : ownerPlayerId // ignore: cast_nullable_to_non_nullable
as String,attackerUnitId: null == attackerUnitId ? _self.attackerUnitId : attackerUnitId // ignore: cast_nullable_to_non_nullable
as String,defenderCol: freezed == defenderCol ? _self.defenderCol : defenderCol // ignore: cast_nullable_to_non_nullable
as int?,defenderRow: freezed == defenderRow ? _self.defenderRow : defenderRow // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
