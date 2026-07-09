// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hud_minimized_popups_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HudMinimizedPopupsState {

 bool get loaded; List<HudMinimizedPopupEntry> get entries; Map<String, List<HudMinimizedPopupEntry>> get transientEntriesByScope; HudPopupRestoreRequest? get restoreRequest; HudPopupAttentionRequest? get attentionRequest;
/// Create a copy of HudMinimizedPopupsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HudMinimizedPopupsStateCopyWith<HudMinimizedPopupsState> get copyWith => _$HudMinimizedPopupsStateCopyWithImpl<HudMinimizedPopupsState>(this as HudMinimizedPopupsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HudMinimizedPopupsState&&(identical(other.loaded, loaded) || other.loaded == loaded)&&const DeepCollectionEquality().equals(other.entries, entries)&&const DeepCollectionEquality().equals(other.transientEntriesByScope, transientEntriesByScope)&&(identical(other.restoreRequest, restoreRequest) || other.restoreRequest == restoreRequest)&&(identical(other.attentionRequest, attentionRequest) || other.attentionRequest == attentionRequest));
}


@override
int get hashCode => Object.hash(runtimeType,loaded,const DeepCollectionEquality().hash(entries),const DeepCollectionEquality().hash(transientEntriesByScope),restoreRequest,attentionRequest);

@override
String toString() {
  return 'HudMinimizedPopupsState(loaded: $loaded, entries: $entries, transientEntriesByScope: $transientEntriesByScope, restoreRequest: $restoreRequest, attentionRequest: $attentionRequest)';
}


}

/// @nodoc
abstract mixin class $HudMinimizedPopupsStateCopyWith<$Res>  {
  factory $HudMinimizedPopupsStateCopyWith(HudMinimizedPopupsState value, $Res Function(HudMinimizedPopupsState) _then) = _$HudMinimizedPopupsStateCopyWithImpl;
@useResult
$Res call({
 bool loaded, List<HudMinimizedPopupEntry> entries, Map<String, List<HudMinimizedPopupEntry>> transientEntriesByScope, HudPopupRestoreRequest? restoreRequest, HudPopupAttentionRequest? attentionRequest
});




}
/// @nodoc
class _$HudMinimizedPopupsStateCopyWithImpl<$Res>
    implements $HudMinimizedPopupsStateCopyWith<$Res> {
  _$HudMinimizedPopupsStateCopyWithImpl(this._self, this._then);

  final HudMinimizedPopupsState _self;
  final $Res Function(HudMinimizedPopupsState) _then;

/// Create a copy of HudMinimizedPopupsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loaded = null,Object? entries = null,Object? transientEntriesByScope = null,Object? restoreRequest = freezed,Object? attentionRequest = freezed,}) {
  return _then(_self.copyWith(
loaded: null == loaded ? _self.loaded : loaded // ignore: cast_nullable_to_non_nullable
as bool,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<HudMinimizedPopupEntry>,transientEntriesByScope: null == transientEntriesByScope ? _self.transientEntriesByScope : transientEntriesByScope // ignore: cast_nullable_to_non_nullable
as Map<String, List<HudMinimizedPopupEntry>>,restoreRequest: freezed == restoreRequest ? _self.restoreRequest : restoreRequest // ignore: cast_nullable_to_non_nullable
as HudPopupRestoreRequest?,attentionRequest: freezed == attentionRequest ? _self.attentionRequest : attentionRequest // ignore: cast_nullable_to_non_nullable
as HudPopupAttentionRequest?,
  ));
}

}


/// Adds pattern-matching-related methods to [HudMinimizedPopupsState].
extension HudMinimizedPopupsStatePatterns on HudMinimizedPopupsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HudMinimizedPopupsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HudMinimizedPopupsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HudMinimizedPopupsState value)  $default,){
final _that = this;
switch (_that) {
case _HudMinimizedPopupsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HudMinimizedPopupsState value)?  $default,){
final _that = this;
switch (_that) {
case _HudMinimizedPopupsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool loaded,  List<HudMinimizedPopupEntry> entries,  Map<String, List<HudMinimizedPopupEntry>> transientEntriesByScope,  HudPopupRestoreRequest? restoreRequest,  HudPopupAttentionRequest? attentionRequest)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HudMinimizedPopupsState() when $default != null:
return $default(_that.loaded,_that.entries,_that.transientEntriesByScope,_that.restoreRequest,_that.attentionRequest);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool loaded,  List<HudMinimizedPopupEntry> entries,  Map<String, List<HudMinimizedPopupEntry>> transientEntriesByScope,  HudPopupRestoreRequest? restoreRequest,  HudPopupAttentionRequest? attentionRequest)  $default,) {final _that = this;
switch (_that) {
case _HudMinimizedPopupsState():
return $default(_that.loaded,_that.entries,_that.transientEntriesByScope,_that.restoreRequest,_that.attentionRequest);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool loaded,  List<HudMinimizedPopupEntry> entries,  Map<String, List<HudMinimizedPopupEntry>> transientEntriesByScope,  HudPopupRestoreRequest? restoreRequest,  HudPopupAttentionRequest? attentionRequest)?  $default,) {final _that = this;
switch (_that) {
case _HudMinimizedPopupsState() when $default != null:
return $default(_that.loaded,_that.entries,_that.transientEntriesByScope,_that.restoreRequest,_that.attentionRequest);case _:
  return null;

}
}

}

