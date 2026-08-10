// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'war_goal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WarGoal {

 String get targetPlayerId; WarGoalKind get kind; CityHex? get targetCity; HexCoordinate get targetHex; int get turnsBudget; List<String> get assignedUnitIds; double get priority;
/// Create a copy of WarGoal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WarGoalCopyWith<WarGoal> get copyWith => _$WarGoalCopyWithImpl<WarGoal>(this as WarGoal, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WarGoal&&(identical(other.targetPlayerId, targetPlayerId) || other.targetPlayerId == targetPlayerId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.targetCity, targetCity) || other.targetCity == targetCity)&&(identical(other.targetHex, targetHex) || other.targetHex == targetHex)&&(identical(other.turnsBudget, turnsBudget) || other.turnsBudget == turnsBudget)&&const DeepCollectionEquality().equals(other.assignedUnitIds, assignedUnitIds)&&(identical(other.priority, priority) || other.priority == priority));
}


@override
int get hashCode => Object.hash(runtimeType,targetPlayerId,kind,targetCity,targetHex,turnsBudget,const DeepCollectionEquality().hash(assignedUnitIds),priority);

@override
String toString() {
  return 'WarGoal(targetPlayerId: $targetPlayerId, kind: $kind, targetCity: $targetCity, targetHex: $targetHex, turnsBudget: $turnsBudget, assignedUnitIds: $assignedUnitIds, priority: $priority)';
}


}

/// @nodoc
abstract mixin class $WarGoalCopyWith<$Res>  {
  factory $WarGoalCopyWith(WarGoal value, $Res Function(WarGoal) _then) = _$WarGoalCopyWithImpl;
@useResult
$Res call({
 String targetPlayerId, WarGoalKind kind, CityHex? targetCity, HexCoordinate targetHex, int turnsBudget, List<String> assignedUnitIds, double priority
});




}
/// @nodoc
class _$WarGoalCopyWithImpl<$Res>
    implements $WarGoalCopyWith<$Res> {
  _$WarGoalCopyWithImpl(this._self, this._then);

  final WarGoal _self;
  final $Res Function(WarGoal) _then;

/// Create a copy of WarGoal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? targetPlayerId = null,Object? kind = null,Object? targetCity = freezed,Object? targetHex = null,Object? turnsBudget = null,Object? assignedUnitIds = null,Object? priority = null,}) {
  return _then(WarGoal(
targetPlayerId: null == targetPlayerId ? _self.targetPlayerId : targetPlayerId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as WarGoalKind,targetCity: freezed == targetCity ? _self.targetCity : targetCity // ignore: cast_nullable_to_non_nullable
as CityHex?,targetHex: null == targetHex ? _self.targetHex : targetHex // ignore: cast_nullable_to_non_nullable
as HexCoordinate,turnsBudget: null == turnsBudget ? _self.turnsBudget : turnsBudget // ignore: cast_nullable_to_non_nullable
as int,assignedUnitIds: null == assignedUnitIds ? _self.assignedUnitIds! : assignedUnitIds // ignore: cast_nullable_to_non_nullable
as Iterable<String>,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}



/// @nodoc


class _WarGoal extends WarGoal {
  const _WarGoal({required this.targetPlayerId, required this.kind, this.targetCity, required this.targetHex, required this.turnsBudget, required  List<String> assignedUnitIds, required this.priority}): _assignedUnitIds = assignedUnitIds,super._();
  

@override final  String targetPlayerId;
@override final  WarGoalKind kind;
@override final  CityHex? targetCity;
@override final  HexCoordinate targetHex;
@override final  int turnsBudget;
 final  List<String> _assignedUnitIds;
@override List<String> get assignedUnitIds {
  if (_assignedUnitIds is EqualUnmodifiableListView) return _assignedUnitIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assignedUnitIds);
}

@override final  double priority;

/// Create a copy of WarGoal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WarGoalCopyWith<_WarGoal> get copyWith => __$WarGoalCopyWithImpl<_WarGoal>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WarGoal&&(identical(other.targetPlayerId, targetPlayerId) || other.targetPlayerId == targetPlayerId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.targetCity, targetCity) || other.targetCity == targetCity)&&(identical(other.targetHex, targetHex) || other.targetHex == targetHex)&&(identical(other.turnsBudget, turnsBudget) || other.turnsBudget == turnsBudget)&&const DeepCollectionEquality().equals(other._assignedUnitIds, _assignedUnitIds)&&(identical(other.priority, priority) || other.priority == priority));
}


@override
int get hashCode => Object.hash(runtimeType,targetPlayerId,kind,targetCity,targetHex,turnsBudget,const DeepCollectionEquality().hash(_assignedUnitIds),priority);

@override
String toString() {
  return 'WarGoal._internal(targetPlayerId: $targetPlayerId, kind: $kind, targetCity: $targetCity, targetHex: $targetHex, turnsBudget: $turnsBudget, assignedUnitIds: $assignedUnitIds, priority: $priority)';
}


}

/// @nodoc
abstract mixin class _$WarGoalCopyWith<$Res> implements $WarGoalCopyWith<$Res> {
  factory _$WarGoalCopyWith(_WarGoal value, $Res Function(_WarGoal) _then) = __$WarGoalCopyWithImpl;
@override @useResult
$Res call({
 String targetPlayerId, WarGoalKind kind, CityHex? targetCity, HexCoordinate targetHex, int turnsBudget, List<String> assignedUnitIds, double priority
});




}
/// @nodoc
class __$WarGoalCopyWithImpl<$Res>
    implements _$WarGoalCopyWith<$Res> {
  __$WarGoalCopyWithImpl(this._self, this._then);

  final _WarGoal _self;
  final $Res Function(_WarGoal) _then;

/// Create a copy of WarGoal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetPlayerId = null,Object? kind = null,Object? targetCity = freezed,Object? targetHex = null,Object? turnsBudget = null,Object? assignedUnitIds = null,Object? priority = null,}) {
  return _then(_WarGoal(
targetPlayerId: null == targetPlayerId ? _self.targetPlayerId : targetPlayerId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as WarGoalKind,targetCity: freezed == targetCity ? _self.targetCity : targetCity // ignore: cast_nullable_to_non_nullable
as CityHex?,targetHex: null == targetHex ? _self.targetHex : targetHex // ignore: cast_nullable_to_non_nullable
as HexCoordinate,turnsBudget: null == turnsBudget ? _self.turnsBudget : turnsBudget // ignore: cast_nullable_to_non_nullable
as int,assignedUnitIds: null == assignedUnitIds ? _self._assignedUnitIds : assignedUnitIds // ignore: cast_nullable_to_non_nullable
as List<String>,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
