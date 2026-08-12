// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unit_production_requirement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UnitProductionRequirement {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitProductionRequirement);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UnitProductionRequirement()';
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UnitResourceRequirement value)?  resource,TResult Function( UnitStockpileCostRequirement value)?  stockpileCost,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UnitResourceRequirement() when resource != null:
return resource(_that);case UnitStockpileCostRequirement() when stockpileCost != null:
return stockpileCost(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UnitResourceRequirement value)  resource,required TResult Function( UnitStockpileCostRequirement value)  stockpileCost,}){
final _that = this;
switch (_that) {
case UnitResourceRequirement():
return resource(_that);case UnitStockpileCostRequirement():
return stockpileCost(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UnitResourceRequirement value)?  resource,TResult? Function( UnitStockpileCostRequirement value)?  stockpileCost,}){
final _that = this;
switch (_that) {
case UnitResourceRequirement() when resource != null:
return resource(_that);case UnitStockpileCostRequirement() when stockpileCost != null:
return stockpileCost(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Set<ResourceType> resources)?  resource,TResult Function( List<StrategicResourceBundle> options)?  stockpileCost,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UnitResourceRequirement() when resource != null:
return resource(_that.resources);case UnitStockpileCostRequirement() when stockpileCost != null:
return stockpileCost(_that.options);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Set<ResourceType> resources)  resource,required TResult Function( List<StrategicResourceBundle> options)  stockpileCost,}) {final _that = this;
switch (_that) {
case UnitResourceRequirement():
return resource(_that.resources);case UnitStockpileCostRequirement():
return stockpileCost(_that.options);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Set<ResourceType> resources)?  resource,TResult? Function( List<StrategicResourceBundle> options)?  stockpileCost,}) {final _that = this;
switch (_that) {
case UnitResourceRequirement() when resource != null:
return resource(_that.resources);case UnitStockpileCostRequirement() when stockpileCost != null:
return stockpileCost(_that.options);case _:
  return null;

}
}

}

/// @nodoc


class UnitResourceRequirement extends UnitProductionRequirement {
  const UnitResourceRequirement( Set<ResourceType> resources): _resources = resources,super._();
  

 final  Set<ResourceType> _resources;
 Set<ResourceType> get resources {
  if (_resources is EqualUnmodifiableSetView) return _resources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_resources);
}





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


class UnitStockpileCostRequirement extends UnitProductionRequirement {
  const UnitStockpileCostRequirement( List<StrategicResourceBundle> options): _options = options,super._();
  

 final  List<StrategicResourceBundle> _options;
 List<StrategicResourceBundle> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitStockpileCostRequirement&&const DeepCollectionEquality().equals(other._options, _options));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_options));

@override
String toString() {
  return 'UnitProductionRequirement.stockpileCost(options: $options)';
}


}




// dart format on