/// @nodoc


class _HudMinimizedPopupsState extends HudMinimizedPopupsState {
  const _HudMinimizedPopupsState({this.loaded = false, final  List<HudMinimizedPopupEntry> entries = const <HudMinimizedPopupEntry>[], final  Map<String, List<HudMinimizedPopupEntry>> transientEntriesByScope = const <String, List<HudMinimizedPopupEntry>>{}, this.restoreRequest, this.attentionRequest}): _entries = entries,_transientEntriesByScope = transientEntriesByScope,super._();
  

@override@JsonKey() final  bool loaded;
 final  List<HudMinimizedPopupEntry> _entries;
@override@JsonKey() List<HudMinimizedPopupEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

 final  Map<String, List<HudMinimizedPopupEntry>> _transientEntriesByScope;
@override@JsonKey() Map<String, List<HudMinimizedPopupEntry>> get transientEntriesByScope {
  if (_transientEntriesByScope is EqualUnmodifiableMapView) return _transientEntriesByScope;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_transientEntriesByScope);
}

@override final  HudPopupRestoreRequest? restoreRequest;
@override final  HudPopupAttentionRequest? attentionRequest;

/// Create a copy of HudMinimizedPopupsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HudMinimizedPopupsStateCopyWith<_HudMinimizedPopupsState> get copyWith => __$HudMinimizedPopupsStateCopyWithImpl<_HudMinimizedPopupsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HudMinimizedPopupsState&&(identical(other.loaded, loaded) || other.loaded == loaded)&&const DeepCollectionEquality().equals(other._entries, _entries)&&const DeepCollectionEquality().equals(other._transientEntriesByScope, _transientEntriesByScope)&&(identical(other.restoreRequest, restoreRequest) || other.restoreRequest == restoreRequest)&&(identical(other.attentionRequest, attentionRequest) || other.attentionRequest == attentionRequest));
}


@override
int get hashCode => Object.hash(runtimeType,loaded,const DeepCollectionEquality().hash(_entries),const DeepCollectionEquality().hash(_transientEntriesByScope),restoreRequest,attentionRequest);

@override
String toString() {
  return 'HudMinimizedPopupsState(loaded: $loaded, entries: $entries, transientEntriesByScope: $transientEntriesByScope, restoreRequest: $restoreRequest, attentionRequest: $attentionRequest)';
}


}

/// @nodoc
abstract mixin class _$HudMinimizedPopupsStateCopyWith<$Res> implements $HudMinimizedPopupsStateCopyWith<$Res> {
  factory _$HudMinimizedPopupsStateCopyWith(_HudMinimizedPopupsState value, $Res Function(_HudMinimizedPopupsState) _then) = __$HudMinimizedPopupsStateCopyWithImpl;
@override @useResult
$Res call({
 bool loaded, List<HudMinimizedPopupEntry> entries, Map<String, List<HudMinimizedPopupEntry>> transientEntriesByScope, HudPopupRestoreRequest? restoreRequest, HudPopupAttentionRequest? attentionRequest
});




}
/// @nodoc
class __$HudMinimizedPopupsStateCopyWithImpl<$Res>
    implements _$HudMinimizedPopupsStateCopyWith<$Res> {
  __$HudMinimizedPopupsStateCopyWithImpl(this._self, this._then);

  final _HudMinimizedPopupsState _self;
  final $Res Function(_HudMinimizedPopupsState) _then;

/// Create a copy of HudMinimizedPopupsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? loaded = null,Object? entries = null,Object? transientEntriesByScope = null,Object? restoreRequest = freezed,Object? attentionRequest = freezed,}) {
  return _then(_HudMinimizedPopupsState(
loaded: null == loaded ? _self.loaded : loaded // ignore: cast_nullable_to_non_nullable
as bool,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<HudMinimizedPopupEntry>,transientEntriesByScope: null == transientEntriesByScope ? _self._transientEntriesByScope : transientEntriesByScope // ignore: cast_nullable_to_non_nullable
as Map<String, List<HudMinimizedPopupEntry>>,restoreRequest: freezed == restoreRequest ? _self.restoreRequest : restoreRequest // ignore: cast_nullable_to_non_nullable
as HudPopupRestoreRequest?,attentionRequest: freezed == attentionRequest ? _self.attentionRequest : attentionRequest // ignore: cast_nullable_to_non_nullable
as HudPopupAttentionRequest?,
  ));
}


}

// dart format on
