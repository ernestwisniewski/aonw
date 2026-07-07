// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditorState {

 Set<TerrainType> get selectedTerrains; Set<ResourceType> get selectedResources; MapObjectiveType? get selectedObjectiveType; EditorObjectivePaintMode get objectivePaintMode; int get selectedHeight; bool get heightActive;
/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorStateCopyWith<EditorState> get copyWith => _$EditorStateCopyWithImpl<EditorState>(this as EditorState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorState&&const DeepCollectionEquality().equals(other.selectedTerrains, selectedTerrains)&&const DeepCollectionEquality().equals(other.selectedResources, selectedResources)&&(identical(other.selectedObjectiveType, selectedObjectiveType) || other.selectedObjectiveType == selectedObjectiveType)&&(identical(other.objectivePaintMode, objectivePaintMode) || other.objectivePaintMode == objectivePaintMode)&&(identical(other.selectedHeight, selectedHeight) || other.selectedHeight == selectedHeight)&&(identical(other.heightActive, heightActive) || other.heightActive == heightActive));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(selectedTerrains),const DeepCollectionEquality().hash(selectedResources),selectedObjectiveType,objectivePaintMode,selectedHeight,heightActive);

@override
String toString() {
  return 'EditorState(selectedTerrains: $selectedTerrains, selectedResources: $selectedResources, selectedObjectiveType: $selectedObjectiveType, objectivePaintMode: $objectivePaintMode, selectedHeight: $selectedHeight, heightActive: $heightActive)';
}


}

/// @nodoc
abstract mixin class $EditorStateCopyWith<$Res>  {
  factory $EditorStateCopyWith(EditorState value, $Res Function(EditorState) _then) = _$EditorStateCopyWithImpl;
@useResult
$Res call({
 Set<TerrainType> selectedTerrains, Set<ResourceType> selectedResources, MapObjectiveType? selectedObjectiveType, EditorObjectivePaintMode objectivePaintMode, int selectedHeight, bool heightActive
});




}
/// @nodoc
class _$EditorStateCopyWithImpl<$Res>
    implements $EditorStateCopyWith<$Res> {
  _$EditorStateCopyWithImpl(this._self, this._then);

  final EditorState _self;
  final $Res Function(EditorState) _then;

/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectedTerrains = null,Object? selectedResources = null,Object? selectedObjectiveType = freezed,Object? objectivePaintMode = null,Object? selectedHeight = null,Object? heightActive = null,}) {
  return _then(_self.copyWith(
selectedTerrains: null == selectedTerrains ? _self.selectedTerrains : selectedTerrains // ignore: cast_nullable_to_non_nullable
as Set<TerrainType>,selectedResources: null == selectedResources ? _self.selectedResources : selectedResources // ignore: cast_nullable_to_non_nullable
as Set<ResourceType>,selectedObjectiveType: freezed == selectedObjectiveType ? _self.selectedObjectiveType : selectedObjectiveType // ignore: cast_nullable_to_non_nullable
as MapObjectiveType?,objectivePaintMode: null == objectivePaintMode ? _self.objectivePaintMode : objectivePaintMode // ignore: cast_nullable_to_non_nullable
as EditorObjectivePaintMode,selectedHeight: null == selectedHeight ? _self.selectedHeight : selectedHeight // ignore: cast_nullable_to_non_nullable
as int,heightActive: null == heightActive ? _self.heightActive : heightActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [EditorState].
extension EditorStatePatterns on EditorState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorState value)  $default,){
final _that = this;
switch (_that) {
case _EditorState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorState value)?  $default,){
final _that = this;
switch (_that) {
case _EditorState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<TerrainType> selectedTerrains,  Set<ResourceType> selectedResources,  MapObjectiveType? selectedObjectiveType,  EditorObjectivePaintMode objectivePaintMode,  int selectedHeight,  bool heightActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorState() when $default != null:
return $default(_that.selectedTerrains,_that.selectedResources,_that.selectedObjectiveType,_that.objectivePaintMode,_that.selectedHeight,_that.heightActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<TerrainType> selectedTerrains,  Set<ResourceType> selectedResources,  MapObjectiveType? selectedObjectiveType,  EditorObjectivePaintMode objectivePaintMode,  int selectedHeight,  bool heightActive)  $default,) {final _that = this;
switch (_that) {
case _EditorState():
return $default(_that.selectedTerrains,_that.selectedResources,_that.selectedObjectiveType,_that.objectivePaintMode,_that.selectedHeight,_that.heightActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<TerrainType> selectedTerrains,  Set<ResourceType> selectedResources,  MapObjectiveType? selectedObjectiveType,  EditorObjectivePaintMode objectivePaintMode,  int selectedHeight,  bool heightActive)?  $default,) {final _that = this;
switch (_that) {
case _EditorState() when $default != null:
return $default(_that.selectedTerrains,_that.selectedResources,_that.selectedObjectiveType,_that.objectivePaintMode,_that.selectedHeight,_that.heightActive);case _:
  return null;

}
}

}

/// @nodoc


class _EditorState extends EditorState {
  const _EditorState({required final  Set<TerrainType> selectedTerrains, required final  Set<ResourceType> selectedResources, this.selectedObjectiveType, this.objectivePaintMode = EditorObjectivePaintMode.none, required this.selectedHeight, required this.heightActive}): _selectedTerrains = selectedTerrains,_selectedResources = selectedResources,super._();
  

 final  Set<TerrainType> _selectedTerrains;
@override Set<TerrainType> get selectedTerrains {
  if (_selectedTerrains is EqualUnmodifiableSetView) return _selectedTerrains;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedTerrains);
}

 final  Set<ResourceType> _selectedResources;
@override Set<ResourceType> get selectedResources {
  if (_selectedResources is EqualUnmodifiableSetView) return _selectedResources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedResources);
}

@override final  MapObjectiveType? selectedObjectiveType;
@override@JsonKey() final  EditorObjectivePaintMode objectivePaintMode;
@override final  int selectedHeight;
@override final  bool heightActive;

/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorStateCopyWith<_EditorState> get copyWith => __$EditorStateCopyWithImpl<_EditorState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorState&&const DeepCollectionEquality().equals(other._selectedTerrains, _selectedTerrains)&&const DeepCollectionEquality().equals(other._selectedResources, _selectedResources)&&(identical(other.selectedObjectiveType, selectedObjectiveType) || other.selectedObjectiveType == selectedObjectiveType)&&(identical(other.objectivePaintMode, objectivePaintMode) || other.objectivePaintMode == objectivePaintMode)&&(identical(other.selectedHeight, selectedHeight) || other.selectedHeight == selectedHeight)&&(identical(other.heightActive, heightActive) || other.heightActive == heightActive));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_selectedTerrains),const DeepCollectionEquality().hash(_selectedResources),selectedObjectiveType,objectivePaintMode,selectedHeight,heightActive);

