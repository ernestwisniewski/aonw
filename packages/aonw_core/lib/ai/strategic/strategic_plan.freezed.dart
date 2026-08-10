// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'strategic_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StrategicPlan {

 int get computedAtTurn; StrategicMode get mode; EconomyExpectations get expectations; EconomyHealth get economyHealth; List<PlayerThreatScore> get rivalRanking; List<TechnologyId> get techPath; List<CityHex> get citySiteRanking; Map<String, CityHex> get settlerAssignments; Map<String, StrategicWorkerAssignment> get workerAssignments; Map<String, StrategicFrontierClearingAssignment> get frontierClearingAssignments; List<WarGoal> get warGoals; Map<String, StrategicDefenseAssignment> get defenses;
/// Create a copy of StrategicPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StrategicPlanCopyWith<StrategicPlan> get copyWith => _$StrategicPlanCopyWithImpl<StrategicPlan>(this as StrategicPlan, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StrategicPlan&&(identical(other.computedAtTurn, computedAtTurn) || other.computedAtTurn == computedAtTurn)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.expectations, expectations) || other.expectations == expectations)&&(identical(other.economyHealth, economyHealth) || other.economyHealth == economyHealth)&&const DeepCollectionEquality().equals(other.rivalRanking, rivalRanking)&&const DeepCollectionEquality().equals(other.techPath, techPath)&&const DeepCollectionEquality().equals(other.citySiteRanking, citySiteRanking)&&const DeepCollectionEquality().equals(other.settlerAssignments, settlerAssignments)&&const DeepCollectionEquality().equals(other.workerAssignments, workerAssignments)&&const DeepCollectionEquality().equals(other.frontierClearingAssignments, frontierClearingAssignments)&&const DeepCollectionEquality().equals(other.warGoals, warGoals)&&const DeepCollectionEquality().equals(other.defenses, defenses));
}


@override
int get hashCode => Object.hash(runtimeType,computedAtTurn,mode,expectations,economyHealth,const DeepCollectionEquality().hash(rivalRanking),const DeepCollectionEquality().hash(techPath),const DeepCollectionEquality().hash(citySiteRanking),const DeepCollectionEquality().hash(settlerAssignments),const DeepCollectionEquality().hash(workerAssignments),const DeepCollectionEquality().hash(frontierClearingAssignments),const DeepCollectionEquality().hash(warGoals),const DeepCollectionEquality().hash(defenses));

@override
String toString() {
  return 'StrategicPlan(computedAtTurn: $computedAtTurn, mode: $mode, expectations: $expectations, economyHealth: $economyHealth, rivalRanking: $rivalRanking, techPath: $techPath, citySiteRanking: $citySiteRanking, settlerAssignments: $settlerAssignments, workerAssignments: $workerAssignments, frontierClearingAssignments: $frontierClearingAssignments, warGoals: $warGoals, defenses: $defenses)';
}


}

