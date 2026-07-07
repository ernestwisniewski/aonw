// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unit_production_requirement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UnitProductionRequirement {

 Set<ResourceType> get resources;
/// Create a copy of UnitProductionRequirement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitProductionRequirementCopyWith<UnitProductionRequirement> get copyWith => _$UnitProductionRequirementCopyWithImpl<UnitProductionRequirement>(this as UnitProductionRequirement, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitProductionRequirement&&const DeepCollectionEquality().equals(other.resources, resources));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(resources));

@override
String toString() {
  return 'UnitProductionRequirement(resources: $resources)';
}


}

/// @nodoc
abstract mixin class $UnitProductionRequirementCopyWith<$Res>  {
  factory $UnitProductionRequirementCopyWith(UnitProductionRequirement value, $Res Function(UnitProductionRequirement) _then) = _$UnitProductionRequirementCopyWithImpl;
@useResult
$Res call({
 Set<ResourceType> resources
});




}
/// @nodoc
class _$UnitProductionRequirementCopyWithImpl<$Res>
    implements $UnitProductionRequirementCopyWith<$Res> {
  _$UnitProductionRequirementCopyWithImpl(this._self, this._then);

  final UnitProductionRequirement _self;
  final $Res Function(UnitProductionRequirement) _then;

/// Create a copy of UnitProductionRequirement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resources = null,}) {
  return _then(_self.copyWith(
resources: null == resources ? _self.resources : resources // ignore: cast_nullable_to_non_nullable
as Set<ResourceType>,
  ));
}

}


/// Adds pattern-matching-related methods to [UnitProductionRequirement].
extension UnitProductionRequirementPatterns on UnitProductionRequirement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UnitResourceRequirement value)?  resource,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UnitResourceRequirement() when resource != null:
return resource(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UnitResourceRequirement value)  resource,}){
final _that = this;
switch (_that) {
case UnitResourceRequirement():
return resource(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UnitResourceRequirement value)?  resource,}){
final _that = this;
switch (_that) {
case UnitResourceRequirement() when resource != null:
return resource(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Set<ResourceType> resources)?  resource,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UnitResourceRequirement() when resource != null:
return resource(_that.resources);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Set<ResourceType> resources)  resource,}) {final _that = this;
switch (_that) {
case UnitResourceRequirement():
return resource(_that.resources);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Set<ResourceType> resources)?  resource,}) {final _that = this;
switch (_that) {
case UnitResourceRequirement() when resource != null:
return resource(_that.resources);case _:
  return null;

}
}

}

/// @nodoc


class UnitResourceRequirement extends UnitProductionRequirement {
  const UnitResourceRequirement(final  Set<ResourceType> resources): _resources = resources,super._();
  

 final  Set<ResourceType> _resources;
@override Set<ResourceType> get resources {
  if (_resources is EqualUnmodifiableSetView) return _resources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_resources);
}


/// Create a copy of UnitProductionRequirement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitResourceRequirementCopyWith<UnitResourceRequirement> get copyWith => _$UnitResourceRequirementCopyWithImpl<UnitResourceRequirement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitResourceRequirement&&const DeepCollectionEquality().equals(other._resources, _resources));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_resources));

@override
String toString() {
  return 'UnitProductionRequirement.resource(resources: $resources)';
}


}

/// @nodoc
abstract mixin class $UnitResourceRequirementCopyWith<$Res> implements $UnitProductionRequirementCopyWith<$Res> {
  factory $UnitResourceRequirementCopyWith(UnitResourceRequirement value, $Res Function(UnitResourceRequirement) _then) = _$UnitResourceRequirementCopyWithImpl;
@override @useResult
$Res call({
 Set<ResourceType> resources
});




}
/// @nodoc
class _$UnitResourceRequirementCopyWithImpl<$Res>
    implements $UnitResourceRequirementCopyWith<$Res> {
  _$UnitResourceRequirementCopyWithImpl(this._self, this._then);

  final UnitResourceRequirement _self;
  final $Res Function(UnitResourceRequirement) _then;

/// Create a copy of UnitProductionRequirement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resources = null,}) {
  return _then(UnitResourceRequirement(
null == resources ? _self._resources : resources // ignore: cast_nullable_to_non_nullable
as Set<ResourceType>,
  ));
}


}

// dart format on