@override
String toString() {
  return 'EditorState(selectedTerrains: $selectedTerrains, selectedResources: $selectedResources, selectedObjectiveType: $selectedObjectiveType, objectivePaintMode: $objectivePaintMode, selectedHeight: $selectedHeight, heightActive: $heightActive)';
}


}

/// @nodoc
abstract mixin class _$EditorStateCopyWith<$Res> implements $EditorStateCopyWith<$Res> {
  factory _$EditorStateCopyWith(_EditorState value, $Res Function(_EditorState) _then) = __$EditorStateCopyWithImpl;
@override @useResult
$Res call({
 Set<TerrainType> selectedTerrains, Set<ResourceType> selectedResources, MapObjectiveType? selectedObjectiveType, EditorObjectivePaintMode objectivePaintMode, int selectedHeight, bool heightActive
});




}
/// @nodoc
class __$EditorStateCopyWithImpl<$Res>
    implements _$EditorStateCopyWith<$Res> {
  __$EditorStateCopyWithImpl(this._self, this._then);

  final _EditorState _self;
  final $Res Function(_EditorState) _then;

/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectedTerrains = null,Object? selectedResources = null,Object? selectedObjectiveType = freezed,Object? objectivePaintMode = null,Object? selectedHeight = null,Object? heightActive = null,}) {
  return _then(_EditorState(
selectedTerrains: null == selectedTerrains ? _self._selectedTerrains : selectedTerrains // ignore: cast_nullable_to_non_nullable
as Set<TerrainType>,selectedResources: null == selectedResources ? _self._selectedResources : selectedResources // ignore: cast_nullable_to_non_nullable
as Set<ResourceType>,selectedObjectiveType: freezed == selectedObjectiveType ? _self.selectedObjectiveType : selectedObjectiveType // ignore: cast_nullable_to_non_nullable
as MapObjectiveType?,objectivePaintMode: null == objectivePaintMode ? _self.objectivePaintMode : objectivePaintMode // ignore: cast_nullable_to_non_nullable
as EditorObjectivePaintMode,selectedHeight: null == selectedHeight ? _self.selectedHeight : selectedHeight // ignore: cast_nullable_to_non_nullable
as int,heightActive: null == heightActive ? _self.heightActive : heightActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