/// @nodoc
abstract mixin class $StrategicPlanCopyWith<$Res>  {
  factory $StrategicPlanCopyWith(StrategicPlan value, $Res Function(StrategicPlan) _then) = _$StrategicPlanCopyWithImpl;
@useResult
$Res call({
 int computedAtTurn, StrategicMode mode, EconomyExpectations expectations, EconomyHealth economyHealth, List<PlayerThreatScore> rivalRanking, List<TechnologyId> techPath, List<CityHex> citySiteRanking, Map<String, CityHex> settlerAssignments, Map<String, StrategicWorkerAssignment> workerAssignments, Map<String, StrategicFrontierClearingAssignment> frontierClearingAssignments, List<WarGoal> warGoals, Map<String, StrategicDefenseAssignment> defenses
});




}
/// @nodoc
class _$StrategicPlanCopyWithImpl<$Res>
    implements $StrategicPlanCopyWith<$Res> {
  _$StrategicPlanCopyWithImpl(this._self, this._then);

  final StrategicPlan _self;
  final $Res Function(StrategicPlan) _then;

/// Create a copy of StrategicPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? computedAtTurn = null,Object? mode = null,Object? expectations = null,Object? economyHealth = null,Object? rivalRanking = null,Object? techPath = null,Object? citySiteRanking = null,Object? settlerAssignments = null,Object? workerAssignments = null,Object? frontierClearingAssignments = null,Object? warGoals = null,Object? defenses = null,}) {
  return _then(StrategicPlan(
computedAtTurn: null == computedAtTurn ? _self.computedAtTurn : computedAtTurn // ignore: cast_nullable_to_non_nullable
as int,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as StrategicMode,expectations: null == expectations ? _self.expectations : expectations // ignore: cast_nullable_to_non_nullable
as EconomyExpectations,economyHealth: null == economyHealth ? _self.economyHealth : economyHealth // ignore: cast_nullable_to_non_nullable
as EconomyHealth,rivalRanking: null == rivalRanking ? _self.rivalRanking : rivalRanking // ignore: cast_nullable_to_non_nullable
as List<PlayerThreatScore>,techPath: null == techPath ? _self.techPath : techPath // ignore: cast_nullable_to_non_nullable
as List<TechnologyId>,citySiteRanking: null == citySiteRanking ? _self.citySiteRanking : citySiteRanking // ignore: cast_nullable_to_non_nullable
as List<CityHex>,settlerAssignments: null == settlerAssignments ? _self.settlerAssignments : settlerAssignments // ignore: cast_nullable_to_non_nullable
as Map<String, CityHex>,workerAssignments: null == workerAssignments ? _self.workerAssignments : workerAssignments // ignore: cast_nullable_to_non_nullable
as Map<String, StrategicWorkerAssignment>,frontierClearingAssignments: null == frontierClearingAssignments ? _self.frontierClearingAssignments : frontierClearingAssignments // ignore: cast_nullable_to_non_nullable
as Map<String, StrategicFrontierClearingAssignment>,warGoals: null == warGoals ? _self.warGoals : warGoals // ignore: cast_nullable_to_non_nullable
as List<WarGoal>,defenses: null == defenses ? _self.defenses : defenses // ignore: cast_nullable_to_non_nullable
as Map<String, StrategicDefenseAssignment>,
  ));
}

}


/// Adds pattern-matching-related methods to [StrategicPlan].
extension StrategicPlanPatterns on StrategicPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StrategicPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StrategicPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StrategicPlan value)  $default,){
final _that = this;
switch (_that) {
case _StrategicPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StrategicPlan value)?  $default,){
final _that = this;
switch (_that) {
case _StrategicPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int computedAtTurn,  StrategicMode mode,  EconomyExpectations expectations,  EconomyHealth economyHealth,  List<PlayerThreatScore> rivalRanking,  List<TechnologyId> techPath,  List<CityHex> citySiteRanking,  Map<String, CityHex> settlerAssignments,  Map<String, StrategicWorkerAssignment> workerAssignments,  Map<String, StrategicFrontierClearingAssignment> frontierClearingAssignments,  List<WarGoal> warGoals,  Map<String, StrategicDefenseAssignment> defenses)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StrategicPlan() when $default != null:
return $default(_that.computedAtTurn,_that.mode,_that.expectations,_that.economyHealth,_that.rivalRanking,_that.techPath,_that.citySiteRanking,_that.settlerAssignments,_that.workerAssignments,_that.frontierClearingAssignments,_that.warGoals,_that.defenses);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int computedAtTurn,  StrategicMode mode,  EconomyExpectations expectations,  EconomyHealth economyHealth,  List<PlayerThreatScore> rivalRanking,  List<TechnologyId> techPath,  List<CityHex> citySiteRanking,  Map<String, CityHex> settlerAssignments,  Map<String, StrategicWorkerAssignment> workerAssignments,  Map<String, StrategicFrontierClearingAssignment> frontierClearingAssignments,  List<WarGoal> warGoals,  Map<String, StrategicDefenseAssignment> defenses)  $default,) {final _that = this;
switch (_that) {
case _StrategicPlan():
return $default(_that.computedAtTurn,_that.mode,_that.expectations,_that.economyHealth,_that.rivalRanking,_that.techPath,_that.citySiteRanking,_that.settlerAssignments,_that.workerAssignments,_that.frontierClearingAssignments,_that.warGoals,_that.defenses);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int computedAtTurn,  StrategicMode mode,  EconomyExpectations expectations,  EconomyHealth economyHealth,  List<PlayerThreatScore> rivalRanking,  List<TechnologyId> techPath,  List<CityHex> citySiteRanking,  Map<String, CityHex> settlerAssignments,  Map<String, StrategicWorkerAssignment> workerAssignments,  Map<String, StrategicFrontierClearingAssignment> frontierClearingAssignments,  List<WarGoal> warGoals,  Map<String, StrategicDefenseAssignment> defenses)?  $default,) {final _that = this;
switch (_that) {
case _StrategicPlan() when $default != null:
return $default(_that.computedAtTurn,_that.mode,_that.expectations,_that.economyHealth,_that.rivalRanking,_that.techPath,_that.citySiteRanking,_that.settlerAssignments,_that.workerAssignments,_that.frontierClearingAssignments,_that.warGoals,_that.defenses);case _:
  return null;

}
}

}

