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