/// @nodoc


class _StrategicPlan extends StrategicPlan {
  const _StrategicPlan({required this.computedAtTurn, required this.mode, required this.expectations, this.economyHealth = EconomyHealth.stable,  List<PlayerThreatScore> rivalRanking = const [],  List<TechnologyId> techPath = const [],  List<CityHex> citySiteRanking = const [],  Map<String, CityHex> settlerAssignments = const {},  Map<String, StrategicWorkerAssignment> workerAssignments = const {},  Map<String, StrategicFrontierClearingAssignment> frontierClearingAssignments = const {},  List<WarGoal> warGoals = const [],  Map<String, StrategicDefenseAssignment> defenses = const {}}): _rivalRanking = rivalRanking,_techPath = techPath,_citySiteRanking = citySiteRanking,_settlerAssignments = settlerAssignments,_workerAssignments = workerAssignments,_frontierClearingAssignments = frontierClearingAssignments,_warGoals = warGoals,_defenses = defenses,super._();
  

@override final  int computedAtTurn;
@override final  StrategicMode mode;
@override final  EconomyExpectations expectations;
@override@JsonKey() final  EconomyHealth economyHealth;
 final  List<PlayerThreatScore> _rivalRanking;
@override@JsonKey() List<PlayerThreatScore> get rivalRanking {
  if (_rivalRanking is EqualUnmodifiableListView) return _rivalRanking;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rivalRanking);
}

 final  List<TechnologyId> _techPath;
@override@JsonKey() List<TechnologyId> get techPath {
  if (_techPath is EqualUnmodifiableListView) return _techPath;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_techPath);
}

 final  List<CityHex> _citySiteRanking;
@override@JsonKey() List<CityHex> get citySiteRanking {
  if (_citySiteRanking is EqualUnmodifiableListView) return _citySiteRanking;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_citySiteRanking);
}

 final  Map<String, CityHex> _settlerAssignments;
@override@JsonKey() Map<String, CityHex> get settlerAssignments {
  if (_settlerAssignments is EqualUnmodifiableMapView) return _settlerAssignments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_settlerAssignments);
}

 final  Map<String, StrategicWorkerAssignment> _workerAssignments;
@override@JsonKey() Map<String, StrategicWorkerAssignment> get workerAssignments {
  if (_workerAssignments is EqualUnmodifiableMapView) return _workerAssignments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_workerAssignments);
}

 final  Map<String, StrategicFrontierClearingAssignment> _frontierClearingAssignments;
@override@JsonKey() Map<String, StrategicFrontierClearingAssignment> get frontierClearingAssignments {
  if (_frontierClearingAssignments is EqualUnmodifiableMapView) return _frontierClearingAssignments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_frontierClearingAssignments);
}

 final  List<WarGoal> _warGoals;
@override@JsonKey() List<WarGoal> get warGoals {
  if (_warGoals is EqualUnmodifiableListView) return _warGoals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_warGoals);
}

 final  Map<String, StrategicDefenseAssignment> _defenses;
@override@JsonKey() Map<String, StrategicDefenseAssignment> get defenses {
  if (_defenses is EqualUnmodifiableMapView) return _defenses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_defenses);
}


/// Create a copy of StrategicPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StrategicPlanCopyWith<_StrategicPlan> get copyWith => __$StrategicPlanCopyWithImpl<_StrategicPlan>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StrategicPlan&&(identical(other.computedAtTurn, computedAtTurn) || other.computedAtTurn == computedAtTurn)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.expectations, expectations) || other.expectations == expectations)&&(identical(other.economyHealth, economyHealth) || other.economyHealth == economyHealth)&&const DeepCollectionEquality().equals(other._rivalRanking, _rivalRanking)&&const DeepCollectionEquality().equals(other._techPath, _techPath)&&const DeepCollectionEquality().equals(other._citySiteRanking, _citySiteRanking)&&const DeepCollectionEquality().equals(other._settlerAssignments, _settlerAssignments)&&const DeepCollectionEquality().equals(other._workerAssignments, _workerAssignments)&&const DeepCollectionEquality().equals(other._frontierClearingAssignments, _frontierClearingAssignments)&&const DeepCollectionEquality().equals(other._warGoals, _warGoals)&&const DeepCollectionEquality().equals(other._defenses, _defenses));
}


@override
int get hashCode => Object.hash(runtimeType,computedAtTurn,mode,expectations,economyHealth,const DeepCollectionEquality().hash(_rivalRanking),const DeepCollectionEquality().hash(_techPath),const DeepCollectionEquality().hash(_citySiteRanking),const DeepCollectionEquality().hash(_settlerAssignments),const DeepCollectionEquality().hash(_workerAssignments),const DeepCollectionEquality().hash(_frontierClearingAssignments),const DeepCollectionEquality().hash(_warGoals),const DeepCollectionEquality().hash(_defenses));

@override
String toString() {
  return 'StrategicPlan(computedAtTurn: $computedAtTurn, mode: $mode, expectations: $expectations, economyHealth: $economyHealth, rivalRanking: $rivalRanking, techPath: $techPath, citySiteRanking: $citySiteRanking, settlerAssignments: $settlerAssignments, workerAssignments: $workerAssignments, frontierClearingAssignments: $frontierClearingAssignments, warGoals: $warGoals, defenses: $defenses)';
}


}

/// @nodoc
abstract mixin class _$StrategicPlanCopyWith<$Res> implements $StrategicPlanCopyWith<$Res> {
  factory _$StrategicPlanCopyWith(_StrategicPlan value, $Res Function(_StrategicPlan) _then) = __$StrategicPlanCopyWithImpl;
@override @useResult
$Res call({
 int computedAtTurn, StrategicMode mode, EconomyExpectations expectations, EconomyHealth economyHealth, List<PlayerThreatScore> rivalRanking, List<TechnologyId> techPath, List<CityHex> citySiteRanking, Map<String, CityHex> settlerAssignments, Map<String, StrategicWorkerAssignment> workerAssignments, Map<String, StrategicFrontierClearingAssignment> frontierClearingAssignments, List<WarGoal> warGoals, Map<String, StrategicDefenseAssignment> defenses
});




}
/// @nodoc
class __$StrategicPlanCopyWithImpl<$Res>
    implements _$StrategicPlanCopyWith<$Res> {
  __$StrategicPlanCopyWithImpl(this._self, this._then);

  final _StrategicPlan _self;
  final $Res Function(_StrategicPlan) _then;

/// Create a copy of StrategicPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? computedAtTurn = null,Object? mode = null,Object? expectations = null,Object? economyHealth = null,Object? rivalRanking = null,Object? techPath = null,Object? citySiteRanking = null,Object? settlerAssignments = null,Object? workerAssignments = null,Object? frontierClearingAssignments = null,Object? warGoals = null,Object? defenses = null,}) {
  return _then(_StrategicPlan(
computedAtTurn: null == computedAtTurn ? _self.computedAtTurn : computedAtTurn // ignore: cast_nullable_to_non_nullable
as int,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as StrategicMode,expectations: null == expectations ? _self.expectations : expectations // ignore: cast_nullable_to_non_nullable
as EconomyExpectations,economyHealth: null == economyHealth ? _self.economyHealth : economyHealth // ignore: cast_nullable_to_non_nullable
as EconomyHealth,rivalRanking: null == rivalRanking ? _self._rivalRanking : rivalRanking // ignore: cast_nullable_to_non_nullable
as List<PlayerThreatScore>,techPath: null == techPath ? _self._techPath : techPath // ignore: cast_nullable_to_non_nullable
as List<TechnologyId>,citySiteRanking: null == citySiteRanking ? _self._citySiteRanking : citySiteRanking // ignore: cast_nullable_to_non_nullable
as List<CityHex>,settlerAssignments: null == settlerAssignments ? _self._settlerAssignments : settlerAssignments // ignore: cast_nullable_to_non_nullable
as Map<String, CityHex>,workerAssignments: null == workerAssignments ? _self._workerAssignments : workerAssignments // ignore: cast_nullable_to_non_nullable
as Map<String, StrategicWorkerAssignment>,frontierClearingAssignments: null == frontierClearingAssignments ? _self._frontierClearingAssignments : frontierClearingAssignments // ignore: cast_nullable_to_non_nullable
as Map<String, StrategicFrontierClearingAssignment>,warGoals: null == warGoals ? _self._warGoals : warGoals // ignore: cast_nullable_to_non_nullable
as List<WarGoal>,defenses: null == defenses ? _self._defenses : defenses // ignore: cast_nullable_to_non_nullable
as Map<String, StrategicDefenseAssignment>,
  ));
}


}

// dart format on
